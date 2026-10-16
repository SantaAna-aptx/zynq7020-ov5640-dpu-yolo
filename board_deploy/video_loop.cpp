// video_loop.cpp — OV5640 实时目标识别 (DPU B1152) + M-JPEG 推流
// 管线: OV5640 720p RGB565 → VDMA s2mm → DDR(0x10000000, memmap 保留)
//       → /dev/mem 映射 → BGR565→BGR → resize 416×416 → DPU → NMS → 画框
//       → JPEG → http://板子IP:8080 M-JPEG 流 (+ /latest 单帧)
// 编译: 见 build_video.sh (PetaLinux ARM gcc + DNNDK + OpenCV)
#include <algorithm>
#include <vector>
#include <atomic>
#include <iostream>
#include <iomanip>
#include <chrono>
#include <mutex>
#include <thread>
#include <string>
#include <utility>
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <dnndk/n2cube.h>

using namespace std;
using namespace cv;
using namespace std::chrono;

#define CONF      0.5
#define NMS_THRE  0.1
#define YOLOKERNEL "tiny_yolo"
#define INPUTNODE  "conv2d_1_convolution"
vector<string> outputs_node = {"conv2d_10_convolution", "conv2d_13_convolution"};
const int classification = 80;
const int anchor = 3;
vector<float> biases { 116,90,  156,198,  373,326, 30,61,  62,45,  59,119, 10,13,  16,30,  33,23 };
vector<string> class_names = {
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck",
    "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench",
    "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra",
    "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
    "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove",
    "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup", "fork",
    "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange", "broccoli",
    "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch", "potted plant",
    "bed", "dining table", "toilet", "tv", "laptop", "mouse", "remote", "keyboard",
    "cell phone", "microwave", "oven", "toaster", "sink", "refrigerator", "book",
    "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush" };

// ---------------- 硬件地址 ----------------
#define FB_PA        0x10000000UL           // 帧缓冲 (bootargs memmap 保留)
#define FB_SIZE      (1280UL * 720 * 2)     // RGB565
#define VD_PA        0x43C00000UL           // VDMA LITE 基址 (BD 地址编辑器分配)
#define VD_SIZE      0x1000
// VDMA s2mm 寄存器 (相对基址, PG022)
#define S2MM_DMACR   0x30
#define S2MM_DMASR   0x34
#define S2MM_FRMSTORE 0x48
#define S2MM_IRQMASK 0x54
#define S2MM_VSIZE   0xA0
#define S2MM_HSIZE   0xA4
#define S2MM_STRIDE  0xA8
#define S2MM_SA1     0xAC
#define DMACR_RESET  4u
#define DMACR_RUN    1u
#define DMACR_FRMCNT_EN 0x10u
#define DMASR_FRMCNT 0x1000u

static int fb_fd = -1, vd_fd = -1;
static volatile unsigned char *fb = nullptr;   // 帧缓冲映射
static volatile unsigned int  *vd = nullptr;   // VDMA 寄存器映射

static inline unsigned vd_rd(unsigned off) { return vd[off / 4]; }
static inline void vd_wr(unsigned off, unsigned v) { vd[off / 4] = v; }

static int hw_map(void) {
    fb_fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fb_fd < 0) { fprintf(stderr, "open /dev/mem: %s\n", strerror(errno)); return -1; }
    fb = (volatile unsigned char*)mmap(NULL, FB_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fb_fd, FB_PA);
    if (fb == MAP_FAILED) { fprintf(stderr, "mmap fb failed\n"); return -1; }
    vd_fd = open("/dev/mem", O_RDWR | O_SYNC);
    vd = (volatile unsigned int*)mmap(NULL, VD_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, vd_fd, VD_PA);
    if (vd == MAP_FAILED) { fprintf(stderr, "mmap vdma failed\n"); return -1; }
    printf("[HW] fb @0x%08lX mapped, vdma @0x%08lX mapped\n", FB_PA, VD_PA);
    return 0;
}

static void vdma_start(void) {
    vd_wr(S2MM_DMACR, DMACR_RESET); usleep(10000);
    vd_wr(S2MM_DMACR, 0);
    vd_wr(S2MM_FRMSTORE, 1);                       // 单帧存储(循环覆盖=永远最新)
    vd_wr(S2MM_SA1, (unsigned)FB_PA);
    vd_wr(S2MM_STRIDE, 1280 * 2);                  // 2560 字节/行
    vd_wr(S2MM_HSIZE, 1280 * 2 / 8);               // 64bit 总线: beat 数 = 320
    vd_wr(S2MM_IRQMASK, DMASR_FRMCNT);
    vd_wr(S2MM_DMACR, DMACR_RUN | DMACR_FRMCNT_EN | (1u << 16)); // RUN + 帧计数中断, count=1
    vd_wr(S2MM_VSIZE, 720);                        // 写 VSIZE 启动
    printf("[HW] VDMA s2mm started (720x2560B, fb=0x%08lX)\n", FB_PA);
}

static int wait_frame(int timeout_ms) {
    for (int i = 0; i < timeout_ms / 5; ++i) {
        if (vd_rd(S2MM_DMASR) & DMASR_FRMCNT) {    // 一帧完成
            vd_wr(S2MM_DMASR, DMASR_FRMCNT);       // 写 1 清除
            return 1;
        }
        usleep(5000);
    }
    return 0;
}

// ---------------- DNNDK 推理 ----------------
#define INPUTNODE "conv2d_1_convolution"
static DPUTask *g_task = nullptr;
static int g_sh = 416, g_sw = 416;

// 快速输入量化: 结果与 set_input_image 的 float 路径逐位一致 (LUT 预计算)
static int8_t g_lut[3][256];
static void build_lut(void) {
    float scale = dpuGetInputTensorScale(g_task, INPUTNODE);
    printf("[DPU] input scale = %g\n", scale);
    for (int a = 0; a < 3; ++a)
        for (int v = 0; v < 256; ++v)
            g_lut[a][v] = (int8_t)(int)((v / 255.0f) * scale);
}
// planes[0]=B, planes[1]=G, planes[2]=R (cv split 顺序); 网络通道序 a=0R,1G,2B
static void fast_set_input(const Mat& pB, const Mat& pG, const Mat& pR) {
    int8_t* data = dpuGetInputTensorAddress(g_task, INPUTNODE);
    int W = g_sw;
    for (int b = 0; b < g_sh; ++b) {
        const uchar* rB = pB.ptr<uchar>(b);
        const uchar* rG = pG.ptr<uchar>(b);
        const uchar* rR = pR.ptr<uchar>(b);
        int8_t* o = data + (size_t)b * W * 3;
        for (int c = 0; c < W; ++c) {
            o[c * 3 + 0] = g_lut[0][rR[c]];
            o[c * 3 + 1] = g_lut[1][rG[c]];
            o[c * 3 + 2] = g_lut[2][rB[c]];
        }
    }
}

inline float sigmoid(float p) { return 1.0f / (1 + expf(-p)); }
inline float overlap(float x1, float w1, float x2, float w2) {
    float left = max(x1 - w1 / 2.0f, x2 - w2 / 2.0f);
    float right = min(x1 + w1 / 2.0f, x2 + w2 / 2.0f);
    return right - left;
}
inline float cal_iou(vector<float>& box, vector<float>& truth) {
    float w = overlap(box[0], box[2], truth[0], truth[2]);
    float h = overlap(box[1], box[3], truth[1], truth[3]);
    if (w <= 0 || h <= 0) return 0;
    float inter = w * h;
    float uni = box[2] * box[3] + truth[2] * truth[3] - inter;
    return inter / uni;
}

void get_output(int8_t* dpuOut, int sizeOut, float scale, int oc, int oh, int ow, vector<float>& result) {
    vector<int8_t> nums(sizeOut);
    memcpy(nums.data(), dpuOut, sizeOut);
    for (int a = 0; a < oc; ++a)
        for (int b = 0; b < oh; ++b)
            for (int c = 0; c < ow; ++c) {
                int offset = b * oc * ow + c * oc + a;
                result[a * oh * ow + b * ow + c] = nums[offset] * scale;
            }
}

void detect(vector<vector<float>>& boxes, vector<float>& result, int channel, int height, int width, int num, int sh, int sw) {
    int conf_box = 5 + classification;
    vector<vector<vector<float>>> swap(height * width, vector<vector<float>>(anchor, vector<float>(conf_box)));
    for (int h = 0; h < height; ++h)
        for (int w = 0; w < width; ++w)
            for (int c = 0; c < channel; ++c) {
                int temp = c * height * width + h * width + w;
                auto& cell = swap[h * width + w];
                cell[c / conf_box][c % conf_box] = result[temp];
            }
    for (int h = 0; h < height; ++h)
        for (int w = 0; w < width; ++w)
            for (int c = 0; c < anchor; ++c) {
                auto& cell = swap[h * width + w];
                float obj_score = sigmoid(cell[c][4]);
                if (obj_score < CONF) continue;
                vector<float> box;
                box.push_back((w + sigmoid(cell[c][0])) / width);
                box.push_back((h + sigmoid(cell[c][1])) / height);
                box.push_back(expf(cell[c][2]) * biases[2 * c + anchor * 2 * num] / (float)sw);
                box.push_back(expf(cell[c][3]) * biases[2 * c + anchor * 2 * num + 1] / (float)sh);
                box.push_back(-1);
                box.push_back(obj_score);
                for (int p = 0; p < classification; ++p)
                    box.push_back(obj_score * sigmoid(cell[c][5 + p]));
                boxes.push_back(box);
            }
}

vector<vector<float>> apply_nms(vector<vector<float>>& boxes, int classes, const float thres) {
    vector<pair<int, float>> order(boxes.size());
    vector<vector<float>> result;
    for (int k = 0; k < classes; ++k) {
        for (size_t i = 0; i < boxes.size(); ++i) {
            order[i].first = i;
            boxes[i][4] = k;
            order[i].second = boxes[i][6 + k];
        }
        sort(order.begin(), order.end(),
             [](const pair<int, float>& a, const pair<int, float>& b) { return a.second > b.second; });
        vector<bool> keep(boxes.size(), true);
        for (size_t i = 0; i < boxes.size(); ++i) {
            size_t bi = order[i].first;
            if (!keep[bi]) continue;
            if (boxes[bi][6 + k] < CONF) { keep[bi] = false; continue; }
            result.push_back(boxes[bi]);
            for (size_t j = i + 1; j < boxes.size(); ++j) {
                size_t bj = order[j].first;
                if (!keep[bj]) continue;
                if (cal_iou(boxes[bj], boxes[bi]) >= thres) keep[bj] = false;
            }
        }
    }
    return result;
}

void correct_region_boxes(vector<vector<float>>& boxes, int w, int h, int netw, int neth) {
    int new_w = w, new_h = h;
    if (((float)netw / w) < ((float)neth / h)) { new_w = netw; new_h = (h * netw) / w; }
    else { new_h = neth; new_w = (w * neth) / h; }
    for (auto& b : boxes) {
        b[0] *= (float)new_w / netw;
        b[1] *= (float)new_h / neth;
        b[2] *= (float)w / new_w;
        b[3] *= (float)h / new_h;
    }
}

// ---------------- M-JPEG 推流 ----------------
static std::mutex g_jmtx;
static std::vector<uchar> g_jpeg;
static unsigned g_seq = 0;
static std::atomic<int> g_clients(0);

static ssize_t send_all(int c, const char* p, size_t n) {
    size_t off = 0;
    while (off < n) {
        ssize_t k = send(c, p + off, n - off, MSG_NOSIGNAL);
        if (k <= 0) return -1;
        off += k;
    }
    return (ssize_t)n;
}

static void* client_thread(void* arg) {
    int c = (int)(long)arg;
    char req[512] = {0};
    recv(c, req, sizeof(req) - 1, 0);
    bool latest = (strstr(req, "GET /latest") != NULL);
    if (latest) {
        vector<uchar> copy;
        { std::lock_guard<std::mutex> lk(g_jmtx); copy = g_jpeg; }
        char h[256];
        snprintf(h, sizeof(h), "HTTP/1.1 200 OK\r\nContent-Type: image/jpeg\r\nContent-Length: %zu\r\nConnection: close\r\n\r\n", copy.size());
        send_all(c, h, strlen(h));
        if (copy.size()) send_all(c, (const char*)copy.data(), copy.size());
        close(c);
        return nullptr;
    }
    const char* hdr = "HTTP/1.1 200 OK\r\nContent-Type: multipart/x-mixed-replace; boundary=frame\r\n\r\n";
    send_all(c, hdr, strlen(hdr));
    unsigned last = 0;
    while (1) {
        if (g_seq != last) {
            vector<uchar> copy;
            { std::lock_guard<std::mutex> lk(g_jmtx); copy = g_jpeg; last = g_seq; }
            char h[160];
            int hn = snprintf(h, sizeof(h), "--frame\r\nContent-Type: image/jpeg\r\nContent-Length: %zu\r\n\r\n", copy.size());
            if (send_all(c, h, hn) < 0) break;
            if (!copy.empty() && send_all(c, (const char*)copy.data(), copy.size()) < 0) break;
            if (send_all(c, "\r\n", 2) < 0) break;
        } else usleep(15000);
    }
    close(c);
    g_clients--;
    return nullptr;
}

static void* server_thread(void*) {
    int sfd = socket(AF_INET, SOCK_STREAM, 0);
    int one = 1;
    setsockopt(sfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
    sockaddr_in a; memset(&a, 0, sizeof(a));
    a.sin_family = AF_INET;
    a.sin_addr.s_addr = htonl(INADDR_ANY);
    a.sin_port = htons(8080);
    if (bind(sfd, (sockaddr*)&a, sizeof(a)) < 0) { fprintf(stderr, "[MJPEG] bind failed\n"); return nullptr; }
    listen(sfd, 8);
    printf("[MJPEG] streaming on http://0.0.0.0:8080/  (single frame: /latest)\n");
    while (1) {
        int c = accept(sfd, nullptr, nullptr);
        if (c < 0) continue;
        int nd = 1; setsockopt(c, IPPROTO_TCP, TCP_NODELAY, &nd, sizeof(nd));
        g_clients++;
        pthread_t t;
        pthread_create(&t, nullptr, client_thread, (void*)(long)c);
        pthread_detach(t);
    }
    return nullptr;
}

// ---------------- main ----------------
int main(int argc, char** argv) {
    if (hw_map() < 0) return -1;
    vdma_start();

    printf("[DPU] opening...\n");
    dpuOpen();
    DPUKernel* kernel = dpuLoadKernel(YOLOKERNEL);
    g_task = dpuCreateTask(kernel, 0);
    g_sh = dpuGetInputTensorHeight(g_task, INPUTNODE);
    g_sw = dpuGetInputTensorWidth(g_task, INPUTNODE);
    build_lut();
    printf("[DPU] ready, net input %dx%d\n", g_sw, g_sh);

    pthread_t st;
    pthread_create(&st, nullptr, server_thread, nullptr);

    printf("[CAM] waiting for camera I2C config + first frames (3s)...\n");
    sleep(3);
    wait_frame(1000);   // 丢弃第一帧(可能不完整)

    Mat bgr565(720, 1280, CV_8UC2, (void*)fb);      // 直接映射帧缓冲
    Mat bgr, small, disp;
    Mat pB(416, 416, CV_8UC1), pG(416, 416, CV_8UC1), pR(416, 416, CV_8UC1);
    long frames = 0;
    auto t_prev = steady_clock::now();
    auto t_last = steady_clock::now();

    while (1) {
        wait_frame(500);                            // 等一帧完成(带超时保护)
        bgr565.setTo(0);                            // 防御: 上一帧残留透明化(调试友好)
        memcpy(bgr565.data, (const void*)fb, FB_SIZE);
        cvtColor(bgr565, bgr, COLOR_BGR5652BGR);
        cv::resize(bgr, small, small.size(), 0, 0, INTER_LINEAR);
        Mat ch[3];
        split(small, ch);                           // ch0=B ch1=G ch2=R
        fast_set_input(ch[2], ch[1], ch[0]);        // 网络序 RGB
        auto t0 = steady_clock::now();
        dpuRunTask(g_task);
        double infer_ms = duration<double, milli>(steady_clock::now() - t0).count();

        // 解码
        vector<vector<float>> boxes;
        for (size_t i = 0; i < outputs_node.size(); ++i) {
            string node = outputs_node[i];
            int chn = dpuGetOutputTensorChannel(g_task, node.c_str());
            int hh = dpuGetOutputTensorHeight(g_task, node.c_str());
            int ww = dpuGetOutputTensorWidth(g_task, node.c_str());
            int sz = dpuGetOutputTensorSize(g_task, node.c_str());
            int8_t* po = dpuGetOutputTensorAddress(g_task, node.c_str());
            float sc = dpuGetOutputTensorScale(g_task, node.c_str());
            vector<float> result(sz);
            get_output(po, sz, sc, chn, hh, ww, result);
            detect(boxes, result, chn, hh, ww, (int)i, g_sh, g_sw);
        }
        correct_region_boxes(boxes, bgr.cols, bgr.rows, g_sw, g_sh);
        vector<vector<float>> res = apply_nms(boxes, classification, NMS_THRE);

        disp = bgr.clone();
        for (auto& r : res) {
            float xmin = (r[0] - r[2] / 2) * disp.cols, ymin = (r[1] - r[3] / 2) * disp.rows;
            float xmax = (r[0] + r[2] / 2) * disp.cols, ymax = (r[1] + r[3] / 2) * disp.rows;
            int cls = (int)r[4];
            rectangle(disp, Point(xmin, ymin), Point(xmax, ymax), Scalar(0, 255, 0), 2);
            putText(disp, class_names[cls] + " " + to_string((int)(r[5 + cls] * 100)) + "%",
                    Point(max(0.f, xmin), max(20.f, ymin - 6)), FONT_HERSHEY_SIMPLEX, 0.7,
                    Scalar(0, 255, 255), 2, LINE_AA);
        }
        // 状态条
        double fps_now = 1000.0 / max(1.0, duration<double, milli>(steady_clock::now() - t_prev).count());
        putText(disp, "DPU " + to_string((int)infer_ms) + "ms  " + to_string((int)fps_now) + "fps  boxes=" + to_string(res.size()),
                Point(10, 30), FONT_HERSHEY_SIMPLEX, 0.8, Scalar(255, 255, 255), 2);
        t_prev = steady_clock::now();

        vector<uchar> jpeg;
        vector<int> jp = {IMWRITE_JPEG_QUALITY, 70};
        imencode(".jpg", disp, jpeg, jp);
        { std::lock_guard<std::mutex> lk(g_jmtx); g_jpeg.swap(jpeg); ++g_seq; }

        ++frames;
        if (frames % 30 == 0) {
            double fps = 30.0 / duration<double>(steady_clock::now() - t_last).count();
            t_last = steady_clock::now();
            printf("[LOOP] %ld frames, %.1f fps, infer %.0f ms, boxes %zu, clients %d\n",
                   frames, fps, infer_ms, res.size(), (int)g_clients);
            fflush(stdout);
        }
    }
    return 0;
}

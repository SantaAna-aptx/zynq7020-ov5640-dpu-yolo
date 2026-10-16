// cam_stream.cpp -- on-board resident service: OV5640 -> DPU YOLOv3-tiny -> M-JPEG over HTTP.
//
//   OV5640 -> frame_writer -> DDR @ 0x08000000 (1025x720 RGB565, 1,476,000 bytes)
//                                     |
//                          mmap /dev/mem (verified: 0.024 s per frame from Python)
//                                     v
//                            [this program, one instance]
//                             - wait for the frame boundary
//                             - RGB565 -> BGR
//                             - letterbox 416x416 -> quantise -> DPU input
//                             - dpuRunTask()          (task created ONCE, not per frame)
//                             - decode YOLO output + NMS + draw boxes
//                             - JPEG encode in memory
//                             - publish to all M-JPEG clients
//                                     |
//                            browser http://<board>:8080/
//
// Nothing is written to disk: the frame lives in RAM, the JPEG lives in RAM, and it only ever
// goes out over the socket.
//
// Two things this deliberately does NOT copy from the older video_loop.cpp:
//   1. That file resized 1280x720 straight to 416x416 (plain stretch) and used a matching but
//      inconsistent box correction. The verified diag program instead does a proper darknet
//      letterbox (grey bars, aspect preserved) and corrects boxes with the letterbox offset.
//      The letterbox path is what produced the 8/8 bit-exact results, so it is what is used here.
//   2. That file drove an AXI VDMA at 0x43C00000 and used its frame-counter interrupt. This
//      hardware has no VDMA - the camera path is a custom frame_writer with no registers - so
//      frame sync instead polls cam_top's debug word at 0x41220000 (line_cnt_r[11:4]).
//
// Frame tearing: the frame_writer rolls continuously through the buffer, so a naive read can mix
// two frames. Reading takes ~5 ms while a frame takes ~33 ms to be written, so if the read STARTS
// just after a frame boundary the read pointer stays ahead of the write pointer for the whole
// transfer and the result is one complete, un-torn frame (the previous one - 33 ms of latency,
// irrelevant for a live view). wait_frame_start() is what enforces that.
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
#include <errno.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/imgcodecs.hpp>
#include <dnndk/n2cube.h>

using namespace std;
using namespace cv;
using namespace std::chrono;

// ---------------- network / model constants ----------------
#define CONF            0.5f
#define NMS_THRE        0.1f
#define YOLOKERNEL      "tiny_yolo"
#define INPUTNODE       "conv2d_1_convolution"
#define CLASSIFICATION  80
#define ANCHOR          3

static vector<string> outputs_node = { "conv2d_10_convolution", "conv2d_13_convolution" };
static vector<float> biases { 116,90, 156,198, 373,326, 30,61, 62,45, 59,119, 10,13, 16,30, 33,23 };
static vector<string> class_names = {
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

// ---------------- the one thing the two threads share ----------------
// Detections are passed as normalised (0..1) coordinates so the drawing side never needs to know
// which resolution the inference side worked at - it just multiplies by its own width/height.
// This is the ONLY shared mutable state besides a mutex, which keeps the concurrency surface tiny.
struct Box {
    int   cls;
    float conf;
    float x1, y1, x2, y2;      // normalised: (x1,y1) top-left, (x2,y2) bottom-right
};

static std::mutex          g_boxmtx;
static std::vector<Box>    g_boxes;        // written by the inference thread, read by the display thread
static std::atomic<long>   g_infer_count(0);
// (g_infer_ms / g_boxes_last live with the other M-JPEG globals further down, so the HTTP
//  handler and the inference thread both see one definition)

// ---------------- hardware ----------------
// The camera frame buffer. frame_writer.v writes here through S_AXI_HP3; mem=120M on the kernel
// command line keeps it out of Linux's RAM so a bulk read cannot corrupt the kernel.
#define FB_PA    0x08000000UL
#define FB_W     1025
#define FB_H     720
#define FB_SIZE  ((size_t)FB_W * FB_H * 2)     // 1,476,000
// cam_top's debug register: line_cnt_r[11:4], i.e. the current line number >> 4. It runs 0..~44
// once per frame, so a small value means we are at the very start of a frame.
#define DBG_PA   0x41220000UL
#define DBG_SIZE 0x1000

#define MJPEG_PORT 8080

static volatile unsigned char *g_fb  = nullptr;
static volatile unsigned      *g_dbg = nullptr;
static unsigned char          *g_local = nullptr;   // stable copy of one frame

static int hw_map(void) {
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) { fprintf(stderr, "[HW] open /dev/mem: %s\n", strerror(errno)); return -1; }

    g_fb = (volatile unsigned char *)mmap(NULL, FB_SIZE, PROT_READ, MAP_SHARED, fd, FB_PA);
    if (g_fb == MAP_FAILED) { fprintf(stderr, "[HW] mmap fb failed: %s\n", strerror(errno)); return -1; }

    g_dbg = (volatile unsigned *)mmap(NULL, DBG_SIZE, PROT_READ, MAP_SHARED, fd, DBG_PA);
    if (g_dbg == MAP_FAILED) { fprintf(stderr, "[HW] mmap dbg failed: %s\n", strerror(errno)); return -1; }

    g_local = (unsigned char *)malloc(FB_SIZE);
    if (!g_local) { fprintf(stderr, "[HW] malloc frame copy failed\n"); return -1; }

    printf("[HW] fb @0x%08lX (%zu bytes), dbg @0x%08lX, dbg=%u\n",
           (unsigned long)FB_PA, FB_SIZE, (unsigned long)DBG_PA, *g_dbg);
    return 0;
}

// Wait until the camera is at the very beginning of a frame (line_cnt >> 4 small). Starting the
// copy here is what makes the read un-torn - see the file header.
static int wait_frame_start(int timeout_ms) {
    for (int i = 0; i < timeout_ms; ++i) {
        if (*g_dbg <= 2u) return 1;
        usleep(500);
    }
    return 0;
}

// ---------------- preprocessing (letterbox + quantise) ----------------
// The verified diag program built this the long way: Mat -> CHW float RGB in [0,1] (a hand-written
// per-pixel loop), then a hand-written bilinear resize, then a hand-written NHWC re-pack and
// quantise. That chain measured ~450 ms per frame here and dominated the whole pipeline - the DPU
// itself only needs ~125 ms.
//
// This does the same thing with OpenCV's NEON paths:
//   resize (NEON) -> copyTo the letterbox canvas (grey 128) -> cvtColor(BGR2RGB) -> 256-entry LUT
// The letterbox geometry and the grey fill value are the same formulas and the same 0.5/128, and
// the quantiser reproduces the original expression exactly (int truncation, then negative->127),
// so the tensor handed to the DPU is equivalent up to sub-pixel resize interpolation differences.
static cv::Mat   g_small;
static cv::Mat   g_canvas;
static cv::Mat   g_rgb;
static int8_t    g_qlut[256];
static float     g_qlut_scale = -1e9f;

static void set_input_image(DPUTask* task, const Mat& bgr, const char* nodename) {
    const int height = dpuGetInputTensorHeight(task, nodename);
    const int width  = dpuGetInputTensorWidth(task, nodename);
    int8_t*   data   = dpuGetInputTensorAddress(task, nodename);
    const float scale = dpuGetInputTensorScale(task, nodename);

    if (scale != g_qlut_scale) {
        for (int v = 0; v < 256; ++v) {
            int q = (int)((v / 255.0f) * scale);   // same as the verified program
            int8_t q8 = (int8_t)q;                 // truncate to int8 first ...
            if (q8 < 0) q8 = 127;                  // ... then the same negative clamp
            g_qlut[v] = q8;
        }
        g_qlut_scale = scale;
        printf("[DPU] input scale %g, grey %d -> %d\n", scale, 128, (int)g_qlut[128]);
    }

    // letterbox geometry, identical formulas to the verified program
    int new_w = bgr.cols, new_h = bgr.rows;
    if (((float)width / bgr.cols) < ((float)height / bgr.rows)) {
        new_w = width;  new_h = (bgr.rows * width) / bgr.cols;
    } else {
        new_h = height; new_w = (bgr.cols * height) / bgr.rows;
    }
    if (new_w < 1) new_w = 1;
    if (new_h < 1) new_h = 1;

    cv::resize(bgr, g_small, Size(new_w, new_h), 0, 0, INTER_LINEAR);

    if (g_canvas.rows != height || g_canvas.cols != width)
        g_canvas.create(height, width, CV_8UC3);
    g_canvas.setTo(cv::Scalar::all(128));          // 0.5 * 255, matches the float 0.5 fill
    g_small.copyTo(g_canvas(cv::Rect((width - new_w) / 2, (height - new_h) / 2, new_w, new_h)));

    cv::cvtColor(g_canvas, g_rgb, cv::COLOR_BGR2RGB);

    const uchar* p = g_rgb.ptr<uchar>(0);
    const int n = width * height;
    for (int i = 0; i < n; ++i) {                  // NHWC, same layout the DPU expects
        data[i * 3 + 0] = g_qlut[p[i * 3 + 0]];
        data[i * 3 + 1] = g_qlut[p[i * 3 + 1]];
        data[i * 3 + 2] = g_qlut[p[i * 3 + 2]];
    }
}

// ---------------- post-processing ----------------
static inline float sigmoid(float p) { return 1.0f / (1.0f + expf(-p)); }
static inline float overlap(float x1, float w1, float x2, float w2) {
    float left = max(x1 - w1 / 2.0f, x2 - w2 / 2.0f);
    float right = min(x1 + w1 / 2.0f, x2 + w2 / 2.0f);
    return right - left;
}
static inline float cal_iou(vector<float> box, vector<float> truth) {
    float w = overlap(box[0], box[2], truth[0], truth[2]);
    float h = overlap(box[1], box[3], truth[1], truth[3]);
    if (w < 0 || h < 0) return 0;
    float inter = w * h;
    float uni = box[2] * box[3] + truth[2] * truth[3] - inter;
    return inter / uni;
}

static void get_output(int8_t* dpuOut, int sizeOut, float scale, int oc, int oh, int ow, vector<float>& result) {
    for (int a = 0; a < oc; ++a)
        for (int b = 0; b < oh; ++b)
            for (int c = 0; c < ow; ++c) {
                int offset = b * oc * ow + c * oc + a;
                result[a * oh * ow + b * ow + c] = dpuOut[offset] * scale;
            }
}

// The original version of this built a nested
//     vector<vector<vector<float>>> swap(height*width, vector<vector<float>>(ANCHOR, vector<float>(85)))
// and copied every output value through it. For the 26x26 head that is 676*3 = 2028 separate vector
// allocations per frame, plus a full extra read+write of 172,380 floats.
//
// The intermediate is unnecessary: the copy was
//     swap[cell][c/85][c%85] = result[c*HW + cell]
// so swap[cell][anchor][k] == result[(anchor*85 + k)*HW + cell] exactly. Reading `result` directly
// with a stride of HW per field is mathematically identical - no rearrangement, no allocation -
// and it is verified against the old path by comparing detection output.
static void detect(vector<vector<float>>& boxes, const vector<float>& result, int channel,
                   int height, int width, int num, int sh, int sw) {
    const int conf_box = 5 + CLASSIFICATION;
    const int HW = height * width;
    for (int h = 0; h < height; ++h) {
        for (int w = 0; w < width; ++w) {
            const int cell = h * width + w;
            for (int c = 0; c < ANCHOR; ++c) {
                // stride is HW between consecutive fields k of the same anchor
                const float* base = &result[c * conf_box * HW + cell];
                float obj = sigmoid(base[4 * HW]);
                if (obj < CONF) continue;
                vector<float> box;
                box.push_back((w + sigmoid(base[0])) / width);
                box.push_back((h + sigmoid(base[1 * HW])) / height);
                box.push_back(expf(base[2 * HW]) * biases[2 * c + ANCHOR * 2 * num] / (float)sw);
                box.push_back(expf(base[3 * HW]) * biases[2 * c + ANCHOR * 2 * num + 1] / (float)sh);
                box.push_back(-1);
                box.push_back(obj);
                for (int p = 0; p < CLASSIFICATION; ++p)
                    box.push_back(obj * sigmoid(base[(5 + p) * HW]));
                boxes.push_back(box);
            }
        }
    }
}

static vector<vector<float>> apply_nms(vector<vector<float>>& boxes, int classes, float thres) {
    vector<pair<int, float>> order(boxes.size());
    vector<bool> keep;                       // reused across the 80 class passes (no realloc)
    vector<vector<float>> result;
    for (int k = 0; k < classes; ++k) {
        for (size_t i = 0; i < boxes.size(); ++i) {
            order[i].first = i;
            boxes[i][4] = k;
            order[i].second = boxes[i][6 + k];
        }
        sort(order.begin(), order.end(),
             [](const pair<int,float>& a, const pair<int,float>& b) { return a.second > b.second; });
        keep.assign(boxes.size(), true);
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

static void correct_region_boxes(vector<vector<float>>& boxes, int n, int w, int h, int netw, int neth) {
    int new_w = 0, new_h = 0;
    if (((float)netw / w) < ((float)neth / h)) { new_w = netw; new_h = (h * netw) / w; }
    else                                       { new_h = neth; new_w = (w * neth) / h; }
    for (int i = 0; i < n; ++i) {
        boxes[i][0] = (boxes[i][0] - (netw - new_w) / 2. / netw) / ((float)new_w / netw);
        boxes[i][1] = (boxes[i][1] - (neth - new_h) / 2. / neth) / ((float)new_h / neth);
        boxes[i][2] *= (float)netw / new_w;
        boxes[i][3] *= (float)neth / new_h;
    }
}

// ---- inference side: DPU output tensors -> NMS -> normalised boxes ----
// Runs on the inference thread. Touches the DPU and nothing else the display thread owns.
static void decode_boxes(DPUTask* task, int sw, int sh, vector<Box>& out) {
    out.clear();
    vector<vector<float>> boxes;
    for (size_t i = 0; i < outputs_node.size(); ++i) {
        const string& node = outputs_node[i];
        int channel = dpuGetOutputTensorChannel(task, node.c_str());
        int width   = dpuGetOutputTensorWidth(task, node.c_str());
        int height  = dpuGetOutputTensorHeight(task, node.c_str());
        int sizeOut = dpuGetOutputTensorSize(task, node.c_str());
        int8_t* dpuOut = dpuGetOutputTensorAddress(task, node.c_str());
        float scale = dpuGetOutputTensorScale(task, node.c_str());
        vector<float> result(sizeOut);
        get_output(dpuOut, sizeOut, scale, channel, height, width, result);
        detect(boxes, result, channel, height, width, (int)i, sh, sw);
    }
    correct_region_boxes(boxes, boxes.size(), FB_W, FB_H, sw, sh);
    vector<vector<float>> res = apply_nms(boxes, CLASSIFICATION, NMS_THRE);

    out.reserve(res.size());
    for (size_t i = 0; i < res.size(); ++i) {
        int cls = (int)res[i][4];
        if (cls < 0 || cls >= (int)class_names.size()) continue;
        Box b;
        b.cls  = cls;
        b.conf = res[i][5];
        b.x1 = res[i][0] - res[i][2] / 2.0f;      // keep normalised; the display side scales it
        b.y1 = res[i][1] - res[i][3] / 2.0f;
        b.x2 = res[i][0] + res[i][2] / 2.0f;
        b.y2 = res[i][1] + res[i][3] / 2.0f;
        out.push_back(b);
    }
}

// ---- display side: draw whatever boxes the inference thread last produced ----
// Runs on the display thread while holding g_boxmtx. No DPU access at all.
static void draw_boxes(Mat& img, const vector<Box>& boxes) {
    const float w = (float)img.cols, h = (float)img.rows;
    for (size_t i = 0; i < boxes.size(); ++i) {
        const Box& b = boxes[i];
        if (b.cls < 0 || b.cls >= (int)class_names.size()) continue;
        float xmin = max(0.0f, min(b.x1 * w, w - 1));
        float ymin = max(0.0f, min(b.y1 * h, h - 1));
        float xmax = max(0.0f, min(b.x2 * w, w - 1));
        float ymax = max(0.0f, min(b.y2 * h, h - 1));
        char buf[96];
        snprintf(buf, sizeof(buf), "%s %.2f", class_names[b.cls].c_str(), b.conf);

        rectangle(img, Point(xmin, ymin), Point(xmax, ymax), Scalar(255, 0, 0), 2);
        int baseline = 0;
        Size ts = getTextSize(buf, FONT_HERSHEY_SIMPLEX, 0.6, 1, &baseline);
        int ty = (int)ymin - 4;
        if (ty - ts.height < 0) ty = (int)ymin + ts.height + 4;   // keep the label on screen
        rectangle(img, Point(xmin, ty - ts.height - 4), Point(xmin + ts.width + 2, ty), Scalar(255,0,0), FILLED);
        putText(img, buf, Point(xmin + 1, ty - 2), FONT_HERSHEY_SIMPLEX, 0.6, Scalar(255,255,255), 1, LINE_AA);
    }
}

// ---------------- M-JPEG server ----------------
static std::mutex g_jmtx;
static std::vector<uchar> g_jpeg;
// atomic: the display thread increments it and every M-JPEG client thread reads it. It is only
// *mutated* under g_jmtx, but the readers test it outside the lock to avoid waking up every frame
// when there is nothing new - so the read itself has to be a proper atomic load.
static std::atomic<unsigned> g_seq(0);
static std::atomic<int> g_clients(0);
static std::atomic<long> g_frames(0);
static std::atomic<int> g_fps_x10(0);
static std::atomic<int> g_infer_ms(0);
static std::atomic<int> g_boxes_last(0);

static ssize_t send_all(int c, const char* p, size_t n) {
    size_t off = 0;
    while (off < n) {
        ssize_t k = send(c, p + off, n - off, MSG_NOSIGNAL);
        if (k <= 0) return -1;
        off += k;
    }
    return (ssize_t)n;
}

static const char* PAGE_HTML =
    "<!DOCTYPE html><html><head><meta charset=\"utf-8\">"
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
    "<title>OV5640 + DPU YOLOv3-tiny</title><style>"
    "html,body{margin:0;padding:0;background:#101418;color:#dfe6ee;"
    "font-family:system-ui,-apple-system,'Segoe UI',sans-serif;text-align:center}"
    "h1{font-size:15px;font-weight:600;margin:10px 0 6px;letter-spacing:.02em;opacity:.9}"
    ".wrap{display:inline-block;max-width:1024px;width:100%}"
    "img{width:100%;height:auto;display:block;border-radius:6px;background:#000}"
    ".bar{font-size:12px;opacity:.65;margin:8px 0 14px;font-variant-numeric:tabular-nums}"
    "b{color:#7ec8ff;font-weight:600}"
    "</style></head><body>"
    "<h1>OV5640 &rarr; DPU YOLOv3-tiny &middot; live detection</h1>"
    "<div class=\"wrap\"><img id=\"v\" src=\"/stream\" alt=\"live\">"
    "<div class=\"bar\"><b id=\"df\">-</b> fps display &middot; frames <b id=\"f\">-</b> "
    "&middot; DPU <b id=\"i\">-</b> ms &middot; <b id=\"b\">-</b> boxes "
    "&middot; <span id=\"s\">connecting...</span></div></div>"
    "<script>"
    "var v=document.getElementById('v');"
    "v.onload=function(){document.getElementById('s').textContent='streaming';};"
    "v.onerror=function(){document.getElementById('s').textContent='reconnecting...';};"
    "setInterval(function(){fetch('/stat').then(function(r){return r.json();}).then(function(j){"
    "document.getElementById('df').textContent=j.display_fps;"
    "document.getElementById('f').textContent=j.display_frames;"
    "document.getElementById('i').textContent=j.infer_ms;"
    "document.getElementById('b').textContent=j.boxes;"
    "document.getElementById('s').textContent=j.clients+' viewer(s)';"
    "}).catch(function(){});},1000);"
    "</script></body></html>";

static void* client_thread(void* arg) {
    int c = (int)(long)arg;
    char req[1024] = {0};
    recv(c, req, sizeof(req) - 1, 0);

    if (strstr(req, "GET /stat") != NULL) {
        char body[320];
        int n = snprintf(body, sizeof(body),
                         "{\"display_fps\":%.1f,\"display_frames\":%ld,\"infer_ms\":%d,"
                         "\"inferences\":%ld,\"boxes\":%d,\"clients\":%d}",
                         g_fps_x10.load() / 10.0, (long)g_frames.load(),
                         g_infer_ms.load(), (long)g_infer_count.load(),
                         g_boxes_last.load(), g_clients.load());
        char hdr[192];
        int hn = snprintf(hdr, sizeof(hdr),
                          "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
                          "Cache-Control: no-store\r\nContent-Length: %d\r\nConnection: close\r\n\r\n", n);
        send_all(c, hdr, hn);
        send_all(c, body, n);
        close(c);
        g_clients--;                     // every branch must decrement, or the count only grows
        return nullptr;
    }
    if (strstr(req, "GET /latest") != NULL) {
        vector<uchar> copy;
        { std::lock_guard<std::mutex> lk(g_jmtx); copy = g_jpeg; }
        char h[224];
        int hn = snprintf(h, sizeof(h),
                          "HTTP/1.1 200 OK\r\nContent-Type: image/jpeg\r\nCache-Control: no-store\r\n"
                          "Content-Length: %zu\r\nConnection: close\r\n\r\n", copy.size());
        send_all(c, h, hn);
        if (!copy.empty()) send_all(c, (const char*)copy.data(), copy.size());
        close(c);
        g_clients--;
        return nullptr;
    }
    if (strstr(req, "GET /stream") == NULL) {          // anything else -> the page
        size_t n = strlen(PAGE_HTML);
        char h[192];
        int hn = snprintf(h, sizeof(h),
                          "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n"
                          "Cache-Control: no-store\r\nContent-Length: %zu\r\nConnection: close\r\n\r\n", n);
        send_all(c, h, hn);
        send_all(c, PAGE_HTML, n);
        close(c);
        g_clients--;
        return nullptr;
    }

    const char* hdr = "HTTP/1.1 200 OK\r\n"
                      "Content-Type: multipart/x-mixed-replace; boundary=frame\r\n"
                      "Cache-Control: no-store\r\nConnection: close\r\n\r\n";
    send_all(c, hdr, strlen(hdr));
    unsigned last = 0;
    int idle = 0;
    while (1) {
        if (g_seq != last) {
            vector<uchar> copy;
            { std::lock_guard<std::mutex> lk(g_jmtx); copy = g_jpeg; last = g_seq; }
            idle = 0;
            if (copy.empty()) { usleep(10000); continue; }
            char h[160];
            int hn = snprintf(h, sizeof(h),
                              "--frame\r\nContent-Type: image/jpeg\r\nContent-Length: %zu\r\n\r\n",
                              copy.size());
            if (send_all(c, h, hn) < 0) break;
            if (send_all(c, (const char*)copy.data(), copy.size()) < 0) break;
            if (send_all(c, "\r\n", 2) < 0) break;
        } else {
            usleep(5000);
            if (++idle > 2400) break;                  // ~12 s with no new frame
        }
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
    a.sin_port = htons(MJPEG_PORT);
    if (bind(sfd, (sockaddr*)&a, sizeof(a)) < 0) {
        fprintf(stderr, "[HTTP] bind :%d failed: %s\n", MJPEG_PORT, strerror(errno));
        return nullptr;
    }
    listen(sfd, 8);
    printf("[HTTP] http://0.0.0.0:%d/  (/stream = M-JPEG, /latest = one JPEG, /stat = JSON)\n", MJPEG_PORT);
    fflush(stdout);
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

// ---------------- inference thread ----------------
// Owns the DPU task and produces g_boxes. Runs completely independently of the display loop: it
// waits for a frame boundary, grabs its OWN copy of the frame, then does preprocess -> DPU ->
// decode -> NMS. The only thing it shares with the display thread is g_boxes, behind g_boxmtx.
//
// Note it grabs its own frame rather than reading a buffer owned by the display thread. That costs
// one extra memcpy per inference (~5 ms out of 242 ms) but removes an entire class of race: there
// is no frame buffer that two threads can touch, so no lock has to be held across a 1.4 MB copy or
// across the 55 ms preprocess.
static DPUTask* g_task = nullptr;
static int      g_sw = 416, g_sh = 416;

static void* infer_thread(void*) {
    unsigned char* frame = (unsigned char*)malloc(FB_SIZE);
    if (!frame) { fprintf(stderr, "[INFER] malloc failed\n"); return nullptr; }
    Mat raw(FB_H, FB_W, CV_8UC2, frame);
    Mat bgr;
    vector<Box> nb;
    long n = 0;
    printf("[INFER] thread started\n"); fflush(stdout);

    while (1) {
        wait_frame_start(400);
        memcpy(frame, (const void*)g_fb, FB_SIZE);
        cvtColor(raw, bgr, COLOR_BGR5652BGR);

        auto t0 = steady_clock::now();
        set_input_image(g_task, bgr, INPUTNODE);
        dpuRunTask(g_task);
        double ims = duration<double, milli>(steady_clock::now() - t0).count();

        decode_boxes(g_task, g_sw, g_sh, nb);
        {
            std::lock_guard<std::mutex> lk(g_boxmtx);
            g_boxes.swap(nb);
            g_boxes_last = (int)g_boxes.size();
        }
        g_infer_ms = (int)ims;
        ++n;
        g_infer_count = n;

        if (n % 20 == 0) {
            printf("[INFER] %ld inferences, DPU %.0f ms, boxes %d\n", n, ims, g_boxes_last.load());
            fflush(stdout);
        }
    }
    return nullptr;
}

// ---------------- main = the display thread ----------------
int main(void) {
    printf("[CAM] OV5640 + DPU M-JPEG streamer starting (display/inference decoupled)\n"); fflush(stdout);

    if (hw_map() < 0) return 1;

    printf("[DPU] dpuOpen + dpuLoadKernel(\"%s\") ...\n", YOLOKERNEL); fflush(stdout);
    dpuOpen();
    DPUKernel* kernel = dpuLoadKernel(YOLOKERNEL);
    if (!kernel) { fprintf(stderr, "[DPU] dpuLoadKernel failed\n"); return 1; }
    g_task = dpuCreateTask(kernel, 0);
    if (!g_task) { fprintf(stderr, "[DPU] dpuCreateTask failed\n"); return 1; }
    g_sh = dpuGetInputTensorHeight(g_task, INPUTNODE);
    g_sw = dpuGetInputTensorWidth(g_task, INPUTNODE);
    printf("[DPU] ready, network input %dx%d\n", g_sw, g_sh); fflush(stdout);

    pthread_t st, it;
    pthread_create(&st, nullptr, server_thread, nullptr);
    pthread_create(&it, nullptr, infer_thread, nullptr);

    printf("[CAM] waiting for the camera to produce frames ...\n"); fflush(stdout);
    int waited = 0;
    while (*g_dbg > 2u && waited < 5000) { usleep(1000); ++waited; }
    printf("[CAM] camera alive (dbg=%u after %d ms)\n", *g_dbg, waited); fflush(stdout);

    Mat bgr565(FB_H, FB_W, CV_8UC2, g_local);
    Mat bgr;
    vector<int> jp = { IMWRITE_JPEG_QUALITY, 60 };
    long frames = 0;
    auto t_fps = steady_clock::now();

    double acc_grab = 0, acc_cvt = 0, acc_draw = 0, acc_jpg = 0;
    int acc_n = 0;

    // Reused across frames. swap() below hands the buffer to the M-JPEG clients and takes back
    // whatever they were holding, so this allocation happens once instead of once per frame.
    vector<uchar> jpeg;

    while (1) {
        auto ts0 = steady_clock::now();
        wait_frame_start(400);
        memcpy(g_local, (const void*)g_fb, FB_SIZE);
        auto ts1 = steady_clock::now();

        cvtColor(bgr565, bgr, COLOR_BGR5652BGR);
        auto ts2 = steady_clock::now();

        // draw whatever the inference thread last found - microseconds under the lock
        { std::lock_guard<std::mutex> lk(g_boxmtx); draw_boxes(bgr, g_boxes); }
        auto ts3 = steady_clock::now();

        ++frames;
        double since = duration<double>(steady_clock::now() - t_fps).count();
        if (since >= 2.0) {
            g_fps_x10 = (int)(frames / since * 10);
            frames = 0; t_fps = steady_clock::now();
        }
        int nbox = g_boxes_last.load();
        char st_line[192];
        snprintf(st_line, sizeof(st_line), "display %.1f fps  |  DPU %d ms  %d box%s  %dx%d",
                 g_fps_x10.load() / 10.0, g_infer_ms.load(), nbox, nbox == 1 ? "" : "es", FB_W, FB_H);
        putText(bgr, st_line, Point(10, 28), FONT_HERSHEY_SIMPLEX, 0.7, Scalar(0, 0, 0), 3, LINE_AA);
        putText(bgr, st_line, Point(10, 28), FONT_HERSHEY_SIMPLEX, 0.7, Scalar(0, 255, 255), 1, LINE_AA);
        auto ts4 = steady_clock::now();

        // Encode straight out of `bgr`, with no clone. The old code cloned because the coupled
        // pipeline needed the un-annotated image afterwards; nothing does now, and the clone was
        // costing 4.4 MB of memory traffic (~3 ms) every frame.
        imencode(".jpg", bgr, jpeg, jp);
        { std::lock_guard<std::mutex> lk(g_jmtx); g_jpeg.swap(jpeg); ++g_seq; }
        auto ts5 = steady_clock::now();

        auto msd = [](steady_clock::time_point a, steady_clock::time_point b) {
            return duration<double, milli>(b - a).count();
        };
        acc_grab += msd(ts0, ts1);
        acc_cvt  += msd(ts1, ts2);
        acc_draw += msd(ts2, ts3);
        acc_jpg  += msd(ts4, ts5);
        ++acc_n;
        g_frames++;

        if (g_frames.load() % 60 == 0) {
            printf("[LOOP] %ld frames, %.1f fps | grab %.1f  cvt %.1f  draw %.1f  jpeg %.1f  "
                   "(ms, avg over %d) | infer %d ms, %d boxes, %ld inferences\n",
                   (long)g_frames.load(), g_fps_x10.load() / 10.0,
                   acc_grab/acc_n, acc_cvt/acc_n, acc_draw/acc_n, acc_jpg/acc_n, acc_n,
                   g_infer_ms.load(), g_boxes_last.load(), (long)g_infer_count.load());
            fflush(stdout);
            acc_grab = acc_cvt = acc_draw = acc_jpg = 0;
            acc_n = 0;
        }
    }
    return 0;
}

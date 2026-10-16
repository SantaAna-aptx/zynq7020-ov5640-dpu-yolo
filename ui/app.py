# -*- coding: utf-8 -*-
"""YOLO DPU 检测平台 - PC 端控制台
浏览器 UI -> Flask -> 串口(COM10) -> 板卡 tiny_yolo_image_diag -> 结果回收展示
"""
import os, re, time, json, threading, subprocess, socket, shutil, urllib.request

from flask import Flask, request, jsonify, send_from_directory, render_template, abort

BASE = r'E:\yoloProject'
WEBDIR = os.path.join(BASE, 'web')                  # PC http server root (board wget source)
IMGDIR = os.path.join(WEBDIR, 'test_images')
STATIC = os.path.join(BASE, 'ui', 'static')
THUMBS = os.path.join(STATIC, 'thumbs')
RESULTS = os.path.join(STATIC, 'results')
for d in (IMGDIR, THUMBS, RESULTS):
    os.makedirs(d, exist_ok=True)

BOARD_IP = '192.168.1.10'
BOARD_HTTP = 'http://%s:8080' % BOARD_IP
PC_HTTP = 'http://192.168.1.100:8000'

sys_path = os.path.join(BASE, 'board_deploy')
import sys
sys.path.insert(0, sys_path)

app = Flask(__name__, static_folder=STATIC, static_url_path='/static')
serial_lock = threading.Lock()
BOARD = None          # lazy Board instance
BOARD_OWNER = None

STATE = r'E:\yoloProject\board_deploy\autopilot_state.txt'
WCFG = r'E:\yoloProject\board_deploy\autopilot_cfg.json'
UI_CFG = os.path.join(BASE, 'ui', 'ui_cfg.json')


def serial_enabled():
    try:
        return json.load(open(UI_CFG)).get('use_serial', False)
    except Exception:
        return False


def read_state():
    try:
        return open(STATE).read().strip()
    except Exception:
        return '?'


def get_board(timeout=15):
    """Acquire serial board handle (single global). Waits for autopilot release."""
    if not serial_enabled():
        raise RuntimeError('serial is owned by autopilot (use_serial=false)')
    global BOARD
    deadline = time.time() + timeout
    while time.time() < deadline:
        st = read_state()
        if st not in ('WATCHING', 'LOGIN_PROMPT', 'UBOOT_SEQ', 'UBOOT_BOORING', 'DEBIAN_LOGIN'):
            break
        time.sleep(0.5)
    if BOARD is None:
        from board_ctl import Board
        BOARD = Board()
        st = BOARD.try_shell()
        if st != 'shell':
            BOARD.close()
            BOARD = None
            raise RuntimeError('board shell not ready (state=%s)' % st)
    return BOARD


def release_board():
    global BOARD
    if BOARD is not None:
        try:
            BOARD.close()
        except Exception:
            pass
        BOARD = None


def bcmd(c, timeout=60):
    b = get_board()
    with serial_lock:
        return b.cmd(c, timeout=timeout)


def ensure_pc_http():
    s = socket.socket()
    s.settimeout(1)
    try:
        s.connect(('127.0.0.1', 8000))
        s.close()
        return True
    except Exception:
        s.close()
    subprocess.Popen(['python', '-m', 'http.server', '8000', '--directory', WEBDIR, '--bind', '0.0.0.0'],
                     creationflags=subprocess.CREATE_NO_WINDOW)
    time.sleep(2)
    return True


def ensure_board_http():
    out = bcmd('netstat -tln 2>/dev/null | grep -c :8080 || echo 0', timeout=20)
    if out.strip().endswith('0'):
        bcmd('busybox httpd -p 8080 -h /home/root &', timeout=15)
        time.sleep(1)


def enable_dpu():
    seq = ['devmem 0xF8000008 32 0xDF0D',
           'devmem 0xF8000170 32 0x00400A00',
           'devmem 0xF8000174 32 0x00400A00',
           'devmem 0xF800021C 32 0x00000000']
    for c in seq:
        bcmd(c, timeout=20)
    out = bcmd('ls -la /dev/dpu || insmod /home/root/dpu.ko', timeout=30)
    out2 = bcmd('ls -la /dev/dpu', timeout=15)
    ok = 'dev/dpu' in out2
    return ok, out2


def board_status():
    try:
        b = get_board()
        with serial_lock:
            fclk0 = b.cmd('devmem 0xF8000170', timeout=15)
            fclk1 = b.cmd('devmem 0xF8000174', timeout=15)
            dpu = b.cmd('ls -la /dev/dpu 2>/dev/null || echo NO_DPU_DEV', timeout=15)
            net = b.cmd('ifconfig eth0 2>/dev/null | grep "inet addr" || echo NO_NET', timeout=15)
        dpu_ok = ('dev/dpu' in dpu) and ('NO_DPU' not in dpu)
        net_ok = 'inet addr' in net
        if not net_ok:
            bcmd('ifconfig eth0 192.168.1.10 netmask 255.255.255.0 up', timeout=20)
            time.sleep(1)
            net = bcmd('ifconfig eth0 2>/dev/null | grep "inet addr" || echo NO_NET', timeout=15)
            net_ok = 'inet addr' in net
        try:
            ensure_board_http()
        except Exception:
            pass
        return {'shell': True, 'dpu': dpu_ok, 'dpu_info': dpu[:200],
                'net': net_ok, 'net_info': net.strip()[:120],
                'fclk0': fclk0.strip(), 'fclk1': fclk1.strip()}
    except Exception as e:
        return {'shell': False, 'error': str(e), 'watcher_state': read_state()}


def sanitize(name):
    name = os.path.basename(name)
    return name if re.match(r'^[A-Za-z0-9._-]+$', name) else ''


def push_image_to_board(name):
    # board pulls from PC http server
    out = bcmd('cd /home/root && wget -q %s/test_images/%s -O /home/root/%s && echo PUSH_OK || echo PUSH_FAIL'
               % (PC_HTTP, name, name), timeout=120)
    return 'PUSH_OK' in out


def run_inference(name):
    base = os.path.splitext(name)[0]
    cmds = ('cd /home/root && ./tiny_yolo_image_diag %s > /home/root/last_out.txt 2>&1; '
            'mkdir -p /home/root/results; '
            'cp /home/root/result.jpg /home/root/results/%s_result.jpg 2>/dev/null; '
            'cp /home/root/result.bmp /home/root/results/%s_result.bmp 2>/dev/null; echo INFER_DONE' % (name, base, base))
    out = bcmd(cmds, timeout=180)
    if 'INFER_DONE' not in out:
        return None, 'inference did not finish: %s' % out[:200]
    text = bcmd('cat /home/root/last_out.txt', timeout=60)
    return parse_output(text), None


DET_RE = re.compile(r'Class name:\s*(.+?)\s+\[ID\]:(\d+)\s+conf=([\d.]+)\s+box=\((\d+),(\d+)\)-\((\d+),(\d+)\)')


def parse_output(text):
    dets = []
    for m in DET_RE.finditer(text):
        dets.append({'cls': m.group(1), 'id': int(m.group(2)), 'conf': float(m.group(3)),
                     'box': [int(m.group(4)), int(m.group(5)), int(m.group(6)), int(m.group(7))]})
    summary = {}
    for key in ['DETERM_CHECK', 'BOXES', 'OUT0', 'OUT1', 'IN_SCALE']:
        m = re.search(re.escape(key) + r':?\s*(.*)', text)
        if m:
            summary[key] = m.group(1).strip()[:150]
    timing = dict(re.findall(r'___?([A-Za-z_ ]+time):\s+([\d.]+)', text))
    total = re.search(r'Total time:\s+[\d.]+ seconds', text)
    return {'dets': dets, 'summary': summary, 'timing': timing,
            'total': total.group(0) if total else '', 'raw': text[-1500:]}


def fetch_board_result(base):
    """Pull result image from board httpd into local static cache."""
    url = '%s/results/%s_result.jpg' % (BOARD_HTTP, base)
    dst = os.path.join(RESULTS, '%s_result.jpg' % base)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'ui'})
        data = urllib.request.urlopen(req, timeout=20).read()
        with open(dst, 'wb') as f:
            f.write(data)
        return True
    except Exception:
        return False


def thumb_for(name):
    src = os.path.join(IMGDIR, name)
    dst = os.path.join(THUMBS, name + '.png')
    if not os.path.exists(dst):
        try:
            from PIL import Image
            im = Image.open(src).convert('RGB')
            im.thumbnail((240, 240))
            im.save(dst)
        except Exception:
            return None
    return '/static/thumbs/%s.png' % name


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/api/status')
def api_status():
    if not serial_enabled():
        try:
            st = open(STATE).read().strip()
        except Exception:
            st = '?'
        return jsonify({'shell': False, 'autopilot': st,
                        'message': 'autopilot holds serial; UI network mode pending board recovery'})
    try:
        st = board_status()
    except Exception as e:
        st = {'shell': False, 'error': str(e)}
    return jsonify(st)


@app.route('/api/images')
def api_images():
    out = []
    for n in sorted(os.listdir(IMGDIR)):
        if not re.match(r'^[A-Za-z0-9._-]+\.(jpg|jpeg|png)$', n, re.I):
            continue
        out.append({'name': n, 'thumb': thumb_for(n)})
    return jsonify(out)


@app.route('/images/<path:name>')
def serve_image(name):
    return send_from_directory(IMGDIR, sanitize(name))


@app.route('/static/results/<path:name>')
def serve_result(name):
    return send_from_directory(RESULTS, sanitize(name))


@app.route('/api/upload', methods=['POST'])
def api_upload():
    f = request.files.get('file')
    if not f:
        return jsonify({'error': 'no file'}), 400
    name = sanitize(f.filename)
    if not name:
        return jsonify({'error': 'bad filename'}), 400
    f.save(os.path.join(IMGDIR, name))
    try:
        thumb_for(name)
    except Exception:
        pass
    return jsonify({'ok': True, 'name': name})


@app.route('/api/infer', methods=['POST'])
def api_infer():
    name = sanitize(request.json.get('name', ''))
    if not name:
        return jsonify({'error': 'bad name'}), 400
    ensure_pc_http()
    try:
        if not push_image_to_board(name):
            return jsonify({'error': 'push image to board failed (network?)'}), 500
        res, err = run_inference(name)
        if err:
            return jsonify({'error': err}), 500
        base = os.path.splitext(name)[0]
        got = fetch_board_result(base)
        return jsonify({'ok': True, 'name': name, 'result': res,
                        'result_url': '/static/results/%s_result.jpg' % base if got else None,
                        'orig_url': '/images/%s' % name})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        release_board()


if __name__ == '__main__':
    ensure_pc_http()
    app.run(host='0.0.0.0', port=5000, threaded=True)

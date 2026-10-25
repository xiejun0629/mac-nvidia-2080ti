#!/usr/bin/env python3
"""恢复环境反向命令通道（relay server）。

背景：macOS 恢复环境（只读系统）没有可用的 sshd（Privilege separation user sshd
does not exist），因此改为"恢复环境主动轮询"的 HTTP 通道：

    恢复环境 agent  --GET /get-->  服务器（取一条命令）
    恢复环境 agent  --POST /put?i=ID--> 服务器（回传输出）

用法（服务器 192.168.1.223）：
    python3 relay-server.py            # 监听 203.0.113.10:18199
    curl -s http://127.0.0.1:18199/ping

接口：
    GET  /a.sh        返回 agent 脚本（恢复环境里 curl -s .../a.sh | sh 即可）
    GET  /ping        -> pong
    GET  /add?c=CMD   入队一条命令（URL 编码）-> 返回 id
    GET  /get         agent 取命令："id\\ncmd"；空则空响应
    POST /put?i=ID    回传某条命令的输出
    GET  /res?i=ID    查询输出（"__PENDING__" 表示还没执行完）
    GET  /state       队列/完成状态 JSON
    GET  /clear       清空队列与结果
"""
import http.server, socketserver, urllib.parse, threading, itertools, collections, json

AGENT = r'''#!/bin/sh
# 恢复环境 agent：轮询 relay server，执行命令并回传输出。
# 关键：caffeinate 防止恢复环境休眠（否则几分钟后掉线）；150s 看门狗；输出截断 48KB。
B=http://192.168.1.223:18199
: >/tmp/agent3.log
reach(){ /usr/bin/curl -s -m 5 "$B/ping" 2>/dev/null | /usr/bin/grep -q pong; }
[ -x /usr/bin/caffeinate ] && /usr/bin/caffeinate -dimsu >/dev/null 2>&1 &
/sbin/ifconfig en0 2>/dev/null | /usr/bin/grep -q "inet " || {
  /sbin/ifconfig en0 inet 192.168.1.240 netmask 203.0.113.10 2>/dev/null
  /sbin/route add default 192.168.1.1 2>/dev/null
}
reach || { echo "AGENT-ABORT-NET"; exit 1; }
EN0=$(/sbin/ifconfig en0 2>/dev/null | /usr/bin/awk '/inet /{print $2}')
CAF=""; [ -x /usr/bin/caffeinate ] && CAF="caffeinate-started"
/usr/bin/curl -s -m 10 --data-binary "AGENT-UP3 $(date) en0=$EN0 $CAF" "$B/put?i=0" >/dev/null 2>&1
echo "AGENT-UP3 $(date) en0=$EN0 $CAF"
while :; do
  R=$(/usr/bin/curl -s -m 20 "$B/get" 2>/dev/null)
  if [ -z "$R" ]; then sleep 2; continue; fi
  ID=$(printf '%s\n' "$R" | /usr/bin/awk 'NR==1{print; exit}')
  C=$(printf '%s\n' "$R" | /usr/bin/awk 'NR>1')
  [ "$C" = "__EXIT__" ] && { echo "AGENT-EXIT"; break; }
  /bin/sh -c "$C" >/tmp/.co 2>&1 &
  P=$!
  n=0
  while kill -0 "$P" 2>/dev/null; do
    n=$((n+1))
    if [ "$n" -ge 150 ]; then kill -9 "$P" 2>/dev/null; printf '\n__WATCHDOG_TIMEOUT_150s__\n' >>/tmp/.co; break; fi
    sleep 1
  done
  /usr/bin/tail -c 48000 /tmp/.co | /usr/bin/curl -s -m 100 --data-binary @- "$B/put?i=$ID" >/dev/null 2>&1
  /bin/rm -f /tmp/.co
done
'''

pending = collections.deque()
results = {}
lock = threading.Lock()
counter = itertools.count(1)

class H(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.0"
    def log_message(self, *a): pass
    def _send(self, code, body):
        b = body.encode() if isinstance(body, str) else body
        try:
            self.send_response(code)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(b)))
            self.end_headers()
            self.wfile.write(b)
        except Exception:
            pass
    def do_GET(self):
        u = urllib.parse.urlparse(self.path)
        q = urllib.parse.parse_qs(u.query, keep_blank_values=True)
        if u.path in ("/a.sh", "/agent"):
            return self._send(200, AGENT)
        if u.path == "/ping":
            return self._send(200, "pong")
        if u.path == "/clear":
            with lock:
                pending.clear(); results.clear()
            return self._send(200, "cleared")
        if u.path == "/add":
            cmd = q.get("c", [""])[0]
            if not cmd: return self._send(400, "empty")
            with lock:
                i = next(counter); pending.append((i, cmd))
            return self._send(200, str(i))
        if u.path == "/get":
            with lock:
                if not pending: return self._send(200, "")
                i, c = pending.popleft()
            return self._send(200, "%d\n%s" % (i, c))
        if u.path == "/res":
            i = q.get("i", [""])[0]
            with lock: r = results.get(i)
            return self._send(200, "__PENDING__" if r is None else r)
        if u.path == "/state":
            with lock:
                return self._send(200, json.dumps({"pending": [i for i, _ in pending], "done": list(results.keys())}))
        return self._send(404, "no")
    def do_POST(self):
        u = urllib.parse.urlparse(self.path)
        q = urllib.parse.parse_qs(u.query, keep_blank_values=True)
        n = int(self.headers.get("Content-Length", "0") or 0)
        body = self.rfile.read(n).decode("utf-8", "replace")
        if u.path == "/put":
            i = q.get("i", [""])[0]
            with lock: results[i] = body
            return self._send(200, "ok")
        return self._send(404, "no")

class S(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

if __name__ == "__main__":
    print("relay server on 203.0.113.10:18199", flush=True)
    S(("203.0.113.10", 18199), H).serve_forever()

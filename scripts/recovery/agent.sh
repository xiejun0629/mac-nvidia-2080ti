#!/bin/sh
# 恢复环境 agent（与 relay-server.py 内嵌版本一致，单独保存便于阅读/修改）。
# 用法（恢复环境终端）：curl -s http://192.168.1.223:18199/a.sh | sh
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

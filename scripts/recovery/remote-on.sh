#!/bin/sh
# remote-on.sh v4 -- macOS Recovery: static LAN IP + root sshd + diagnostics
# run in Recovery Terminal:  diskutil mount <ESP device> ; sh /Volumes/OCESP/remote-on.sh
ESP=/Volumes/OCESP
[ -d "$ESP" ] || ESP=/Volumes/EFI
LOG=$ESP/remote-on-report.txt
say(){ printf '%s\n' "$*"; printf '%s\n' "$*" >>"$LOG" 2>/dev/null; }
say "=== remote-on v4 $(date) ==="
say "sw: $(sw_vers 2>/dev/null | tr '\n' ' ')"

# ---------- 1) network: static .155, fallback .240 ----------
CAND=""
for i in $(ifconfig -l 2>/dev/null); do
  case "$i" in lo0|gif*|stf*|utun*|awdl*|llw*|bridge*|ap*|anpi*|p2p*) continue;; esac
  CAND="$CAND $i"
done
say "candidates:$CAND"
NET=""
for ip in 192.168.1.240 192.168.1.241; do
  for i in $CAND; do
    ifconfig "$i" up 2>/dev/null
    ifconfig "$i" inet "$ip" netmask 203.0.113.10 2>/dev/null
    sleep 1
    route -n add default 192.168.1.1 >/dev/null 2>&1 || route -n change default 192.168.1.1 >/dev/null 2>&1
    if ping -c 2 -t 2 192.168.1.1 >/dev/null 2>&1; then
      NET="$i"; say "NET-OK iface=$i ip=$ip"; break
    fi
    ifconfig "$i" inet 203.0.113.10 2>/dev/null
  done
  [ -n "$NET" ] && break
done
[ -n "$NET" ] || say "NET-FAIL"

# ---------- 2) key material ----------
# 公开版说明：原脚本内嵌的 hostkey / clientkey 私钥已移除（避免泄露）。
# 本地复现时使用临时生成的 ed25519 密钥：
mkdir -p /tmp/sshx
if [ ! -f /tmp/sshx/hostkey ]; then
  ssh-keygen -q -t ed25519 -N '' -f /tmp/sshx/hostkey
fi
if [ ! -f /tmp/sshx/id_ed25519 ]; then
  ssh-keygen -q -t ed25519 -N '' -f /tmp/sshx/id_ed25519
fi

# ---------- 3) sshd ----------
/usr/sbin/sshd -f /tmp/sshx/sshd_config -E /tmp/sshx/sshd.log
sleep 2
N=$(ps ax 2>/dev/null | grep -c '[s]shd')
say "sshd-custom procs=$N"
if [ "$N" -eq 0 ]; then
  say "trying launchd ssh.plist"
  launchctl load -w /System/Library/LaunchDaemons/ssh.plist >>"$LOG" 2>&1
  sleep 2
  N=$(ps ax 2>/dev/null | grep -c '[s]shd')
  say "sshd-launchd procs=$N"
fi
if [ "$N" -gt 0 ]; then say "RECOVERY-SSHD-UP"; else say "RECOVERY-SSHD-FAIL"; tail -15 /tmp/sshx/sshd.log >>"$LOG" 2>&1; fi

# ---------- 4) diagnostics + install recon ----------
say "--- ifconfig ---"; ifconfig -a >>"$LOG" 2>&1
say "--- volumes ---"; ls -1 /Volumes >>"$LOG" 2>&1
say "--- installer apps ---"
for v in /Volumes/*; do
  for a in "$v"/Applications/Install*.app; do [ -d "$a" ] && say "APP: $a"; done
done
say "--- macOS Install Data / update leftovers ---"
for v in /Volumes/*; do
  ls -d "$v"/macOS*Install* "$v"/System/Volumes/Update 2>/dev/null >>"$LOG" 2>&1
done
say "--- diskutil list ---"; diskutil list >>"$LOG" 2>&1
say "--- diskutil apfs list ---"; diskutil apfs list >>"$LOG" 2>&1
say "--- df ---"; df -k >>"$LOG" 2>&1
say "=== END $(date) ==="

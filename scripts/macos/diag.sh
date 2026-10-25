#!/bin/sh
# 1401 recovery diagnostics - run in macOS Recovery Terminal
SD="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
OUT="$SD/diag-report.txt"
[ -z "$SD" ] && OUT=/tmp/diag-report.txt
: > "$OUT"
log() { echo "$@" >> "$OUT" 2>&1; }
log "=== DIAG START $(date) ==="
log "sw_vers: $(sw_vers 2>&1 | tr '\n' '|')"
log "uname: $(uname -a)"
log "hw.model: $(sysctl -n hw.model 2>&1)"
log "script_dir: $SD"
log "== diskutil list =="
diskutil list >> "$OUT" 2>&1
log "== diskutil apfs list =="
diskutil apfs list >> "$OUT" 2>&1
log "== mount apfs container disk1s2 =="
diskutil mount disk1s2 >> "$OUT" 2>&1
sleep 2
log "== ls /Volumes =="
ls -la /Volumes >> "$OUT" 2>&1
for v in /Volumes/*/; do
  log "--- VOLUME: $v"
  ls "$v" >> "$OUT" 2>&1
  [ -d "$v/Applications" ] && { log "HAS-Applications:"; ls "$v/Applications" >> "$OUT" 2>&1; }
  [ -d "$v/Applications/Install macOS Sequoia.app" ] && log "HAS-SEQUOIA-APP"
  [ -d "$v/macOS Install Data" ] && { log "HAS-macOSInstallData:"; ls "$v/macOS Install Data" >> "$OUT" 2>&1; }
  [ -f "$v/macOS Install Data/InstallInfo.plist" ] && plutil -p "$v/macOS Install Data/InstallInfo.plist" >> "$OUT" 2>&1
  [ -d "$v/System/Library/CoreServices" ] && { log "HAS-CoreServices:"; ls "$v/System/Library/CoreServices" >> "$OUT" 2>&1; }
done
log "== bless info =="
bless --info / >> "$OUT" 2>&1
bless --getBoot >> "$OUT" 2>&1
log "== nvram filtered =="
nvram -p 2>&1 | grep -E "boot-args|efi-boot-device|csr-active|current-snapshot" >> "$OUT" 2>&1
log "== mount =="
mount >> "$OUT" 2>&1
log "== df =="
df -h >> "$OUT" 2>&1
log "=== DIAG COMPLETE $(date) ==="
echo "DONE - report saved to: $OUT"
echo "REPORT-DONE-1401"

#!/bin/bash
# 在"服务器"上执行：通过镜像下载 NullMoth 驱动包 + 1401 Mac 安装器，校验 SHA256，然后 scp 到 macOS 主机。
# 用法：./fetch-driver.sh 2.5.4
# 说明：Mac 上直连 GitHub 会超时（HTTP 000），所以由服务器下载再局域网传输。
set -euo pipefail
VER="${1:-2.5.4}"
BASE="https://github.com/nullmoth/nvidia-macos-driver/releases/download/v${VER}"
MIRRORS=("https://ghfast.top/" "https://gh-proxy.com/")
MAC="user@192.168.1.155"
DEST="/Users/user/1401-work"
WORK="${WORK:-/tmp/nullmoth-$VER}"
mkdir -p "$WORK" && cd "$WORK"

fetch() { # $1=file
  local f="$1" ok=0
  for m in "${MIRRORS[@]}"; do
    echo "== downloading $f via $m"
    if curl -fL --retry 3 --retry-delay 2 -m 1800 -o "$f" "${m}${BASE}/${f}"; then ok=1; break; fi
  done
  [ "$ok" = 1 ] || { echo "download failed: $f"; exit 1; }
}

fetch "nullmoth-nvidia-${VER}.tar.gz"
fetch "1401-Mac-${VER}.dmg"
fetch "SHA256SUMS.txt" || true

echo "== SHA256 =="
sha256sum "nullmoth-nvidia-${VER}.tar.gz" "1401-Mac-${VER}.dmg"
[ -f SHA256SUMS.txt ] && grep -E "nullmoth-nvidia-${VER}|1401-Mac-${VER}" SHA256SUMS.txt || true
echo "!! 请把上面的 SHA256 与发布页/API digest 对照后再继续 !!"
read -r -p "确认校验和正确后按回车继续（Ctrl+C 取消）" _ || true

scp "nullmoth-nvidia-${VER}.tar.gz" "1401-Mac-${VER}.dmg" "${MAC}:${DEST}/"
echo "== done: 文件已传到 ${MAC}:${DEST}"
echo "下一步（在 Mac 上）：hdiutil attach ~/1401-work/1401-Mac-${VER}.dmg -nobrowse"

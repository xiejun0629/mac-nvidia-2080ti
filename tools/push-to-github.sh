#!/bin/bash
# 把本仓库（服务器 Gitea）镜像到 GitHub。
# 用法：./push-to-github.sh user@example.com:<user>/<repo>.git
set -euo pipefail
REMOTE="${1:?用法: $0 <github repo url>}"
# 在服务器上执行时，从 Gitea 克隆再推送
SRC="${SRC:-http://192.168.1.223:3066/user/mac-nvidia-2080ti.git}"
TMP="$(mktemp -d)"
git clone --mirror "$SRC" "$TMP/repo.git"
cd "$TMP/repo.git"
git remote add github "$REMOTE"
git push --mirror github
cd /
rm -rf "$TMP"
echo "已镜像到 $REMOTE"

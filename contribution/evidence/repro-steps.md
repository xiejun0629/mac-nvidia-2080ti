# 复现步骤（含命令）

## 环境准备
1. BIOS：Secure Boot=Disabled、CSM=Off、**Above 4G Decoding=Enabled**、**Re-Size BAR Support=Auto**；
2. OpenCore：SMBIOS iMacPro1,1、csr 0x0A43、禁用 BlueToolFixup/SimpleMtkBtFw；
3. 显示器 DP 接 RTX 2080 Ti。

## A. UI 卡顿复现（驱动 2.3.6）
```bash
# 1) 确认驱动加载
kmutil showloaded | grep -i nullmoth
system_profiler SPDisplaysDataType | grep -A8 "2080 Ti"
# 2) 监控 WindowServer CPU（另开终端，拖动窗口时观察）
while :; do ps -o %cpu= -p $(pgrep -x WindowServer); sleep 1; done
# 3) 手动操作：拖动 Finder 窗口、打开启动台、按 F3(Mission Control)、Dock 放大
```
预期：空闲 0~2%，交互时约 100%+（单核）；动画低帧，光标流畅。

## B. 2.5.4 屏幕闪烁复现
1. 用 1401 安装器安装 2.5.4 并重启（见 `docs/04-DRIVER-UPDATE-RUNBOOK.md`）；
2. 登录桌面后静置观察：画面内容不变时出现周期性抖动/闪烁；
3. 回退 2.3.6（同手册"回退"一节），闪烁消失。

## C. `nvfbheads=1` 启动失败复现
1. 把 boot-args 改为 `nvfbheads=1` 并删除 `-nvkmsnosmooth`；
2. 重启选择 `apple`：verbose 白字后长时间无进展；
3. 强制关机 → OC 菜单 `1401: Start once without NVIDIA driver`（Y）→ 进系统后改回原参数。

## D. 驱动安装/回退通用命令
见 `docs/04-DRIVER-UPDATE-RUNBOOK.md`（dry-run → 安装 → 重启；回退用旧版本安装器）。

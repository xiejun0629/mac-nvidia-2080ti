# NullMoth 驱动：安装 / 升级 / 回退手册

## 0. 当前状态
- 驱动版本：**2.3.6**（回退原因：2.5.4 屏幕抽搐/闪烁；2.5.4 备份在 `/Library/NullMoth/backup-20261024-224248.7T2jdc`）。
- macOS 15.8.1 (24H32)；kexts 位于 `/Library/Extensions/{NVRM,NVAccel,NVRMFB,NVRMAGDC}.kext`。
- 救援入口已在 OpenCore 菜单：`1401: Start once without NVIDIA driver`、`1401: Remove NVIDIA driver`。

## 1. 升级前检查
```bash
sw_vers                                   # 15.8.1 (24H32)
plutil -p /Library/Extensions/NVRM.kext/Contents/Info.plist | grep CFBundleShortVersionString
kmutil showloaded | grep -i nullmoth
nvram boot-args
# 备份配置（ESP 挂载后）
PB=/usr/libexec/PlistBuddy; G=<REDACTED_UUID>
$PB -c "Print :NVRAM:Add:$G:boot-args" /Volumes/OCESP/EFI/OC/config.plist
cp /Volumes/OCESP/EFI/OC/config.plist ~/1401-work/config.plist.bak-$(date +%s)
```

## 2. 获取安装包（大陆镜像流程）
在**服务器**（能访问镜像、速度快）下载，再 scp 到 Mac：
```bash
# 版本号以 GitHub 最新 release 为准；以下为 2.5.4 示例
curl -L --retry 3 -o nullmoth-nvidia-2.5.4.tar.gz \
  "https://ghfast.top/https://github.com/nullmoth/nvidia-macos-driver/releases/download/v2.5.4/nullmoth-nvidia-2.5.4.tar.gz"
curl -L --retry 3 -o 1401-Mac-2.5.4.dmg \
  "https://ghfast.top/https://github.com/nullmoth/nvidia-macos-driver/releases/download/v2.5.4/1401-Mac-2.5.4.dmg"
sha256sum nullmoth-nvidia-2.5.4.tar.gz 1401-Mac-2.5.4.dmg
# 期望：648280bea54fa57809e3bf3b312bdb6709a00fa0292af3b37c665e111fe27eaa
#       a4c00042b5180573a98e7ca730bfe78a440cb2bfce9cbfb9ba52654705b38766
scp nullmoth-nvidia-2.5.4.tar.gz 1401-Mac-2.5.4.dmg user@192.168.1.155:/Users/user/1401-work/
```
镜像候选：`ghfast.top`、`gh-proxy.com`（服务器实测可用）；`github.com` 直连在 Mac 上超时。

## 3. 安装（dry-run → 正式）
```bash
# 1) 挂载新版 1401 app
hdiutil attach ~/1401-work/1401-Mac-2.5.4.dmg -nobrowse
cp -R "/Volumes/1401/1401.app" ~/1401-work/1401-2.5.4.app
APP=~/1401-work/1401-2.5.4.app

# 2) dry-run（只列出改动，不动系统）
sudo "$APP/Contents/Resources/nullmoth-setup.sh" \
  --pkg ~/1401-work/nullmoth-nvidia-2.5.4.tar.gz \
  --sha 648280bea54fa57809e3bf3b312bdb6709a00fa0292af3b37c665e111fe27eaa \
  --efi auto --tool "$APP/Contents/Resources/NullMothSafe.efi" \
  --profile ~/1401-work/machine-profile.json \
  --knob NVK_CMDPOOL_GPU_UNCACHED=1 --knob NVK_SYSMEM_GPU_UNCACHED=1 \
  --knob NVMTL_NO_NVENC=1 --knob NVMTL_NO_NVENC_HEVC=1 --dry

# 3) 正式安装（去掉 --dry）
sudo "$APP/Contents/Resources/nullmoth-setup.sh" …（同上，去掉 --dry）
# 4) 重启
sudo shutdown -r now
```
安装器行为：备份当前驱动到 `/Library/NullMoth/backup-*`、改 OpenCore config（boot-args + nvrmsettle、Kernel>Block IONDRVSupport、NVRAM Delete boot-args、救援工具项）、装 kexts、写状态记录。

## 4. 重启后验证
```bash
kmutil showloaded | grep -i nullmoth          # 四个 kext 应为新版本
system_profiler SPDisplaysDataType | grep -A6 "2080 Ti"
sysctl debug.nvrmfb_flip_latch                 # 默认 1
ls /Library/Logs/DiagnosticReports/*.panic 2>/dev/null   # 应为空
```

## 5. 回退（升级出问题）
1. 用**旧版 1401.app + 旧版驱动包**重新跑安装器（自动备份当前驱动）：
   ```bash
   sudo ~/1401-work/1401.app/Contents/Resources/nullmoth-setup.sh \
     --pkg ~/1401-work/nullmoth-nvidia-2.3.6.tar.gz \
     --sha 3855954d9069eca470e4dbc7f645a63bba888040ec099285ef044ece03ad8e4f \
     --efi auto --tool ~/1401-work/1401.app/Contents/Resources/NullMothSafe.efi \
     --profile ~/1401-work/machine-profile.json \
     --knob NVK_CMDPOOL_GPU_UNCACHED=1 --knob NVK_SYSMEM_GPU_UNCACHED=1 \
     --knob NVMTL_NO_NVENC=1 --knob NVMTL_NO_NVENC_HEVC=1
   sudo shutdown -r now
   ```
2. 启动失败时的救援：OpenCore 菜单 `1401: Start once without NVIDIA driver`（按 Y）或 `1401: Remove NVIDIA driver`（按 Y）。
3. 无显示时的最后一招（无画面移除驱动）：恢复环境终端执行
   `nvram <REDACTED_UUID>:nullmoth-remove=1` 后重启。

## 6. 已知注意事项
- 升级后**不要睡眠**（issue #353）。
- 修改 `/etc/sysctl.conf` 等系统级参数要记录并准备回滚（本次 `debug.nvrmfb_flip_latch=2` 已随回退删除）。
- 中国大陆下载务必校验 SHA256；安装前确保磁盘空间足够（≥ 3GB）。
- 升级前记录当前 boot-args 与 config 备份路径。

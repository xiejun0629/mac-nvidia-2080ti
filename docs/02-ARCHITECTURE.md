# 架构与设备清单

## 1. 硬件

| 部件 | 型号/规格 |
|---|---|
| 主板 | BESSTAR B550（AMI BIOS 5.17，2022-03-31；Secure Boot Disabled、CSM Off、Above 4G On、ReBAR Auto） |
| CPU | AMD Ryzen 7 5700G（Cezanne，8C16T；iGPU `1002:1638` Radeon RX Renoir） |
| 内存 | 32GB DDR4-3200 |
| 显卡 | NVIDIA GeForce RTX 2080 Ti（`10DE:1E07`，11GB，Turing TU102） |
| 网卡 | Intel I225-V（`00:11:22:33:44:55`，macOS 下 `en0`，kext AppleIGC 1.7d3） |
| 蓝牙/WiFi | RZ608（0e8d:0608）— macOS 下蓝牙固件 kext 已禁用 |
| 显示器 | AOC Q24G2，2560×1440，DP 接 2080 Ti（当前 165Hz） |

## 2. 磁盘布局（macOS 恢复环境视角，编号可能漂移）

| 磁盘 | 分区 | 说明 |
|---|---|---|
| disk2 (870 EVO 250GB) | disk2s1 NTFS | Windows F:（`/Volumes/本地磁盘`） |
| disk3 (Samsung 980 500GB) | disk3s1 NTFS `WIN1401` | Windows D:（`/Volumes/WIN1401`）；驱动包等资料在此 |
| | disk3s2 APFS Container `disk4` | macOS 容器 82.7GB：`apple - Data`(35.8G)、Preboot、Recovery、`apple`(系统)、VM |
| | disk3s3 `EFI OCESP` | 1.1GB，OpenCore ESP（`/Volumes/OCESP`）；含 `EFI/OC`、`com.apple.recovery.boot`（15.6.1 BaseSystem）、`remote-on.sh`、`bootstrap.sh`、`diag.sh`、OC 日志 |
| | disk3s4 Linux | 14.3GB |
| disk5 (Samsung 980 500GB) | disk5s1 EFI | 314MB 另一块 ESP |
| | disk5s3 NTFS | Windows C: 302.5GB |
| | disk5s4 WinRE / s5 Linux | |

- macOS 容器 UUID：`1882321A-…`（物理盘），Preboot 卷 `<REDACTED_UUID>`；系统卷组 `<REDACTED_UUID>`。
- 系统快照：`com.apple.os.update-C94EBF13…`。

## 3. 软件栈

- **OpenCore 1.0.9**（ESP：`EFI/OC`），SMBIOS `iMacPro1,1`，`csr-active-config = 0x0A43`，`SecureBootModel = Disabled`。
- **Kexts**（`Kernel > Add`）：Lilu 1.7.3、NootedRed 0.8.10、AMFIPass 1.4.1、AppleIGC 1.7d3、AppleMCEReporterDisabler、CtlnaAHCIPort、NVMeFix、RestrictEvents、USBToolBox、UTBDefault、VirtualSMC；**禁用**：BlueToolFixup、SimpleMtkBtFw。
- **ACPI**：SSDT-EC、SSDT-PLUG-ALT、SSDT-USB-Reset、SSDT-USBX。
- **Drivers**：HfsPlus.efi、OpenRuntime.efi、ResetNvramEntry.efi。
- **NVIDIA 驱动（NullMoth）**：kexts `NVRM / NVAccel / NVRMFB / NVRMAGDC`（当前 2.3.6，安装在 `/Library/Extensions`），
  GPU bundles 在 `/Library/GPUBundles`，状态/备份在 `/Library/NullMoth/`。
- **boot-args（当前）**：
  `-v debug=0x100 keepsyms=1 nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 nvrmsettle=10000`

## 4. 启动链

```
UEFI 固件（F7 选择“UEFI OS”）
  → OpenCore（ESP = OCESP）
      → 选择菜单条目：
          ├─ Windows（Windows Boot Manager）
          ├─ apple（macOS：Preboot/boot.efi → 内核 → 系统）
          ├─ Recovery 15.8.1（⚠️ 不可用，见踩坑 B1）
          ├─ OCESP（BaseSystem 15.6.1 恢复环境，救援用）
          └─ 1401: Start once without NVIDIA driver / Remove NVIDIA driver（驱动救援）
  → 正常启动：OpenCore 注入 kexts + boot-args → boot.efi → macOS
```

- 显示输出：Windows 与 macOS 都经过 2080 Ti 的 DP 输出；macOS 下显示由 **NVRMFB** 驱动。
- 核显（NootedRed）仍在系统中，主要承担 **AMD UVD/VCE 视频硬解/硬编**；显示不再依赖它。

## 5. 目录与服务

### macOS 侧
- `/Library/NullMoth/`：`driver-version`、`kexts/`、`backup-*/`（历史驱动备份）、`state`、`bootguard.sh`、`nullmoth-setup.sh`、`nullmoth-recover.sh`。
- `/Users/user/1401-work/`：`1401.app`（2.3.6 安装器）、`nullmoth-nvidia-2.3.6.tar.gz`、`nullmoth-nvidia-2.5.4.tar.gz`、`1401-Mac-2.5.4.dmg`、`machine-profile.json`、`config.plist.*` 备份、`driver-install-notes.txt`。
- SSH：`root@user-server` 的公钥在 `~/.ssh/authorized_keys`；`/etc/sudoers.d/1401` = `user ALL=(ALL) NOPASSWD: ALL`。
- DNS：路由器 `192.168.1.1` + `203.0.113.10`。

### 服务器侧（192.168.1.223）
- 恢复通道 relay：`scripts/recovery/relay-server.py`（监听 `:18199`，仅在需要时以后台任务运行）。
- DSH Web GUI：本机 `127.0.0.1:19387`；局域网入口 `192.168.1.223:19389`（Basic 认证）；frp 公网隧道见 `docs/05`。
- Gitea（docker，容器 `gitea`）：宿主端口 `3066`，域名 `example.com`，数据 `/opt/gitea/data`；本仓库：`user/mac-nvidia-2080ti`。
- 其他：Windows 主机 SSH `Administrator@192.168.1.155`（OpenSSH + PowerShell EncodedCommand）。

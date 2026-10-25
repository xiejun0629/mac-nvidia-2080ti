# 踩坑全记录（症状 → 根因 → 解法）

按"从零到可用"的阶段整理。所有条目都是这次实机踩过的。

---

## A. OpenCore / 引导层

### A1. OpenCore 配置解析失败，无法进 OC
- **症状**：开机停在 OC 报错（Failed to parse configuration / 版本不符），无法进入选择菜单。
- **根因**：ESP 上的 config.plist 损坏或与 OpenCore.efi 版本不匹配（曾出现 config 与备份长度/内容不一致）。
- **解法**：重新格式化 ESP，从完整备份恢复 `EFI` 目录；用 `plutil -lint`/`ocvalidate` 校验；记录 config 大小与 SHA256（本次基准：44657 字节，sha256 `7745701D…`）。

### A2. 启动卡死在 `SimpleMtkBtFw`
- **症状**：verbose 最后一行停在 `SimpleMtkBtFw`（MediaTek 蓝牙固件）或蓝牙相关初始化。
- **根因**：RZ608 蓝牙固件 kext 与该机器/系统不兼容，卡死启动流程。
- **解法**：在 config `Kernel > Add` 里把 `BlueToolFixup.kext` 与 `SimpleMtkBtFw.kext` 设为 `Enabled=false`。

### A3. 升级网卡 kext（AppleIGC 1.7d3 → 1.9）后 DHCP/网络异常
- **症状**：系统能起但拿不到 DHCP、网络异常。
- **根因**：AppleIGC 1.9 与 macOS 15.8.1 的匹配问题。
- **解法**：回退 AppleIGC 到 **1.7d3**（本项目已验证可用版本）。

### A4. 固件/BIOS 前置条件
- 必须：**Secure Boot = Disabled**、**CSM = Off**、**Above 4G Decoding = Enabled**、**Re-Size BAR Support = Auto（或 Enabled）**。
- 少了 Above 4G / ReBAR：NVIDIA 驱动初始化卡在 BAR1 分配（见 C4）。
- 启动方式：开机连按 **F7** → 选 **UEFI OS** → 进入 OpenCore 菜单。

---

## B. 恢复环境（Recovery）

### B1. `Recovery 15.8.1` 完全不可引导（重要）
- **症状**：OC 日志里 `#[EB.LD.OFS|OPEN!] Err(0xE) <"usr\standalone\OS.dmg.root_hash">`，随后 `EB.BST.FBS` 失败，卡在 `EXITBS:START`。
- **根因**：macOS 15.8.1 的恢复镜像在 AMD 平台上的已知问题（OpenCore bugtracker issue #2559），上游明确"AMD CPU 不支持"，无修复。
- **解法**：**只用 ESP 里的 BaseSystem 恢复**（OpenCore 菜单里的 `OCESP` 条目，版本 15.6.1 24G90）。

### B2. 恢复环境里 sshd 起不来
- **症状**：`sshd-custom procs=0`；日志 `/tmp/sshx/sshd.log` 显示 `Privilege separation user sshd does not exist`。
- **根因**：恢复系统是只读根，`/etc/passwd` 里没有 `sshd` 用户，无法补。
- **解法**：放弃 sshd，改用**反向 HTTP 轮询 agent**（见 `docs/03-RECOVERY-RUNBOOK.md`）。

### B3. 恢复环境会休眠，远程通道不定时掉线
- **症状**：`ping` 不通、relay 队列卡住；等一会唤醒后又正常。
- **根因**：恢复环境默认会睡眠。
- **解法**：agent 启动时执行 `caffeinate -dimsu &`（本项目 agent 已内置）；必要时让用户动一下鼠标/键盘唤醒。

### B4. BaseSystem 恢复里挂载 ESP 失败
- **症状**：`diskutil mount disk2s3` 报 "failed to mount … try ReadOnly"，`/Volumes/OCESP` 不存在。
- **根因**：BaseSystem 没自动加载 msdosfs；FAT 脏时也会拒绝挂载。
- **解法**：
  ```
  kmutil load -p /System/Library/Extensions/msdosfs.kext
  fsck_msdos -f -y /dev/rdisk2s3
  mkdir -p /Volumes/OCESP2
  mount -t msdos /dev/disk2s3 /Volumes/OCESP2
  ```
  （`diskutil mount` 在 BaseSystem 里不可靠，用 `mount -t msdos`。）

### B5. 磁盘编号每次进恢复都不一定一样
- **症状**：按旧编号 mount 报错。
- **解法**：每次先 `diskutil list`，按 **卷名**（EFI OCESP）而不是固定 disk 号定位，例如 `awk '/EFI OCESP/{print $NF; exit}'`。

---

## C. 已安装 macOS 的启动

### C1. 15.8.1 启动到一半自动重启（早期最坑）
- **症状**：OC 日志 `Prelinked status - Success`、`EXITBS:START` 之后内核阶段崩溃/自动重启；没有新 panic 日志。
- **根因（本次实测根因之一）**：**NVRAM 里 boot-args 缺失**，而 OpenCore 不会覆盖已存在的 boot-args：
  `OCVAR: Setting NVRAM 7C436110-…:boot-args - ignored, exists`。配置里写的全量参数实际没生效，内核在缺参数状态下启动。
- **解法**：进入系统后（或恢复环境）手动写入：
  ```
  sudo nvram boot-args="-v debug=0x100 keepsyms=1 nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0"
  ```
  （驱动会有自己的 nvrmsettle=10000，见 D 节。）

### C2. 进不去系统时的救援入口（OpenCore 菜单）
- `1401: Start once without NVIDIA driver`：**一次**不加载 NVIDIA 驱动进 macOS（驱动下次启动自动恢复）。
- `1401: Remove NVIDIA driver`：移除驱动并恢复安全显示设置。
- 恢复环境：`OCESP` 条目（BaseSystem）。

### C3. 核显（NootedRed）在 15.8.1 上不稳定
- **症状**：`/Library/Logs/DiagnosticReports/Kernel_*.gpuRestart` 大量生成（20+ 次），桌面黑屏只剩鼠标。
- **根因**：NootedRed 0.8.10 在 15.8.1 上的兼容性问题。
- **解法**：安装 NVIDIA 驱动并把显示输出切到 2080 Ti（之后核显仍可负责视频编解码）。

### C4. 驱动首次启动卡在 `NVRM BAR1`
- **症状**：verbose 停在 `NVRM-XNU: bar1: ... no 64-bit window in the host bridge's _CRS (not an Intel CPU)`，随后自动重启。
- **根因**：BIOS 里 **Above 4G Decoding 关闭**，驱动拿不到 4G 以上地址窗口。
- **解法**：BIOS 中 **Above 4G Decoding = Enabled**、**Re-Size BAR Support = Auto**，保存重启。

---

## D. NullMoth 驱动安装 / 升级 / 回退

### D1. 安装流程（首次 2.3.6）
1. 确认 macOS ≥ 15.5、csr 0x0A43、SecureBootModel Disabled；
2. 用 1401.app 资源里的 `nullmoth-setup.sh`，先 **`--dry`** 看会改什么；
3. 正式安装：`sudo nullmoth-setup.sh --pkg … --sha … --efi auto --tool … --profile … --knob NVK_CMDPOOL_GPU_UNCACHED=1 --knob NVK_SYSMEM_GPU_UNCACHED=1 --knob NVMTL_NO_NVENC=1 --knob NVMTL_NO_NVENC_HEVC=1`
4. 安装器会自动：备份现有配置 → 改 OpenCore（boot-args + `nvrmsettle=10000`、`Kernel > Block` 排除 `IONDRVSupport`、`NVRAM Delete` 加 boot-args）→ 添加救援工具项 → 装 kexts → 记录 `/Library/NullMoth/state`。
5. 重启生效；如 macOS 提示允许系统扩展，按提示允许。

### D2. 中国大陆下载驱动被墙
- **症状**：Mac 上 `curl https://github.com/...` 超时（HTTP 000）。
- **解法**：在服务器用镜像下载再 scp：
  ```
  curl -L -o nullmoth-nvidia-2.5.4.tar.gz "https://ghfast.top/https://github.com/nullmoth/nvidia-macos-driver/releases/download/v2.5.4/nullmoth-nvidia-2.5.4.tar.gz"
  sha256sum …   # 期望 648280bea54fa57809e3bf3b312bdb6709a00fa0292af3b37c665e111fe27eaa
  scp … user@192.168.1.155:/Users/user/1401-work/
  ```
  1401-Mac dmg 同理（sha256 `a4c00042b5180573a98e7ca730bfe78a440cb2bfce9cbfb9ba52654705b38766`）。

### D3. 2.5.4 升级后屏幕抽搐/闪烁 → 回退 2.3.6
- **现象**：画面内容不变但显示抖动/闪烁（用户描述"抽搐"）；与此前 2.3.6 的"卡顿"不同。
- **处理**：用旧版 `1401.app`（2.3.6）里的 `nullmoth-setup.sh` + `nullmoth-nvidia-2.3.6.tar.gz`（sha256 `3855954d9069eca470e4dbc7f645a63bba888040ec099285ef044ece03ad8e4f`）重新安装即回退，安装器会自动备份当前驱动（`/Library/NullMoth/backup-*`）。
- **同时清理**：`/etc/sysctl.conf` 里自定义的 `debug.nvrmfb_flip_latch=2`；恢复原始 boot-args。

### D4. 试 `nvfbheads=1` + 删 `-nvkmsnosmooth`（社区 #283）导致启动卡白字
- **症状**：改完参数后启动停在 verbose 白字界面，长时间不进展；上一次同样的机器是能进的。
- **根因**：该 workaround 只在 RTX 2070 + macOS 26 上验证过，**不适用于 2080 Ti + macOS 15.8.1**。
- **教训**：改启动参数前必须有回退路径（救援入口），且一次只改一个变量；本次通过 `1401: Start once without NVIDIA driver` 进系统后改回。
- **正确参数**：`nvfbheads=4` + `-nvkmsnosmooth`（保持原样）。

### D5. 不要用系统睡眠
- 驱动已知 issue（#353）：睡眠后 WindowServer 可能崩溃/黑屏。建议 `sudo pmset -a sleep 0`。

---

## E. 网络 / 访问

### E1. DNS / "网络慢"的真相
- 实测（macOS 内）：内网 0.9ms、0% 丢包；DNS 1~25ms；百度 62ms、苹果 71ms、Bing 243ms → 网络本身很快。
- 觉得"慢"主要是**界面渲染卡顿**（驱动）与 DSH 连接方式问题，不是带宽/DNS。
- 当前 DNS：路由器 `192.168.1.1` + `203.0.113.10`（也可加 203.0.113.10 / 203.0.113.10）。

### E2. DSH Web GUI 在别的设备打不开 / 一直"正在重新连接"
- DSH 只监听服务器本机 `127.0.0.1:19387`（仅本机可用）。
- 局域网入口：`http://192.168.1.223:19389/`（HTTP Basic，realm "DSH remote access"，用户名 `dsh`，密码见服务器 `/root/.dsh/remote-access/secret.json`）。
- 公网入口：frp 隧道（`https://example.com:…`，详见 `docs/05-NETWORK-AND-ACCESS.md`）。
- "正在重新连接"通常是隧道波动或页面渲染卡顿造成，刷新/等待即可；局域网入口最稳。

### E3. 服务器 `/tmp` 不跨 bash 调用持久
- 本项目脚本/安装包要在**单次命令内**用完，或写到持久位置；否则下一条命令就"文件不存在"。

---

## F. 驱动能力与预期（重要）

- 官方支持表（`docs/CARD-SUPPORT.md`）：Turing / Ampere / Ada 均为 **Pending（未完成物理验证）**；只有部分 Blackwell 卡有验证。
- 桌面卡顿的根因是 **Metal→Vulkan 翻译层**：拖窗口固定 ~18-20ms/帧（≈50fps），WindowServer 单核 100%+，与分辨率/刷新率/窗口大小无关（issue #352 / #356 / #370）。
- 社区已有补丁（#362 / #368：缓存 IOSurface 导入）实测把 WindowServer CPU 110%→45%、拖窗口 97→136fps，但尚未合并发布。
- 同卡（2080 Ti）成功案例 #61：1401 1.7.0 全新安装 + 驱动 1.7.0 + 纯默认参数 → 桌面正常、WindowServer 零崩溃；TU102 硬件 vblank 不 latch，驱动自动用定时器兜底。
- 视频硬编：**2.4.1 起**才支持 RTX 20/30 硬件编码；2.3.6 无 NVENC。
- 游戏：大部分 PC 游戏无 macOS 版；反作弊游戏无法运行；**游戏请用 Windows 双系统**。
- AI 加速：macOS 上 **没有 CUDA**（NVIDIA 早已停止 macOS CUDA 支持），NullMoth 是 Metal 驱动；CUDA/TensorRT/PyTorch-GPU 不可用，仅少数 Metal/CoreML 工具可能用到（未验证）。**AI 请用 Windows**。

---

## G. 当前最终状态（2026-10-24）

- 系统：macOS 15.8.1 (24H32) 正常启动、桌面可用、SSH 可用（`user@192.168.1.155`，sudo NOPASSWD）。
- 驱动：**2.3.6**（2.5.4 回退），4 个 kext 均加载，2080 Ti Metal 3，主显示器 2560×1440@165Hz。
- 已知遗留：窗口动画/拖窗口卡顿（等上游修复）；建议不睡眠。
- 后续：关注驱动新版本（2.5.5+），升级前先 `--dry`、备份，并按 `docs/04-DRIVER-UPDATE-RUNBOOK.md` 操作。

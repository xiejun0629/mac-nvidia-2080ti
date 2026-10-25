# mac-nvidia-2080ti

> **⚠️ 原作者与驱动来源（必读）**
> 本项目使用的是第三方开源项目 **NullMoth** 的 macOS NVIDIA 驱动，驱动作者与原始仓库：
> - 驱动源码/发布（原作者）：https://github.com/nullmoth/nvidia-macos-driver
> - 1401 工具（原作者）：https://github.com/nullmoth/1401
> - 官方站：https://nullmothsystems.com
>
> 本仓库仅为个人安装与踩坑记录，**不包含、不分发驱动二进制文件**；驱动版权与许可归原作者所有，与上游项目无隶属关系。如需使用请前往原作者仓库获取。

**macOS Sequoia 15.8.1 + NVIDIA GeForce RTX 2080 Ti（NullMoth 第三方驱动）在 BESSTAR B550 / Ryzen 7 5700G 上的完整搭建记录。**

> 状态（2026-10-24）：系统可用。显示输出已切到 2080 Ti（2560×1440@165Hz，Metal 3），
> 当前使用驱动 **2.3.6**（2.5.4 因屏幕抽搐/闪烁回退）。已知问题：窗口动画/拖窗口低帧（驱动层翻译开销，官方 open issue）。
> Windows 双系统保留，游戏/AI/CUDA 请在 Windows 侧使用。

> 本仓库为**公开脱敏版**：硬件序列号 / UUID / 内网地址 / 账号 / 域名均已替换；OpenCore 日志因含硬件标识未收录。

## 目录

| 路径 | 内容 |
|---|---|
| `docs/01-PITFALLS.md` | **踩坑全记录**（症状 → 根因 → 解法，按阶段整理） |
| `docs/02-ARCHITECTURE.md` | 硬件/磁盘/软件栈/启动链/远程通道架构 |
| `docs/03-RECOVERY-RUNBOOK.md` | 进不去 macOS 时的恢复手册（OCESP 恢复 + 反向 HTTP 通道） |
| `docs/04-DRIVER-UPDATE-RUNBOOK.md` | NullMoth 驱动安装/升级/回退流程（含大陆镜像下载） |
| `docs/05-NETWORK-AND-ACCESS.md` | 网络/DNS/DSH Web 访问/Gitea 说明 |
| `docs/06-GAMING-AI-EXPECTATIONS.md` | 这套 macOS 能干什么、游戏与 AI 加速的真实预期 |
| `scripts/recovery/` | 恢复环境反向通道（relay 服务端 + agent + ESP 脚本） |
| `scripts/macos/` | macOS 侧辅助脚本（bootstrap/diag/驱动下载/更新提醒） |
| `configs/` | OpenCore config 备份、boot-args、驱动安装记录 |
| `tools/push-to-github.sh` | 把本仓库镜像到 GitHub 的脚本 |

## 关键事实速查

- 机器：BESSTAR B550 / Ryzen 7 5700G（Cezanne iGPU 1002:1638）/ 32GB / RTX 2080 Ti（10DE:1E07）/ Intel I225-V
- macOS：15.8.1 (24H32)，用户 `user`，OpenCore 1.0.9，SMBIOS `iMacPro1,1`，`csr-active-config 0x0A43`
- 当前 boot-args：`-v debug=0x100 keepsyms=1 nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 nvrmsettle=10000`
- 驱动：NullMoth 2.3.6（kexts：NVRM / NVAccel / NVRMFB / NVRMAGDC），备份与状态在 macOS 的 `/Library/NullMoth/`
- 恢复环境：ESP 内的 BaseSystem（OCESP 条目，15.6.1 24G90）；`Recovery 15.8.1` 不可用（见踩坑 #6）
- 救援入口（OpenCore 菜单）：`1401: Start once without NVIDIA driver` / `1401: Remove NVIDIA driver`

## 相关上游

- 驱动源码/发布：https://github.com/nullmoth/nvidia-macos-driver
- 1401 工具：https://github.com/nullmoth/1401
- 官方站：https://nullmothsystems.com

## 快速开始（从零复现）

1. 阅读 `docs/01-PITFALLS.md`（所有踩过的坑与解法）；
2. 按 `docs/04-DRIVER-UPDATE-RUNBOOK.md` 安装/升级驱动（先 `--dry`，保留备份）；
3. 装完后按 `docs/03-RECOVERY-RUNBOOK.md` 准备恢复通道（恢复环境 relay agent）；
4. 网络/远程访问见 `docs/05-NETWORK-AND-ACCESS.md`，能力边界见 `docs/06-GAMING-AI-EXPECTATIONS.md`。

## 如何推送到 GitHub

```bash
# 在服务器上（或任意能访问 Gitea 的机器）：
git clone --mirror http://192.168.1.223:3066/user/mac-nvidia-2080ti.git repo.git
cd repo.git
git remote add github user@example.com:<你的用户名>/<仓库名>.git
git push --mirror github
```
或直接用 `tools/push-to-github.sh user@example.com:<user>/<repo>.git`。

> 注意：本仓库为 **private**；驱动安装包（200MB+ 的 tar.gz/dmg）不入库，
> 用 `scripts/macos/fetch-driver.sh <版本>` 从镜像重新下载并校验 SHA256。

## 仓库结构

```
configs/    OpenCore config 多版本备份（current / 回退前 / 试验前）、安装器备注
docs/       踩坑复盘、架构、恢复/升级手册、网络访问、能力预期
scripts/    recovery/（relay 服务端 + agent + ESP remote-on.sh）
            macos/（bootstrap/diag/驱动下载/系统升级脚本）
state/      当前机器状态快照（kexts/显示/boot-args）
tools/      SHA256 校验和、GitHub 镜像推送脚本
```

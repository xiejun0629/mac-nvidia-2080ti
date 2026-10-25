# 这套 macOS 能干什么：游戏 / AI / 生产力预期

## 1. 可用（当前状态）
- 办公（Office/WPS/飞书等）、网页浏览、微信/QQ
- 视频播放（硬解由核显 AMD UVD 承担，流畅）
- 图片处理、轻度剪辑（编码走核显 AMD VCE；**2.3.6 无 NVIDIA NVENC**）
- 显示：2080 Ti 输出，2560×1440@165Hz，Metal 3
- SSH/远程、终端开发等

## 2. 已知短板
- 窗口动画/Dock/拖窗口**低帧卡顿**（驱动 Metal→Vulkan 翻译开销，官方 open issue #352/#356/#370；社区补丁 #362/#368 未合并）
- 不建议系统睡眠（issue #353）
- 个别 Metal 应用兼容性未知

## 3. 游戏（不推荐在 macOS）
- 多数 PC 游戏无 macOS 版；有 Mac 版的也经翻译层，帧率显著低于 Windows
- 反作弊游戏（Apex/Valorant/PUBG 等）在 macOS/hackintosh 上**无法运行**
- **结论：游戏用 Windows 双系统**（2080 Ti 原生驱动，满性能）

## 4. AI 加速（macOS 侧很有限）
- **CUDA 不可用**：NVIDIA 已停止 macOS CUDA 支持；NullMoth 是 Metal 驱动，不是 CUDA
- 可用：仅 Metal/CoreML 路径（如 llama.cpp 的 Metal 后端，未验证；部分 Metal 推理程序可能可用）
- 不可用：CUDA / cuDNN / TensorRT / PyTorch-GPU 常规栈 / DLSS
- 视频硬编：2.4.1 起支持 RTX 20/30 硬件编码；当前 2.3.6 不支持
- **结论：AI 训练/推理请用 Windows（CUDA 生态）**

## 5. 建议分工
| 用途 | 平台 |
|---|---|
| 办公、上网、视频、轻创作 | macOS（当前状态可用） |
| 大型游戏 | Windows（双系统） |
| AI / CUDA / DLSS / 视频硬编导出 | Windows |
| Final Cut / Xcode 等 macOS 专属 | macOS（可用但非满速） |

## 6. 未来预期
- 官方在积极迭代（仓库创建 2026-10-07，发布极频繁：2.4→2.5.4 仅数天；Turing 在支持表中仍为 Pending）
- 社区补丁方向明确（WindowServer CPU 110%→45%、拖窗口 97→136fps 的实测数据）
- 等新版本发布后再评估升级（升级手册见 `docs/04-DRIVER-UPDATE-RUNBOOK.md`）

# CHANGELOG

## 2026-10-24
- macOS Sequoia 15.8.1 (24H32) 在 BESSTAR B550 + RTX 2080 Ti 上成功启动并可用。
- 关键修复：补全 NVRAM boot-args（OpenCore 不会覆盖已存在项）；BIOS 开启 Above 4G Decoding + Re-Size BAR（Auto）。
- 安装 NullMoth NVIDIA 驱动 2.3.6（4 个 kext，Metal 3，显示 2560×1440@165Hz）。
- 恢复通道：OCESP BaseSystem 15.6.1 + 反向 HTTP relay agent（caffeinate 防休眠）。
- 升级 2.5.4 试验：出现屏幕抽搐/闪烁后回退 2.3.6；删除 `flip_latch=2` 系统参数。
- 网络：DNS 设为路由器 + AliDNS；确认 DSH 局域网入口 192.168.1.223:19389（Basic auth）。
- 文档与脚本整理并入库（本仓库）。

## 历史（2026-10-23 及之前，摘要）
- Windows 侧 1401 工具制作安装 U 盘、备份 ESP、准备 macOS 15.8.1 安装介质。
- OpenCore 重建（1.0.9 + iMacPro1,1 + 13 kexts），解决 config 解析失败、SimpleMtkBtFw 卡死、AppleIGC 版本兼容。
- 多次尝试进入安装/恢复；确认 `Recovery 15.8.1` 因 OS.dmg.root_hash Err(0xE) 不可用（上游 AMD 平台已知问题）。

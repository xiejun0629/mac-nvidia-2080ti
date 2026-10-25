# 恢复手册：进不去 macOS 时怎么办

## 0. 前提
- 恢复环境只有 **OCESP（ESP 内 BaseSystem 15.6.1）可用**；`Recovery 15.8.1` 不可引导（见踩坑 B1）。
- 恢复环境是只读系统、**没有 sshd**，远程操作靠"反向 HTTP 轮询 agent"（见第 3 节）。

## 1. 第一步：进 OpenCore
1. 长按电源键 10 秒强制关机；
2. 开机**连按 F7** → 选 **UEFI OS**；
3. 进入 OpenCore 菜单。

## 2. 菜单选择速查

| 目的 | 选择 |
|---|---|
| 正常进 macOS | `apple` |
| 驱动疑似出问题（想先不加载驱动进系统） | `1401: Start once without NVIDIA driver` → 按 `Y` → 再选 `apple` |
| 驱动彻底移除（恢复安全显示） | `1401: Remove NVIDIA driver` → 按 `Y` → 等它重启 |
| 进恢复环境修东西 | `OCESP` |
| 进 Windows | `Windows` |

> `1401: Start once...` 是"只这一次不加载驱动"，下次启动自动恢复。
> 如果 `apple` 卡住/黑屏超过 3 分钟：强制关机，改用 `1401: Start once...` 或 `OCESP`。

## 3. 恢复环境 + 远程通道（relay agent）

### 3.1 启动 relay（服务器侧）
```bash
# 在服务器 192.168.1.223 上
python3 /path/to/relay-server.py    # 监听 203.0.113.10:18199，需后台常驻
curl -s http://127.0.0.1:18199/ping # 应返回 pong
```

### 3.2 在 macOS 恢复环境里启动 agent（用户侧，一行命令）
恢复界面 → 实用工具 → 终端：
```bash
curl -s http://192.168.1.223:18199/a.sh | sh
```
看到 `AGENT-UP3 … caffeinate-started` 即成功；agent 会：
- 用 `caffeinate -dimsu` 阻止休眠（恢复环境默认会睡，睡了就掉线）；
- 每 2 秒轮询服务器取命令并回传输出；
- 每条命令 150 秒看门狗、输出截断 48KB。

### 3.3 服务器侧下发命令
```bash
B=http://127.0.0.1:18199
id=$(curl -s --get --data-urlencode "c=sw_vers; diskutil list" $B/add)
# 轮询结果
curl -s "$B/res?i=$id"     # "__PENDING__" 表示还没执行完
```
接口：`/ping`、`/add?c=<urlencoded>`、`/get`（agent 内部用）、`/put?i=`（agent 回传）、`/res?i=`、`/state`、`/clear`。

## 4. 恢复环境常用操作

### 4.1 挂载 ESP（编辑 config / 取日志）
```bash
kmutil load -p /System/Library/Extensions/msdosfs.kext
fsck_msdos -f -y /dev/rdisk2s3
mkdir -p /Volumes/OCESP2 && mount -t msdos /dev/disk2s3 /Volumes/OCESP2
ls /Volumes/OCESP2/EFI/OC/config.plist
```
> 磁盘编号会变，先 `diskutil list | grep -i "EFI OCESP"` 确认。

### 4.2 修改 boot-args（修改前先备份）
```bash
PB=/usr/libexec/PlistBuddy
C=/Volumes/OCESP2/EFI/OC/config.plist
cp "$C" "/Users/user/1401-work/config.plist.bak-$(date +%s)"   # 若数据卷已挂载
G=<REDACTED_UUID>
$PB -c "Print :NVRAM:Add:$G:boot-args" "$C"
$PB -c "Set :NVRAM:Add:$G:boot-args -v debug=0x100 keepsyms=1 nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 nvrmsettle=10000" "$C"
nvram boot-args="…同一串…"
```
改完 `plutil -lint "$C"` 校验，再重启。

### 4.3 看 OpenCore 日志
```bash
ls -t /Volumes/OCESP2/opencore-*.txt | head
grep -a "Should boot from" /Volumes/OCESP2/opencore-*.txt | tail -5
grep -a "EXITBS\|Err(0xE)\|OCVAR" /Volumes/OCESP2/opencore-*.txt | tail -20
```

### 4.4 修复/重装驱动（在恢复环境里不建议，优先进系统用 1401 安装器）
救援优先级：`1401: Remove NVIDIA driver` > 重装驱动 > 手动改 kexts。

## 5. 最后手段
- 进 Windows（OC 菜单 `Windows`），把 `S:\EFI\OC` 修复/备份（Windows 下 ESP 为 S: 盘）；
- 用 1401 U 盘/工具重新制作引导并重装驱动；
- 数据卷（`apple - Data`）在恢复环境可挂载：`diskutil mount disk4s1`，重要数据先备份。

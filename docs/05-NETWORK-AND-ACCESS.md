# 网络、DNS 与远程访问

## 1. 局域网
- 服务器（本机）：`192.168.1.223`（另 Tailscale `100.64.0.10`）
- macOS 主机：`192.168.1.155`（DHCP，`en0`，Intel I225-V）
- Windows：`192.168.1.155`（Windows 开机时；与 macOS 共用 DHCP 地址）
- 网关：`192.168.1.1`；NAS：`192.168.1.164`
- macOS DNS：`192.168.1.1`（路由器/运营商）+ `203.0.113.10`；可选 `203.0.113.10`、`203.0.113.10`
- 实测（macOS 内）：内网 0.9ms/0% 丢包；DNS 1~25ms；百度 62ms、苹果 71ms、Bing 243ms

## 2. DSH Web GUI（当前对话界面）
- 本机监听：`127.0.0.1:19387`（**只绑本机**，外部设备不能直连）
- 局域网入口：`http://192.168.1.223:19389/`
  - HTTP Basic 认证（realm: "DSH remote access"），用户名 **`dsh`**
  - 密码在服务器 `/root/.dsh/remote-access/secret.json`（**不要外传**）
  - 该入口由 `frp-auth-proxy-lan.mjs` 提供：改写 Host/Origin + 注入会话 Cookie
- 公网入口：frp 隧道（樱花内网穿透），配置在服务器 `/root/.dsh/remote-access/`
  - 例：`https://example.com:36491`（以实际配置为准）
  - 代理链路：手机 → frp 服务器 → frpc → frp-auth-proxy → 127.0.0.1:19387
- 浏览器"一直正在重新连接"：多为隧道波动/页面渲染卡顿；刷新或改用局域网入口。

## 3. Gitea（本仓库所在）
- Docker 容器 `gitea`，宿主端口 **3066**（容器 3000）；域名 `example.com`
- 数据：宿主 `/opt/gitea/data`（容器 `/data`）；SQLite `/data/gitea/gitea.db`；仓库根 `/data/git/repositories`
- 用户：`user`（管理员）
- 本仓库：`http://192.168.1.223:3066/user/mac-nvidia-2080ti`
- 管理命令示例：
  ```bash
  docker exec -u git gitea gitea admin user list
  docker exec -u git gitea gitea admin user generate-access-token -u user -t token-name --scopes all --raw
  ```

## 4. 恢复环境 relay 通道
- 端口：服务器 `:18199`（仅在运行 relay 时）
- agent 一行命令：`curl -s http://192.168.1.223:18199/a.sh | sh`
- 接口：`/ping /add /get /put /res /state /clear`
- 说明：恢复环境只读、无 sshd；agent 必须带 `caffeinate`，否则恢复环境休眠后掉线。

## 5. 其它
- 服务器 `/tmp` **不跨 bash 调用持久**：脚本/安装包需在单次命令内完成，或落到持久目录。
- 中国大陆 GitHub 直连不稳：优先用镜像（`ghfast.top`、`gh-proxy.com`）下载并校验 SHA256。
- Windows 主机 SSH：`Administrator@192.168.1.155`（OpenSSH server，PowerShell `-EncodedCommand`）。

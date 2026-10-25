# 提交前需要准备的日志与脱敏

## 需要附上的材料
1. **1401 "Send logs" 生成的 report ID**（最优先，官方就认这个）
2. OpenCore DEBUG 日志：ESP 里的 `opencore-*.txt`（至少一次正常启动 + 一次 2.5.4 异常启动）
3. `/Library/NullMoth/state`、`driver-version`、`bootguard.log`
4. `/Library/Logs/DiagnosticReports/` 中相关 `gpuRestart`/`panic`（若有）
5. 实测数据表：refresh rate × resolution × 操作类型 的定性与定量结果
6. `system_profiler SPDisplaysDataType`、`kmutil showloaded | grep -i nullmoth`、`nvram boot-args`

## 脱敏
- 删除序列号/机器名：`system_profiler SPHardwareDataType` 的 Serial、Hardware UUID
- OpenCore 日志里若含 MAC 地址/序列号，先 `sed` 替换
- 不要上传 `/Library/NullMoth/backup-*`（包含完整驱动包，体积大）
- 日志打包后附 SHA256 便于核对

# 证据包（原始数据）

本目录内容为**实测数据与命令输出**，不是成文报告。用于配合机主本人撰写的 issue。

优先级最高的日志：**1401.app → Send logs 生成的 report ID（NM-XXXX）**——上游模板必填项；
其余材料作为补充附件/引用。

| 文件 | 说明 |
|---|---|
| environment.md | 环境清单（硬件/OS/驱动/boot-args/BIOS） |
| measurements.md | 实测数据与对比（2.3.6 vs 2.5.4；刷新率/分辨率；WindowServer CPU） |
| repro-steps.md | 复现步骤（含命令） |
| facts-for-issue-fields.md | 按 issue 表单字段列出的可填事实 |
| timeline.csv | 事件时间线 |
| commands.txt | 命令清单（可直接复跑） |
| screenshots-needed.md | 建议附带的照片/截图 |
| _reference-drafts-do-not-submit/ | 旧 AI 草稿，仅参考 |

相关日志文件在本仓库 `logs/`（OpenCore DEBUG 日志、startosinstall 日志）；
`state/current-state.txt` 是采集时的 kexts/显示/boot-args 快照。

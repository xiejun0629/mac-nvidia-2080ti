# 给上游的贡献材料

## ⚠️ 上游规则（必读）
`nullmoth/nvidia-macos-driver` 的 CONTRIBUTING 明确：

> Pull requests, issues and review comments must be written by a person who understands them.
> AI-written code, descriptions and bug reports are closed without review.

因此本目录**只放"证据/数据"**（日志、命令输出、测量数字、环境清单、复现步骤），
供机主**本人撰写** issue / 评论 / PR 时引用。请勿把 AI 生成的整段描述直接提交。

## 目录
- `evidence/` —— **原始证据包**（数据，可直接引用/附件）
  - `environment.md` —— 硬件/系统/驱动/boot-args/BIOS 设置清单
  - `measurements.md` —— 实测数据（刷新率/分辨率/CPU 占用等）
  - `repro-steps.md` —— 精确复现步骤（含命令）
  - `facts-for-issue-fields.md` —— 按上游 issue 模板字段整理的"可填事实"清单
  - `timeline.csv` —— 时间线
  - `commands.txt` —— 所有用到的命令
  - `screenshots-needed.md` —— 建议补拍/附上的截图
  - `_reference-drafts-do-not-submit/` —— 之前的 AI 草稿（**仅供参考，不要原样提交**）

# 按上游 issue 模板字段整理的可填事实（供机主本人撰写）

> 上游规则：描述必须由本人用自己的话写。以下只是"可引用事实"，不是成文段落。

## Send logs report ID
`<待机主在 macOS 上打开 1401.app → Send logs 获取，格式 NM-XXXX>`

## Where does it go wrong?
- On the desktop (flicker, lag, displays, sleep)

## What happens（事实清单，按需挑选引用）
- Driver 2.3.6: desktop OK (Metal 3, 2560×1440@165Hz main display); window drag / Dock / Mission Control stutter.
- Driver 2.5.4: desktop OK but periodic display flicker with unchanged content; reverted to 2.3.6.
- Idle WindowServer ~0–2% CPU; during drag/animation ~105–123% of one core.
- Cursor smooth; window content animations low fps.
- No kernel panics; `/Library/Logs/DiagnosticReports/*.panic` empty.
- Refresh 165/120/60 Hz, resolution 1440p/1080p, flip_latch 1/2: no change.
- `nvfbheads=1` + removing `-nvkmsnosmooth` (reported in #283 for another card): hangs at verbose boot here.

## 机器信息（照抄 environment.md）
见本目录 `environment.md`。

## 附件建议
- 1401 report ID（首选）
- OpenCore DEBUG 日志（本仓库 logs/ 中已有）
- `system_profiler SPDisplaysDataType`
- `kmutil showloaded | grep -i nullmoth`
- `nvram boot-args`
- verbose 启动照片（若涉及启动失败）

## 参考的同类 issue
#61（2080 Ti vblank）、#352（Dock/视频 stutter）、#356（拖窗口固定帧耗时）、#370（WindowServer 着色器翻译）、#368/#362（IOSurface 缓存补丁）

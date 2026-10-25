# 给现有 issue 的评论草稿（供机主核对后提交）

## To #370 (RTX 2070 SUPER, macOS 15.8.1, WindowServer shader translation)
Same OS build here (15.8.1 24H32), RTX 2080 Ti (TU102) / Ryzen 7 5700G (Cezanne):
- Idle WindowServer CPU 0–2%; during window drag / Mission Control it reaches 105–123% of one core.
- Cursor remains smooth; window content animations are low-fps → consistent with compositor-side cost, not GPU saturation.
- `flip_latch` 1/2 and refresh/resolution changes made no difference.
- Interestingly `nvfbheads=1` + `-nvkmsnosmooth` (fix from #283) made this machine hang at verbose boot; reverted.
Can provide verbose boot photos / OpenCore logs if useful.

## To #356 (window drag ~50 fps fixed cost on 165 Hz)
Similar fixed-cost observation on 2080 Ti / 15.8.1 / 165 Hz: drag stutter is independent of window size/resolution/refresh; WindowServer pegged at ~100%+ of one core. Looks like the same Metal→Vulkan per-frame overhead class as #370.

## To #61 (RTX 2080 Ti, Turing vblank never latches)
Another 2080 Ti (10DE:1E07) data point on macOS 15.8.1 (B550 + 5700G, iGPU present but display on 2080 Ti):
- Driver 2.3.6: desktop comes up, Metal 3, 2560×1440@165Hz main display; no `nvhwvbl`/`-nvrmnoflip` needed on our config.
- Driver 2.5.4: desktop works but display flickers; reverted to 2.3.6.
- Can attach OpenCore logs + `/Library/NullMoth` state if maintainer wants more Turing units.

## To #368 / #362 (IOSurface import caching patches)
Your measurements match ours (WindowServer heavily loaded in CA→Metal→Vulkan path; drag fps far below panel rate). If a build with the patch is available for testing on Turing (RTX 2080 Ti), happy to run a before/after test matrix (165/120/60 Hz; drag / Mission Control / Dock) and report numbers.

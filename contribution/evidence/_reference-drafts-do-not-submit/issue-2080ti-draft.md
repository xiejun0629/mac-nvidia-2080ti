# [Draft] Issue: RTX 2080 Ti (TU102) on macOS 15.8.1 / AMD Cezanne — desktop works on 2.3.6, UI stutter persists; 2.5.4 shows display flicker

> 提交前请机主：① 按 1401 的 "Send logs" 生成 report ID 并填入第一行；
> ② 用自己的话核对/改写以下内容；③ 确认环境数据无误。上游规则：AI 代写 issue 会被直接关闭。

## Send logs report ID
`<在此填 1401 "Send logs" 生成的 report ID>`

## Where does it go wrong?
On the desktop (flicker, lag, displays, sleep)

## What happens
- **Driver 2.3.6**: desktop comes up correctly on RTX 2080 Ti (Metal 3, 2560×1440@165Hz main display). UI interactions stutter: dragging windows, Dock magnification, Mission Control, app switching. Cursor stays smooth (hardware cursor plane).
- **Driver 2.5.4**: after upgrade the same desktop works, but the display shows visible flicker/twitch ("抽搐") without content changes; rolled back to 2.3.6.
- No kernel panics on either version; `/Library/Logs/DiagnosticReports/*.panic` empty. WindowServer CPU spikes to ~105–123% of one core during window drags (idle ~0–2%).

## Tested configurations
- Refresh rates 165 / 120 / 60 Hz: stutter unchanged.
- Resolution 2560×1440 / 1920×1080: stutter unchanged.
- `debug.nvrmfb_flip_latch=1` vs `2`: no change.
- Boot-args `nvfbheads=1` + removed `-nvkmsnosmooth` (workaround from #283): **did not boot** — verbose boot hung; reverted to `nvfbheads=4 -nvkmsnosmooth` (this workaround apparently does not apply to this config).
- `Reduce Transparency` + `Reduce Motion`: no visible improvement in frame pacing.

## Environment
- Machine: BESSTAR B550, AMD Ryzen 7 5700G (Cezanne APU with iGPU, `1002:1638`), 32 GB DDR4-3200
- GPU: NVIDIA GeForce RTX 2080 Ti, `10DE:1E07`, TU102, 11 GB (Turing)
- NIC: Intel I225-V; BIOS: Secure Boot off, CSM off, **Above 4G Decoding enabled, Re-Size BAR = Auto**
- macOS 15.8.1 (24H32); SMBIOS `iMacPro1,1`; OpenCore 1.0.9; `csr-active-config = 0x0A43`; `SecureBootModel = Disabled`
- Kexts (OC): Lilu 1.7.3, NootedRed 0.8.10 (iGPU loaded but display is on dGPU), AMFIPass 1.4.1, AppleIGC 1.7d3, VirtualSMC 1.3.9, AppleMCEReporterDisabler, CtlnaAHCIPort, NVMeFix, RestrictEvents, USBToolBox/UTBDefault; BlueToolFixup/SimpleMtkBtFw disabled
- Boot-args (2.3.6): `-v debug=0x100 keepsyms=1 nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 nvrmsettle=10000`
- Display: DP → 2080 Ti, 2560×1440 @165Hz
- Per-system knobs: `NVK_CMDPOOL_GPU_UNCACHED=1`, `NVK_SYSMEM_GPU_UNCACHED=1`, `NVMTL_NO_NVENC=1`, `NVMTL_NO_NVENC_HEVC=1`

## Remarks / related issues
- Same class of stutter reported on other GPUs: #352 (RTX 4080), #356 (RTX 3060 Laptop, ~18–20 ms/frame fixed on 165 Hz), #370 (RTX 2070 SUPER on macOS 15.8.1; WindowServer spends time translating Core Animation shaders via metal2vulkan), #368/#362 (community patches: caching IOSurface imports → WindowServer CPU 110%→45%, drag 97→136 fps).
- Another RTX 2080 Ti report: #61 (display bring-up; Turing hardware vblank never latches, driver falls back to timer VBL). Our machine reaches desktop on 2.3.6 with default args.

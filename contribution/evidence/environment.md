# 环境清单（实测）

## 硬件
| 项 | 值 |
|---|---|
| 主板 | BESSTAR B550（AMI BIOS 5.17，2022-03-31） |
| CPU | AMD Ryzen 7 5700G（Cezanne，8C16T，iGPU 1002:1638） |
| 内存 | 32 GB DDR4-3200 |
| GPU | NVIDIA GeForce RTX 2080 Ti，PCI ID 10DE:1E07，TU102，11 GB |
| 网卡 | Intel I225-V（00:11:22:33:44:55，en0） |
| 显示器 | AOC Q24G2，DP 接 2080 Ti，2560×1440 @165Hz |

## BIOS 设置
- Secure Boot: Disabled
- CSM: Off
- **Above 4G Decoding: Enabled**（原为 Disabled；不开启时驱动在 NVRM BAR1 处卡死/重启）
- **Re-Size BAR Support: Auto**
- 启动方式：F7 → `UEFI OS` → OpenCore 菜单

## 软件
- macOS 15.8.1 (24H32)，SMBIOS `iMacPro1,1`，`csr-active-config = 0x0A43`，`SecureBootModel = Disabled`
- OpenCore 1.0.9（ESP 标签 OCESP，1.1 GB）
- Kexts（OC 注入）：Lilu 1.7.3、NootedRed 0.8.10（iGPU，已加载但不承担显示）、AMFIPass 1.4.1、AppleIGC 1.7d3、VirtualSMC 1.3.9、AppleMCEReporterDisabler、CtlnaAHCIPort、NVMeFix、RestrictEvents、USBToolBox、UTBDefault；BlueToolFixup / SimpleMtkBtFw 已禁用

## 驱动
| 版本 | 状态 |
|---|---|
| NullMoth 2.3.6 | 可用；桌面正常、Metal 3、主显示 2560×1440@165Hz；UI 交互卡顿 |
| NullMoth 2.5.4 | 桌面正常，但出现屏幕闪烁/抖动（内容不变时也抖）；已回退 2.3.6 |

- kexts：NVRM / NVAccel / NVRMFB / NVRMAGDC（`/Library/Extensions`，版本随驱动包）
- 状态/备份目录：`/Library/NullMoth/`
- per-system knobs：NVK_CMDPOOL_GPU_UNCACHED=1、NVK_SYSMEM_GPU_UNCACHED=1、NVMTL_NO_NVENC=1、NVMTL_NO_NVENC_HEVC=1

## boot-args（当前，2.3.6）
```
-v debug=0x100 keepsyms=1 nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 nvrmsettle=10000
```

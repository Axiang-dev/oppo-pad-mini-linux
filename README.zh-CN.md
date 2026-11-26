# OPPO Pad Mini 原生 Linux 移植

**OPD2515 / SM8845P / Molokai 原生 ARM64 Linux 点亮项目**

[English](README.md) | 简体中文

这是一个非官方社区研究项目，与 OPPO、Qualcomm、Armada OS、ROCKNIX 或其他被引用的上游项目没有隶属、背书或官方支持关系。

## 项目概览

本仓库保存 OPPO Pad Mini OPD2515 原生 ARM64 Linux 移植的可复现源码边界、诊断补丁、内核配置、显示实验工具和硬件状态记录。项目仍处在早期开发阶段，没有可安装给普通用户的系统镜像。

当前可确认的最远节点是：打补丁的主线诊断内核进入 RAM-only initramfs，提供 USB ACM 控制台；固件开机画面可见；原生蓝、红测试帧在 DPU INTF 产生不同 CRC；原生接管后 XN254 内屏变黑。EXP-057 用于读取 DSI command MDP0，只完成构建，尚未进行实机测试。

编译成功、DRM card 出现、帧计数增长或模块加载都不是内屏点亮的证据。GPU、触控、Wi-Fi、蓝牙、音频、充电和休眠也尚未达到可发布状态。

## 支持的设备

| 设备 | 状态 | 已测试软件 | 说明 |
|---|---|---|---|
| OPPO Pad Mini OPD2515 | 实验性 | ColorOS 16，16.0.10.500 CN01 | 一台已记录硬件配置到达 RAM-initramfs 诊断节点 |
| OPPO Pad Mini OPD2516 或其他变体 | 不支持 | 无 | 没有运行时证据，不应在其他型号上使用 |

## 当前状态

| 子系统 | 状态 | 证据边界 |
|---|---|---|
| Bootloader 与可逆测试分区 | Working | 已在测试设备上完成 Fastboot、`boot_b` 写入、重启和恢复 |
| Linux ARM64 启动 | Partial | 已进入 RAM initramfs 和 USB ACM shell，尚无持久发行版启动 |
| 内置显示 | Broken | 固件 splash 可见，原生接管后黑屏 |
| DPU | Partial | LM/INTF CRC 能区分原生蓝、红帧 |
| MIPI DSI / DSC | Partial | 控制器配置合理，尚未证明数据到达面板 |
| 触摸屏 | WIP | GT9966 已在厂商数据中识别，主线上路未验证 |
| Adreno GPU | Blocked | 选定主线的 GPU catalog/GMU 固件路径不完整 |
| OpenGL / Vulkan | Blocked | 依赖 GPU 点亮 |
| USB device console | Partial | ACM 可用，Host 模式和手柄未验证 |
| Wi-Fi / Bluetooth | Not Tested | 尚无主线连接结果 |
| 音频 | Not Tested | 尚无端到端播放和录音结果 |
| 电池、充电、温控 | Not Tested | 厂商保护和电源管理尚未替换验证 |
| 休眠与唤醒 | Not Tested | 尚无重复休眠循环 |
| Armada OS、桌面、Steam | Blocked | 设备尚未进入可用 Linux 用户会话 |

完整状态矩阵和升级规则见 [docs/status.md](docs/status.md)。

## 硬件摘要

| 部件 | 已观察目标 |
|---|---|
| SoC | Qualcomm SM8845P，厂商平台名 `canoe`，上游家族 Molokai |
| GPU | Adreno 829，厂商 generation 8.9.0 |
| 存储 | Qualcomm UFS host |
| 显示 | 1680 x 2520 command-mode MIPI DSI，XN254 面板 |
| DPU / DSI | SDE/DPU D10，DSI v2.10，PHY v7.2，四 lane |
| DSC | DSC 1.2，8 bpp，每行两个 840 x 24 slice |
| 触摸 | 厂商数据中的 Goodix GT9966 |
| 无线 | 厂商数据中的 WCN7750 家族集成 |
| 音频 | 厂商数据中的两颗 TFA98xx 放大器 |

## 已知问题

- XN254 内屏在固件 splash 交接后仍黑屏。
- DPU 帧 CRC 只证明图像到达 DPU 接口采样点，不证明 DSI 传输或面板发光。
- 当前测试镜像需要开发者自行取得原厂 `boot_b` 作为打包外壳，仓库不发布刷机镜像。
- 本机验证过的 `boot_b` 路径不能直接外推到另一台设备。
- GPU、触控、无线、音频、电源管理和休眠均未完成。
- Armada OS、Gamescope、FEX、Proton、DXVK、VKD3D-Proton 尚无可用设备节点。

## 构建入口

内核基线固定为 Linux commit `6a876df4686788cd39128b62d7fcbff62f39278f`。

```sh
./scripts/setup.sh
./scripts/fetch-sources.sh
./scripts/build-kernel.sh
```

本地还持有合法原厂 `boot_b` 时，可以调用打包脚本：

```sh
./scripts/build-image.sh \
  --stock /path/to/stock-boot_b.img \
  --kernel artifacts/Image \
  --dtb artifacts/molokai-oppo-opd2515-diag.dtb
```

构建前阅读 [docs/building.md](docs/building.md)，设备测试前阅读 [docs/installation.md](docs/installation.md) 和 [docs/recovery.md](docs/recovery.md)。

## 安装与恢复

仓库当前不提供普通用户安装流程。开发测试要求：原厂 `boot_b` 已备份并校验、实体键进入标准 Fastboot 的路径已验证、每次分区写入均获得明确授权。测试前必须知道串口或 USB 完全丢失时如何进入 Fastboot。

## 路线图

1. 完成 DPU INTF 之后的 DSI command、DSC、lane/PHY 和 XN254 可见输出验证。
2. 完成亮度、熄屏/亮屏、电源时序和冷启动回归。
3. 建立最小持久 ARM64 userspace 和触摸输入。
4. 通过已审查的主线接口启用 Adreno GPU、OpenGL 和 Vulkan。
5. 完成 Wi-Fi、蓝牙、音频、USB Host、电池、充电、温控和休眠。
6. 在硬件基础稳定后接入 Armada OS、Steam Game Mode、Gamescope、FEX 和 Proton。

## 贡献与许可

实验必须区分实机事实、已排除项、源码推测和未验证假设，一次只改变一个行为变量。原始日志、照片、固件和备份保留在仓库外，公开报告必须去除设备唯一标识。

原始仓库代码默认使用 GPL-2.0-only，内核派生代码保留其上游许可证和版权。详见 [LICENSE](LICENSE)、[NOTICE](NOTICE)、[CONTRIBUTING.md](CONTRIBUTING.md) 和 [docs/sources.md](docs/sources.md)。

## 风险提示

写入实验镜像可能导致设备无法启动、数据损坏或暂时无法恢复。本项目不保证另一台 OPD2515 具有相同启动链、面板、固件或分区布局，也不提供生产级刷机或恢复保证。

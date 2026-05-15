# Matter 接入方案：RK3308 家庭背景音乐播放器

本文档是设备本体接入 Matter 生态的架构决策与实施计划。Control4 侧驱动是另一条线，本文档不涉及。

## 背景与约束

| 项 | 现状 |
|---|---|
| SoC | RK3308（Cortex-A35 四核 / Linux） |
| 系统 | Rockchip 原厂 SDK（Buildroot 风格） |
| 联网 | **仅以太网**，AP6256 模组只用 BT 部分 |
| BT 栈 | 博通 **BSA**（Broadcom Smart Audio），不是 BlueZ |
| BSA 用途 | (1) 本可做 A2DP Sink 但流媒体已由 shairport-sync (AirPlay 2) 承担；(2) 承载自家 App 的 BLE GATT 配网/控制 |
| 流媒体 | shairport-sync 实现 AirPlay 2（已使用系统 Avahi） |
| 硬件改动 | 不允许 |
| BT 栈替换 | 不允许（BSA 必须保留） |

**核心洞察**：设备永远有线在网，Matter 的 BLE Commissioning 在协议层是可选的——BLE 本质是给 Wi-Fi/Thread 传凭据用的。Ethernet-only 设备走 On-Network Commissioning 即可，BSA 不必动。

## AirPlay 2 vs Matter 的职责划分

| 维度 | AirPlay 2（已实现） | Matter（本计划） |
|---|---|---|
| 协议归属 | Apple 私有 | CSA 联盟标准 |
| 数据/控制面 | 数据面（音频推流） | 控制面（开关、音量、播放、源切换、自动化） |
| 传媒体 | 是 | 否 |
| 跨生态 | 仅 Apple | Apple / Google / Amazon / 米家 / SmartThings |
| 多房间同步播放 | 原生支持 | 不涉及 |
| 自动化 | 受限 | 强（cluster attribute 触发） |

**做 Matter 的真正价值**：打开非 Apple 生态 + Apple Home 内自动化 + CSA 认证 logo。

## 推荐方案：Matter over Ethernet + On-Network Commissioning（无 BLE）

### 架构一句话

RK3308 上跑一个独立的 `chip-audio-player` 进程，链接 connectedhomeip SDK 的 Linux 平台层但**禁用 BLE / Wi-Fi / Thread**，仅启用 Ethernet。Matter 节点通过既有 Avahi 实例对外广播 `_matterc._udp`（配对期）和 `_matter._tcp`（运行期）。BSA / shairport-sync / 自家 App 全部不动。

### 1. connectedhomeip SDK 集成

SDK 引入方式：作为 git submodule 放在 `third_party/connectedhomeip/`，pin 到 v1.3 release tag（或更新的稳定 tag）。

构建配置（gn args）：

```
chip_config_network_layer_ble = false
chip_enable_ble               = false
chip_enable_wifi              = false
chip_enable_openthread        = false
chip_enable_ethernet          = true
chip_mdns                     = "platform"   # 走系统 Avahi
chip_device_platform          = "linux"
treat_warnings_as_errors      = false        # RK 工具链兼容
```

工程级宏（在自己的 `CHIPProjectConfig.h` 中覆盖）：

- `CHIP_DEVICE_CONFIG_ENABLE_CHIPOBLE = 0`
- `CHIP_DEVICE_CONFIG_ENABLE_WPA = 0`
- `CHIP_DEVICE_CONFIG_ENABLE_THREAD = 0`
- `CHIP_DEVICE_CONFIG_ENABLE_ETHERNET = 1`

交叉编译：用 RK3308 SDK 的 gcc-aarch64 toolchain，通过 gn 的 `target_cpu="arm64"` + `custom_toolchain` 指过去。

### 2. 设备数据模型（ZAP）

参考 `examples/lighting-app/linux/` 骨架，新建 `app/matter/audio-player.zap`：

```
Endpoint 0  Root Node
  ├─ Basic Information
  ├─ General Commissioning
  ├─ Network Commissioning  (Feature: EN — Ethernet only)
  ├─ Operational Credentials
  ├─ General Diagnostics / Ethernet Network Diagnostics
  ├─ OTA Requestor
  └─ Time Synchronization

Endpoint 1  Speaker (Device Type 0x0022)
  ├─ Identify
  ├─ OnOff                 → 播放/静音
  ├─ Level Control         → 音量 (0–254)
  ├─ Media Playback        → Play/Pause/Stop/Next/Previous/Seek
  ├─ Media Input           → AirPlay / 本地 / USB / 网络电台
  └─ Content Launcher      (可选)
```

Network Commissioning Cluster 必须实例化为 Ethernet 变体（feature map = `EN`，即 `kEthernetNetworkInterface`），底层复用 SDK 已实现的 `LinuxEthernetDriver`，无需自写驱动。

### 3. 目标目录结构（待 SDK 引入时创建）

```
MiYueControl4Driver/
├── third_party/
│   └── connectedhomeip/                 submodule, pin v1.3
├── app/matter/
│   ├── BUILD.gn
│   ├── main.cpp                         chip::Server::Init + 业务桥接入口
│   ├── audio-player.zap                 ZAP 数据模型
│   ├── audio-player.matter              由 ZAP 生成
│   ├── CHIPProjectConfig.h
│   ├── bridge/                          Matter Cluster ↔ 业务逻辑桥接
│   │   ├── OnOffBridge.cpp
│   │   ├── LevelControlBridge.cpp       → ALSA mixer
│   │   ├── MediaPlaybackBridge.cpp      → 播放引擎 IPC
│   │   └── MediaInputBridge.cpp         → 音源切换
│   └── factory/
│       ├── factory_data_provider.cpp    读 DAC/PAI/CD/discriminator
│       └── README.md                    出厂烧录流程
├── system/
│   ├── avahi/                           与 shairport-sync 共用 Avahi
│   └── systemd/
│       └── chip-audio-player.service
└── factory-tools/
    ├── gen_pase_verifier.sh
    └── burn_factory.sh
```

### 4. 业务桥接层

| Matter Cluster | 回调 | 桥接到 |
|---|---|---|
| OnOff | `OnOffServer::setOnOff` | ALSA mute / 业务进程 IPC |
| Level Control | `LevelControlServer::moveToLevel` | ALSA `Master` mixer（与 shairport-sync 共用） |
| Media Playback | `Play/Pause/Stop/Next/Previous/Seek` | 播放引擎 IPC（D-Bus 或 Unix socket） |
| Media Input | `SelectInput` | 切换音源（AirPlay/Local/USB） |

状态主动上报：业务侧状态变化（如 AirPlay 来流自动切到 AirPlay 输入）需调 `MatterReportingAttributeChangeCallback()` 触发订阅推送。

### 5. mDNS 共存（与 shairport-sync）

- shairport-sync 已在系统 Avahi 上注册 `_raop._tcp` / `_airplay._tcp`
- Matter SDK 的 platform mDNS 调用同一个 `avahi-daemon`
- 两套服务通过不同 type 名共存，零冲突
- 校验：`avahi-browse -a` 应能同时看到 Matter 和 AirPlay 服务

### 6. Commissioning 流程（用户视角）

1. 出厂烧录 DAC + Discriminator + PASE Verifier + Setup Code
2. 包装上印 QR 码 + 11 位 manual code
3. 用户上电、插网线 → DHCP 获 IP → 进入 Commissioning Mode → Avahi 广播 `_matterc._udp`（`CM=1` + discriminator）
4. 用户在 Matter App 扫 QR → 控制器局域网 mDNS 发现 → PASE → CASE → 加入 Fabric

Apple Home 兜底：iOS Home App 对纯 IP 设备首配有时识别不出 QR，提供 "More options → My accessory isn't shown here" + 手输 11 位 setup code 的备用路径。

### 7. 出厂数据 / 证书

- `spake2p` 生成每台机器的 PASE Verifier
- `chip-cert` 签每台机器的 DAC（PAI/PAA 申请 CSA 颁发）
- 烧到独立分区 `/factory/`（只读挂载）

### 8. OTA

- Matter OTA Requestor Cluster (`0x0029`) + BDX
- 镜像格式：Matter OTA Image
- `OTARequestorDriverImpl::HandleApply()` 调 RK 现有 A/B 分区 updater
- Provider 可后置上线（自建云端 HTTP + Matter Provider 节点）

### 9. 可复用的 SDK 资源

- `examples/lighting-app/linux/` — Linux 应用骨架
- `src/platform/Linux/ConnectivityManagerImpl.{h,cpp}` — Ethernet 路径已就绪
- `src/platform/Linux/NetworkCommissioningDriver.h` — `LinuxEthernetDriver` 直接用
- `src/platform/Linux/CHIPDevicePlatformConfig.h` — 配置参考
- `src/app/clusters/media-playback-server/` — Media Playback 服务端实现
- `src/app/clusters/ota-requestor/` — OTA Requestor 实现

## 风险

| 风险 | 等级 | 应对 |
|---|---|---|
| Apple Home 对无 BLE 设备首配 UX 较差 | 中 | 手册引导 + 11 位 code，实测 iOS 17/18 |
| 米家 / 华为 Matter 控制器对 Ethernet-only 兼容性未知 | 中 | 真机控制器实测 |
| RK 原厂 SDK 的 Avahi 版本可能过旧 | 低 | 必要时升级 avahi-daemon ≥ 0.8 |
| ALSA mixer 名被 shairport-sync 和 Matter Level Control 共写 | 低 | 统一指向同一 `Master`，业务层幂等 |
| connectedhomeip 交叉编译首次拉依赖（pigweed 等）量大 | 低 | CI 缓存 + 离线 mirror |

## 显式不做

- 不移植 BLE Layer 到 BSA（设备 Ethernet-only，无必要）
- 不动 BSA / shairport-sync / 自家 App
- 不引入 BlueZ
- 不做多分区 Bridge 模式（每个 RK3308 都是独立 Matter Node）

## 实施里程碑

| ID | 内容 | 验收 |
|---|---|---|
| M1 | SDK 交叉编译跑通，禁 BLE/Wi-Fi/Thread | `systemctl status chip-audio-player` running；`avahi-browse -rt _matterc._udp` 显示设备 |
| M2 | chip-tool 在同网段成功 Commission | `chip-tool pairing onnetwork <node-id> <pin>` success；能读 Basic Information |
| M3 | OnOff / LevelControl / MediaPlayback / MediaInput 桥接到播放引擎 | chip-tool 控制实物联动；shairport-sync 切源生效 |
| M4 | 主流生态实测 | Apple Home / Google Home / Alexa / 米家真机入网与控制 |
| M5 | 出厂数据与 OTA | 工装烧录工作流；OTA 升级 → 新版本号上报正确 |
| M6 | CSA 认证 | Authorized Test Lab Matter Test Harness 全套用例 |

## 待确认事项

1. 自家 App 与 Matter 是否需要"状态同步"（App 内改音量，Matter 端是否上报）？影响业务桥接层的双向更新设计。
2. 多分区拓扑：单台 RK3308 = 单 Matter Node？还是有主从结构？
3. Vendor ID 是否已申请？没有的话需先走 CSA 入会。

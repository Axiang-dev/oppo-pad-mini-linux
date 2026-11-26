# Hardware

This page records target hardware known from the device and vendor device tree. Vendor identification in a runtime device tree is not a mainline support claim.

## Device identity

| Item | Value |
|---|---|
| Retail model | OPPO Pad Mini OPD2515 |
| Product code | OP6548L1 |
| Tested firmware family | ColorOS 16, OPD2515 16.0.10.500 CN01 |
| SoC | Qualcomm SM8845P |
| Vendor platform name | canoe |
| Board family names | alor and alorp |
| Upstream SoC family | Molokai, SoC ID 685 |
| Architecture | arm64 |

The selected mainline baseline is Linux commit `6a876df4686788cd39128b62d7fcbff62f39278f`, corresponding to the local v7.4-rc1 source used for the diagnostic patch.

## Display

| Item | Observed value |
|---|---|
| DPU | Qualcomm SDE/DPU, vendor hardware version D10 |
| Hardware generation mapping | D00 canoe, D10 alor |
| DSI controller | Version v2.10, command mode |
| DSI PHY | Version v7.2, DSI 3 nm PLL family |
| Lanes | Four data lanes |
| Panel binding | `oppo,xn254-p-d-a0040` |
| Resolution | 1680 by 2520 |
| Modes | 120 Hz, 144 Hz, 90 Hz, and 60 Hz in vendor data |
| Main tested mode | 120 Hz |
| DSC | Version 1.2, 8 bits per pixel, 10 bits per component |
| Slice | 840 by 24, two slices per packet |
| TE | Vendor GPIO 86 |
| Reset | Vendor GPIO 146 |
| Panel enable | Vendor TLMM GPIO 6 |
| VDDR enable | Vendor PMIC GPIO 4 on the reported PMIC rail |
| Panel supply rails | 1.8 V VDDIO, 1.2 V VDD, 3.0 V VCI |

The panel vendor name is not promoted from a generic touch-vendor string. Treat the panel module and supplier identity as unconfirmed.

## Compute and memory

| Item | Observed value |
|---|---|
| CPU | Eight arm64 cores |
| GPU | Adreno 829, KGSL compatible generation 8.9.0 |
| GPU identifier | `0x44030a00` |
| GPU GMU | `qcom,gen8-gmu`, chip identifier `0x8090000` |
| UFS | Qualcomm UFS host controller |
| SMMU | Application, GPU, and display SMMUs present in the vendor tree |

## Input and wireless

| Item | Observed value |
|---|---|
| Touch controller | Goodix GT9966 |
| Generic Wi-Fi and Bluetooth subsystem | WCN7750 |
| Audio amplifiers | Two TFA98xx devices in vendor data |
| Input buses | I2C touch and SPI/I2C alternatives exist in vendor data |

## Power and safety

The vendor software uses OPLUS charging, fuel-gauge, and thermal components. The mainline tree does not yet implement a reviewed replacement.

Do not disable thermal or charging protection to obtain a quick test result. Do not infer PMIC voltages for a new hardware revision from this page.
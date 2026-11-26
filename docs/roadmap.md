# Development roadmap

The project advances through user-visible hardware capabilities. Compile success,
binding, a node, a framebuffer, or a counter is an intermediate observation.

## M0: Reproducible diagnostic baseline

Current state: repository source and build workflow are being formalized.

Acceptance:

- fixed upstream commit
- patch application checked from a clean tree
- configuration and DTB build checked
- initramfs and packaging inputs documented
- repository privacy and script checks pass
- no proprietary firmware or partition images in Git

This milestone does not claim that the device boots independent of the recorded
local workflow.

## M1: XN254 visible display

Target: native ARM64 test frames visibly appear on the internal panel after a
cold boot.

Acceptance:

- firmware splash and native phases are distinguishable
- DPU, DSI command, DSC, and panel evidence align
- blue and red native frames are visible and correct
- no unexplained SMMU, DSI FIFO, PLL, underflow, or timeout error
- result repeats after a clean boot
- original software recovery remains verified

## M2: Display lifecycle

Target: a persistent minimal Linux userspace controls display normally.

Acceptance:

- correct 60, 90, 120, and 144 Hz modes where supported
- brightness range and minimum brightness
- blank and unblank
- panel reset and power sequencing
- suspend and resume
- no corruption through repeated cold boots

## M3: Minimal device Linux

Target: persistent storage, touch, USB shell, and a minimal ARM64 desktop base.

Acceptance:

- protected installation layout
- cold boot without RAM-only dependency
- touchscreen tap, drag, and multitouch
- USB host and gamepad enumeration
- battery reporting and safe charging policy
- thermal monitoring and frequency policy
- update and recovery path

## M4: GPU acceleration

Target: Adreno 829 Freedreno device works through mainstream DRM/MSM.

Acceptance:

- GMU and power domains operational
- Mesa Freedreno renderer reports hardware acceleration
- OpenGL golden output
- Vulkan supported path with golden output
- GPU reset and timeout recovery
- performance and thermal measurement

## M5: Connectivity, audio, and power

Target: daily-use peripheral baseline.

Acceptance:

- Wi-Fi scan, association, DHCP, and throughput
- Bluetooth controller, scan, and device use
- speaker playback, headphone routing, and microphone capture
- USB host, charging, battery health, and thermal balance
- repeated suspend and resume with measured power

## M6: Armada OS and gaming stack

Target: usable Armada OS desktop and Steam Game Mode.

Acceptance:

- Armada userspace boots from persistent storage
- desktop compositor and input are stable
- Gamescope uses the expected display and GPU paths
- FEX runs tested x86-64 applications
- Proton, DXVK, and VKD3D-Proton run accepted test titles
- performance, thermals, audio, suspend, and recovery pass a full regression

No milestone can be closed solely through source analysis or a CI build.

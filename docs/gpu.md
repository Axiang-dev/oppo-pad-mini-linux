# Adreno GPU bring-up

The target GPU is Adreno 829 with vendor generation 8.9.0 and GPU identifier
`0x44030a00`. The vendor tree also identifies GMU generation 8 and chip identifier
`0x8090000`.

The selected mainline baseline does not contain a complete reviewed path for this
exact target. GPU status is **Blocked**. There is no claim of native OpenGL or
Vulkan acceleration.

## What is already known

- The SoC and GPU identifiers are visible in vendor source and device data.
- The display diagnostic path uses the single DRM/MSM module built from the
  patched mainline source.
- A framebuffer being present does not imply that the GPU has powered up.
- A software renderer or CPU framebuffer copy is not hardware acceleration.

## Missing work

- Confirm the upstream Adreno device ID mapping and register/catalog parameters.
- Establish the correct CX, GX, and MX power-domain sequencing.
- Load the correct GMU firmware for the target design.
- Validate GMU boot, RPC, interrupts, and SMMU behavior.
- Validate GPU fault recovery and timeout handling.
- Validate Freedreno DRM rendering.
- Validate Mesa Freedreno OpenGL.
- Validate Vulkan through the current supported Mesa path.
- Measure memory bandwidth, thermal behavior, and frequency scaling.
- Test a long-running desktop or game workload through the normal entry point.

## Research entry points

Search source and mail archives by exact identifiers rather than copying another
Adreno generation:

- `0x44030a00`
- Adreno 829 or compatible vendor strings
- `gen8-gmu`
- `0x8090000`
- Molokai, Kaanapali, and adjacent sm8850-family device trees
- `a8xx_catalog`, GMU firmware naming, and power-domain tables
- Linux DRM/MSM and MSM DRM mailing-list patch series

Upstream code and matching hardware evidence must agree before this repository
claims GPU support.

## Acceptance

GPU support is accepted only when the renderer identifies the hardware device,
golden rendered output is pixel-correct, GPU hang and recovery paths pass, and an
application reaches the device through the normal Linux graphics stack. OpenGL and
Vulkan require separate functional tests.

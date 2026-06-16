---
id: "0017"
title: AIPCC Base Images
status: active
created: 2026-05-26
affects:
  - platform
release:
  - "3.5"
  - "next"
provenance:
  - https://gitlab.com/redhat/rhel-ai/core/base-images/app
author: Doug Hellmann
superseded_by: null
---

## Fact

The AIPCC base images provide RHEL-based application containers with
runtime dependencies for hardware accelerators used in AI workloads.
Downstream teams extend these images by installing Python wheels and
additional packages to create product containers (e.g., vLLM, InstructLab).

Images follow a layout similar to
[s2i-base-containers](https://github.com/sclorg/s2i-base-container)
but are not `s2i` images. Each image runs as an unprivileged user
(UID 1001) and ships `pip` and `uv` pre-configured with the RHEL AI
Python Package Index.

### Common Foundation

All images share:

- **Base OS:** RHEL 9.6 (`registry.redhat.io/rhel9-6-els/rhel:9.6`)
- **Python:** 3.12
- **RHEL AI repo version:** 3.5
- **Package index version:** 3.5
- **Repositories:** BaseOS, AppStream, CodeReady Builder, RHELAI (EUS
  repos on even y-stream releases like 9.6)
- **Container layout:** `/opt/app-root/` with `pip.conf` and `uv.toml`
  pre-configured
- **Environment metadata:** `/etc/rhaipcc/env` provides shell variables
  for variant, versions, and repository info
- **Helper script:** `/usr/libexec/rhaipcc/dnf` enables vendor repos
  for additional package installs

### Accelerator Summary

| Accelerator | Version | Status | Python | RHEL | aarch64 | ppc64le | s390x | x86\_64 |
|---|---|---|---|---|---|---|---|---|
| CPU | -- | Active | 3.12 | 9.6 | Yes | Yes | Yes | Yes |
| NVIDIA CUDA | 12.9.1 | Active | 3.12 | 9.6 | Yes | -- | -- | Yes |
| NVIDIA CUDA | 13.0.2 | Active | 3.12 | 9.6 | Yes | -- | -- | Yes |
| NVIDIA CUDA | 13.2.1 | Active | 3.12 | 9.6 | Yes | -- | -- | Yes |
| AMD ROCm | 7.14 | Active | 3.12 | 9.6 | -- | -- | -- | Yes |
| Intel Gaudi | 1.24.0 | Disabled | 3.12 | 9.6 | -- | -- | -- | Yes |
| IBM Spyre | 1.2.3 | Active | 3.12 | 9.6 | -- | Yes | Yes | Yes |
| AWS Neuron | 2.x | In development | 3.12 | 9.6 | -- | -- | -- | Yes |
| Google TPU | -- | In development | 3.12 | 9.6 | -- | -- | -- | Yes |
| AMD ROCm | 6.4 | Retired | -- | -- | -- | -- | -- | -- |

### Status Legend

- **Active** -- supported and built in CI
- **In development** -- under active development, not yet GA
- **Disabled** -- configuration exists but builds are skipped
- **Retired** -- removed from the repository

### CPU

- **Status:** Active
- **Config:** `build-args/cpu-app.conf`
- **Architectures:** aarch64, ppc64le, s390x, x86\_64
- **Container:** `quay.io/aipcc/base-images/cpu`
- **Extra dependencies:** None. The CPU image is the simplest variant
  with no accelerator-specific packages.

### NVIDIA CUDA

Three CUDA versions are maintained, sharing a single
`Containerfile.cuda-app` with version-specific behavior controlled by
build args.

#### CUDA 12.9.1

- **Status:** Active
- **Config:** `build-args/cuda12.9-el9.6-app.conf`
- **Architectures:** aarch64, x86\_64
- **Container:** `quay.io/aipcc/base-images/cuda-12.9-el9.6`
- **Driver requirement:** `>=525.60.13`
- **Key dependencies:**
  - NCCL 2.29.7
  - cuDNN 9
  - UCX 1.19.1
  - cuBLASMp 0.x
  - cuDSS 0.x
  - cuSPARSELt 0.x
  - NVSHMEM 3.4.5

#### CUDA 13.0.2

- **Status:** Active
- **Config:** `build-args/cuda13.0-el9.6-app.conf`
- **Architectures:** aarch64, x86\_64
- **Container:** `quay.io/aipcc/base-images/cuda-13.0-el9.6`
- **Driver requirement:** `>=580.95.05`
- **Key dependencies:**
  - NCCL 2.28.3
  - cuDNN 9.19.0.56
  - UCX 1.19.1
  - cuBLASMp 0.x
  - cuDSS 0.x
  - cuSPARSELt 0.x
  - NVSHMEM 3.4.5

#### CUDA 13.2.1

- **Status:** Active
- **Config:** `build-args/cuda13.2-el9.6-app.conf`
- **Architectures:** aarch64, x86\_64
- **Container:** `quay.io/aipcc/base-images/cuda-13.2-el9.6`
- **Driver requirement:** `>=595.58.03`
- **Key dependencies:**
  - NCCL 2.29.7
  - cuDNN 9.19.0.56
  - UCX 1.19.1
  - cuBLASMp 0.x
  - cuDSS 0.x
  - cuSPARSELt 0.x
  - NVSHMEM 3.5.19

### AMD ROCm

- **Status:** Active
- **Config:** `build-args/rocm7.14-el9.6-app.conf`
- **ROCm version:** 7.14
- **Architectures:** x86\_64
- **Container:** `quay.io/aipcc/base-images/rocm-7.14-el9.6`
- **Key dependencies:** MIOpen, RCCL, hipBLAS, and other ROCm
  libraries are installed via vendor RPM repositories. AMD uses
  separate `amd-gpu` and `rocm` repo IDs per version.

### Intel Gaudi

- **Status:** Disabled
  ([AIPCC-3471](https://issues.redhat.com/browse/AIPCC-3471))
- **Config:** `build-args/gaudi-app.conf`
- **Gaudi version:** 1.24.0 (revision 1007)
- **Architectures:** x86\_64
- **Container:** `quay.io/aipcc/base-images/gaudi` (not currently published)

Gaudi builds are disabled because earlier versions did not support
Python 3.12 and RHEL 9.6. Gaudi support is planned to resume in 2026.
The Tekton push pipeline exists but triggers only on `refs/tags/gaudi-v`
tags, not in regular CI.

### IBM Spyre

- **Status:** Active
- **Config:** `build-args/spyre-app.conf`
- **Spyre version:** 1.2.3 (all architectures)
- **Architectures:** ppc64le, s390x, x86\_64
- **Container:** `quay.io/aipcc/base-images/spyre`
- **Notes:** Spyre uses per-architecture version variables
  (`SPYRE_VERSION_x86_64`, `SPYRE_VERSION_ppc64le`,
  `SPYRE_VERSION_s390x`) to allow independent version updates. RPMs
  are signed by IBM with architecture-specific GPG keys.

### AWS Neuron

- **Status:** In development
- **Config:** `build-args/neuron-app.conf`
- **Architectures:** x86\_64
- **Container:** `quay.io/aipcc/base-images/neuron`
- **Key dependencies:**
  - Neuron Runtime Library 2.30.51
  - Neuron Tools 2.28.23
  - Neuron Collectives 2.30.59
- **Notes:** Neuron SDK components are installed as RPMs from a manually
  mirrored copy of the AWS Neuron yum repository. Strategies depending on Neuron
  updates must account for this manual mirror synchronization delay and cannot
  assume same‑day upstream releases.

### Google TPU

- **Status:** In development
- **Config:** `build-args/tpu-app.conf`
- **Architectures:** x86\_64
- **Container:** `quay.io/aipcc/base-images/tpu`
- **Notes:** The TPU image uses Torch/XLA and has no
  version-specific accelerator dependencies in the conf file.

### Retired Accelerators

#### AMD ROCm 6.4

ROCm 6.4 was retired in RHAI 3.5-EA1
([AIPCC-15426](https://issues.redhat.com/browse/AIPCC-15426)). The
base image and Tekton pipelines were removed. ROCm 7.14 is the
current supported version.

## Impact on Strategies

- All RHAI components that use accelerator-specific Python libraries MUST use
  these base images; components that have not yet migrated must be updated to
  stay current with the platform.
- Active vs. in-development status matters: AWS Neuron and Google TPU are not GA
  -- strategies must not assume their availability in production workloads.
- Intel Gaudi is disabled (AIPCC-3471); strategies targeting Gaudi must wait
  until support resumes (planned 2026) and must not reference Gaudi as an
  available accelerator.
- AMD ROCm 6.4 is retired; any references in strategies or RFEs must be updated
  to ROCm 7.14, the current supported version.
- Three CUDA versions (12.9, 13.0, 13.2) are maintained simultaneously --
  strategies and RFEs proposing CUDA-dependent features should specify the
  minimum driver version requirement, since each version has a different minimum
  driver.
- IBM Spyre uses per-architecture versioning (`SPYRE_VERSION_x86_64`,
  `SPYRE_VERSION_ppc64le`, `SPYRE_VERSION_s390x`) -- strategies targeting IBM
  hardware should account for independent version updates per architecture.
- The RHEL AI Python Package Index is the authoritative source for Python wheels
  in all images; strategies that add Python dependencies must ensure those
  packages are available in this index.

## Context

This overlay was created to capture the accelerator base image landscape as a
reference for evaluating RFEs proposing accelerator updates or additions. The
generated architecture docs for individual components (vLLM, InstructLab, etc.)
do not describe the shared base image layer or the current status of each
accelerator variant. This overlay fills that gap so that strategy pipelines,
architecture reviews, and design validation tooling have an authoritative,
up-to-date view of which accelerators are active, in development, disabled, or
retired, and what the common foundation looks like across all variants.

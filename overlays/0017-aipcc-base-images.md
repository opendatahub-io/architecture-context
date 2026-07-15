---
id: "0017"
title: AIPCC Base Images
status: active
created: 2026-05-26
affects:
  - platform
release:
  - "3.6"
  - "next"
provenance:
  - https://gitlab.com/redhat/rhel-ai/wheels/fondue/-/tree/main/images/base
author: Doug Hellmann
superseded_by: null
---

## Fact

The AIPCC base images provide RHEL-based application containers with
runtime dependencies for hardware accelerators used in AI
workloads. The images also provide access to versions of python
packages built in Red Hat's secure build pipelines.  Downstream teams
extend these images by installing Python wheels and additional
packages to create product containers (e.g., vLLM, InstructLab).

Images follow a layout similar to
[s2i-base-containers](https://github.com/sclorg/s2i-base-container)
but are not `s2i` images. Each image runs as an unprivileged user
(UID 1001) and ships `pip` and `uv` pre-configured with the RHEL AI
Python Package Index.

### Common Foundation

All images share:

- **Base OS:** RHEL 9.6 (`registry.redhat.io/rhel9-6-els/rhel:9.6-1782883081`)
- **Python:** 3.12
- **RHEL AI repo version:** 3.5
- **Package index version:** 3.6-EA1
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
| NVIDIA Rubin | 13.4.0 | In development | 3.12 | 9.6 | Yes | -- | -- | Yes |
| AMD ROCm | 7.14 | Active | 3.12 | 9.6 | -- | -- | -- | Yes |
| Intel Gaudi | 1.24.1 | Active | 3.12 | 9.6 | -- | -- | -- | Yes |
| IBM Spyre | 1.2.5 | Active | 3.12 | 9.6 | -- | Yes | Yes | Yes |
| AWS Neuron | 2.32 | In development | 3.12 | 9.6 | -- | -- | -- | Yes |
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
- **Container:** `rhaibi-cpu`
- **Extra dependencies:** None. The CPU image is the simplest variant
  with no accelerator-specific packages.

### NVIDIA CUDA

Three active CUDA versions are maintained, sharing a single
`Containerfile.cuda-app` with version-specific behavior controlled by
build args. A fourth version (Rubin / CUDA 13.4) is in development.

#### CUDA 12.9.1

- **Status:** Active
- **Config:** `build-args/cuda12.9-el9.6-app.conf`
- **Architectures:** aarch64, x86\_64
- **Container:** `rhaibi-cuda12.9-el9.6`
- **Driver requirement:** `>=525.60.13`
- **Key dependencies:**
  - NCCL 2.30.4
  - cuDNN 9.22.0.52
  - UCX 1.20.1
  - cuBLASMp 0.x
  - cuDSS 0.7.1.4
  - cuSPARSELt 0.x
  - NVSHMEM 3.5.19

#### CUDA 13.0.2

- **Status:** Active
- **Config:** `build-args/cuda13.0-el9.6-app.conf`
- **Architectures:** aarch64, x86\_64
- **Container:** `rhaibi-cuda13.0-el9.6`
- **Driver requirement:** `>=580.95.05`
- **Key dependencies:**
  - NCCL 2.30.4
  - cuDNN 9.19.0.56
  - UCX 1.20.1
  - cuBLASMp 0.x
  - cuDSS 0.7.1.4
  - cuSPARSELt 0.x
  - NVSHMEM 3.5.19

#### CUDA 13.2.1

- **Status:** Active
- **Config:** `build-args/cuda13.2-el9.6-app.conf`
- **Architectures:** aarch64, x86\_64
- **Container:** `rhaibi-cuda13.2-el9.6`
- **Driver requirement:** `>=595.58.03`
- **Key dependencies:**
  - NCCL 2.29.7 (pinned; lags NVIDIA public mirror for CUDA 13.2)
  - cuDNN 9.19.0.56
  - UCX 1.20.1
  - cuBLASMp 0.x
  - cuDSS 0.7.1.4
  - cuSPARSELt 0.x
  - NVSHMEM 3.5.19

### NVIDIA Rubin

- **Status:** In development (CUDA 13.4 Developer Preview)
- **Config:** `build-args/rubin-app.conf`
- **Architectures:** aarch64, x86\_64
- **Container:** `rhaibi-rubin-el9.6`
- **Driver requirement:** `>=616`
- **Key dependencies:**
  - NCCL 2.30.7
  - cuDNN 9.19.0.56
  - UCX 1.20.1
  - cuBLASMp 0.x
  - cuDSS 0.7.1.4
  - cuSPARSELt 0.x
  - NVSHMEM 3.5.19
- **Notes:** Rubin targets the NVIDIA Rubin GPU architecture with CUDA 13.4.0
  (Developer Preview). Pulp PyPI index tests (`enable_pulp_test: true`) are now
  enabled for MR builds on both aarch64 and x86_64. Despite active CI coverage,
  strategies must not assume GA availability — this variant is still in the
  CUDA 13.4 Developer Preview phase.

### AMD ROCm

- **Status:** Active
- **Config:** `build-args/rocm7.14-el9.6-app.conf`
- **ROCm version:** 7.14
- **Architectures:** x86\_64
- **Container:** `rhaibi-rocm7.14-el9.6`
- **Key dependencies:** MIOpen, RCCL, hipBLAS, and other ROCm
  libraries are installed via vendor RPM repositories. AMD uses
  separate `amd-gpu` and `rocm` repo IDs per version. ROCm 7.14 installs
  under `/opt/rocm/core-7.x/`; `/opt/rocm/core` is a symlink via alternatives
  to the versioned directory.

### Intel Gaudi

- **Status:** Active
- **Config:** `build-args/gaudi-app.conf`
- **Gaudi version:** 1.24.1 (revision 482)
- **Python:** 3.12
- **Architectures:** x86\_64
- **Container:** `rhaibi-gaudi`

Gaudi builds are fully enabled in GitLab CI (`VARIANT_ENABLED: true`). The
Python 3.12 / RHEL 9.6 blocker (AIPCC-3471) was resolved in 3.5-EA2. The
Tekton (Konflux) pipeline is gated to release tags (`refs/tags/v*` or
`refs/tags/gaudi-v*`) rather than every push; MR and tag builds run through
GitLab CI. Pulp test jobs are not yet enabled for Gaudi (`enable_pulp_test`
is omitted in all-variants.yml, so it uses the default value of false).

### IBM Spyre

- **Status:** Active
- **Config:** `build-args/spyre-app.conf`
- **Spyre version:** 1.2.5 (all architectures)
- **Architectures:** ppc64le, s390x, x86\_64
- **Container:** `rhaibi-spyre`
- **Notes:** Spyre uses per-architecture version variables
  (`SPYRE_VERSION_x86_64`, `SPYRE_VERSION_ppc64le`,
  `SPYRE_VERSION_s390x`) to allow independent version updates per arch.
  All three architectures are currently on the same version (1.2.5). RPMs
  are signed by IBM with architecture-specific GPG keys.
- **IBM AIU Monitor:** `ibm-aiu-monitor==1.2.0` is installed into a dedicated
  venv at `/opt/aiu-monitor` from a private IBM PyPI index — it is not in the
  public wheel collections and is therefore not subject to the standard Pulp
  index workflow. Installed on x86\_64 and ppc64le only (not s390x).

### AWS Neuron

- **Status:** In development
- **Config:** `build-args/neuron-app.conf`
- **Architectures:** x86\_64
- **Container:** `rhaibi-neuron`
- **Key dependencies:**
  - Neuron Runtime Library 2.32.31
  - Neuron Tools 2.30.10
  - Neuron Collectives 2.32.28
- **Notes:** Neuron SDK components are installed as RPMs from a manually
  mirrored copy of the AWS Neuron yum repository. Strategies depending on Neuron
  updates must account for this manual mirror synchronization delay and cannot
  assume same‑day upstream releases.

### Google TPU

- **Status:** In development
- **Config:** `build-args/tpu-app.conf`
- **Architectures:** x86\_64
- **Container:** `rhaibi-tpu`
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
- Active vs. in-development status matters: AWS Neuron, Google TPU, and NVIDIA
  Rubin are not GA -- strategies must not assume their availability in production
  workloads.
- Intel Gaudi is Active (AIPCC-3471 resolved in 3.5-EA2). GitLab CI builds are
  fully enabled on x86_64. The Tekton/Konflux pipeline is gated to release tags.
  Strategies may target Gaudi but should note that Pulp PyPI index test coverage
  is not yet enabled for this variant (`enable_pulp_test` omitted, defaults
  false) — unusually, NVIDIA Rubin (still in development) has it enabled.
- NVIDIA Rubin now has Pulp PyPI index tests enabled (`enable_pulp_test: true`)
  for MR builds on aarch64 and x86_64, but the variant remains in development
  (CUDA 13.4 Developer Preview). Do not treat test coverage as a signal of GA
  readiness for Rubin.
- AMD ROCm 6.4 is retired; any references in strategies or RFEs must be updated
  to ROCm 7.14, the current supported version.
- Three active CUDA versions (12.9, 13.0, 13.2) are maintained simultaneously,
  with a fourth (Rubin / CUDA 13.4) in development. Strategies and RFEs proposing
  CUDA-dependent features should specify the minimum driver version requirement,
  since each version has a different minimum driver (525, 580, 595, 616).
- IBM Spyre uses per-architecture versioning (`SPYRE_VERSION_x86_64`,
  `SPYRE_VERSION_ppc64le`, `SPYRE_VERSION_s390x`) -- strategies targeting IBM
  hardware should account for independent version updates per architecture, even
  when all arches are currently on the same version.
- The RHEL AI Python Package Index (`INDEX_VERSION=3.6-EA1`) is the authoritative
  source for Python wheels in all images; strategies that add Python dependencies
  must ensure those packages are available in this index.

## Context

This overlay was created to capture the accelerator base image landscape as a
reference for evaluating RFEs proposing accelerator updates or additions. The
generated architecture docs for individual components (vLLM, InstructLab, etc.)
do not describe the shared base image layer or the current status of each
accelerator variant. This overlay fills that gap so that strategy pipelines,
architecture reviews, and design validation tooling have an authoritative,
up-to-date view of which accelerators are active, in development, disabled, or
retired, and what the common foundation looks like across all variants. Updated
2026-07-30 by running the `update-aipcc-base-images-overlay` skill.

---
id: "0013"
title: Universal training image -- dual-purpose workbench and training runtime
status: active
created: 2026-06-02
affects:
  - platform
  - trainer
  - notebooks
  - training-hub
release:
  - "3.4"
  - "3.5"
  - "next"
provenance:
  - https://redhat.atlassian.net/browse/RHOAIENG-35690
  - https://redhat.atlassian.net/browse/RHAISTRAT-44
  - https://docs.google.com/document/d/1uWmicavmKkfwFSE8s_rvWW4Hj4wXSSdg6XAizZ-MtVA/edit
  - https://github.com/opendatahub-io/distributed-workloads/tree/main/images/universal/training
author: Brian Gallagher
superseded_by: null
---

## Fact

The **universal training image** is a dual-purpose container image that serves as both a Jupyter workbench image (selectable in the RHOAI dashboard) and a headless training runtime image (referenced in Kubeflow Trainer ClusterTrainingRuntimes). It is built in the `opendatahub-io/distributed-workloads` repository and owned by the Kubeflow DevX team.

The image packages all Training Hub dependencies into a single consistent environment, ensuring that experiments run in a notebook scale identically to distributed training jobs on Kubeflow Trainer. The dual-purpose behaviour is controlled by the `entrypoint-universal.sh` entrypoint, which switches on the `NOTEBOOK_ARGS` environment variable: when the OpenShift workbench controller sets `NOTEBOOK_ARGS` (e.g., `--ServerApp.port=8888 --ServerApp.token='' ...`), the entrypoint starts Jupyter via `start-notebook.sh ${NOTEBOOK_ARGS}` (workbench mode); when the Kubeflow Trainer SDK creates a TrainJob, it overrides the container `command` entirely, bypassing the entrypoint so the training script runs directly (runtime mode). Downstream consumers set the mode as follows: workbench ImageStream configs rely on the Notebook CR controller injecting `NOTEBOOK_ARGS`, and ClusterTrainingRuntime manifests need only specify the image — the Trainer controller supplies the training command at pod creation time.

### Image Variants

| Image | Toolkit | Architectures |
|-------|---------|---------------|
| `odh-training-th06-cuda130-torch210-py312` | CUDA 13.0 | x86_64, arm64 |
| `odh-training-th06-rocm64-torch291-py312` | ROCm 6.4 | x86_64 |
| `odh-training-th06-cpu-torch210-py312` | CPU | x86_64, arm64 |

Image naming convention: `<training-hub-version>-<toolkit-version>-<torch-version>-<python-version>`. A minor version change to any of the four core components (Training Hub, CUDA/ROCm, Torch, Python) produces a new image variant.

### Image Layer Stack

| Layer | Source | Owner |
|-------|--------|-------|
| Universal image (Training Hub, Kubeflow SDK, InstructLab Training, Mini Trainer, PEFT, Flash Attention, Liger Kernel) | `opendatahub-io/distributed-workloads` | Kubeflow DevX |
| Jupyter minimal workbench (JupyterLab, Jupyter Server) | `opendatahub-io/notebooks` / AIPCC | Notebooks team |
| AIPCC base image (CUDA/ROCm, Python) | AIPCC | AIPCC team |
| RHEL 9 | Red Hat | AIPCC team |

### Platform Integration

| Context | Mechanism | Consumer |
|---------|-----------|----------|
| Workbench | ImageStream in `opendatahub-io/trainer` RHOAI manifests | RHOAI Dashboard (user selects image) |
| Training runtime | ClusterTrainingRuntime CRs in `opendatahub-io/trainer` RHOAI manifests | Kubeflow Trainer (creates TrainJob pods) |
| Pipelines | KFP component `base_image` parameter | pipelines-components fine-tuning pipelines |

### Release Coordination

The image requires cross-team coordination between three teams each release cycle:

| Team | Responsibility |
|------|---------------|
| **Kubeflow DevX** | Image owner. Builds, tests, releases. Coordinates dependencies. |
| **Notebooks** | Provides Jupyter minimal base image. Confirms CUDA/ROCm version alignment. |
| **AIPCC** | Provides base images, PyPI indexes, and pre-compiled wheels. Onboards new packages on request. |
| **AI Innovation** | Owns Training Hub. Provides version with lockfile of recommended dependency versions. |

The release process spans the full RHOAI development cycle (~30 days) and is documented in the [Universal image release process](https://docs.google.com/document/d/1uWmicavmKkfwFSE8s_rvWW4Hj4wXSSdg6XAizZ-MtVA/edit). Key milestones: core version agreement (day 1-5), early midstream build (day 1-5), downstream onboarding start (day 1-14), Training Hub and SDK release (~14 days before freeze), midstream and downstream finalization (~1 day before freeze).

### Repository and Discovery Context

The image source lives in `opendatahub-io/distributed-workloads` under `universal-image/`. This repo is cloned by the architecture pipeline (it is in the `red-hat-data-services` org) but is excluded from the component map as `"documentation_testing"`. The universal image is not a standalone deployed component -- it is a build artifact consumed by the Trainer manifests and the Notebooks ImageStream infrastructure.

## Impact on Strategies

- The universal image is the **standard runtime** for all Training Hub algorithms (SFT, OSFT, LoRA, GRPO) on Kubeflow Trainer. Strategies targeting training workloads should reference these images, not custom-built containers
- The dual-purpose design means a single image must satisfy both Jupyter workbench constraints (startup, idle culling, UI extensions) and training runtime constraints (no UI, GPU utilisation, distributed training). Architecture reviewers should not split these into separate images without understanding the intentional design
- Image versioning is tied to four core components (Training Hub, CUDA/ROCm, Torch, Python). A bump to any one triggers a new image variant. Backward compatibility is maintained by preserving older variants alongside new ones in ClusterTrainingRuntimes
- The release timeline is tightly coupled to AIPCC index availability. Strategies requiring new Python packages in the training environment must account for AIPCC onboarding lead time (~14 days before code freeze)
- The `distributed-workloads` repo is excluded from architecture generation (`"documentation_testing"` in the component map). This is intentional -- the repo primarily contains Dockerfiles and CI config rather than deployed services. The universal image's architectural significance is captured through this overlay and the Trainer component doc's parameterisation table

## Context

The generated architecture docs reference the universal image indirectly: `trainer.md` lists the image variants as parameterised values in ClusterTrainingRuntimes, and overlay 0009 mentions Training Hub is "pre-installed in Kubeflow SDK universal images." However, no generated doc explains the dual-purpose design, the cross-team release coordination, or why the image exists as a unified artifact spanning the workbench and training boundaries. The `notebooks.md` doc does not mention it at all (it covers base workbench images only). This overlay provides the integration context for strategies and reviews that touch training runtimes, workbench images, or AIPCC dependencies.

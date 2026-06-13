---
id: "0012"
title: Kubeflow SDK platform integration and midstream architecture context
status: active
created: 2026-05-26
affects:
  - platform
  - notebooks
  - trainer
  - training-operator
release:
  - "3.4"
  - "3.5"
  - "next"
provenance:
  - https://redhat.atlassian.net/browse/RHOAIENG-62211
  - https://github.com/opendatahub-io/kubeflow-sdk
  - https://github.com/kubeflow/sdk
author: Brian Gallagher
superseded_by: null
---

## Fact

The **Kubeflow SDK** (`opendatahub-io/kubeflow-sdk`) is a shipped RHOAI component providing the unified Python API (`kubeflow` package) for Kubeflow Trainer, Optimizer, Spark Operator, and Model Registry. It is distributed as a pip dependency inside universal training images (via `distributed-workloads`) and notebook workbench images. The SDK is absent from the architecture-context component inventory and has no generated architecture doc because: (a) the repo lives in `opendatahub-io`, not `red-hat-data-services`, (b) it has no operator manifest entry, and (c) it is not listed in `platforms.yaml` `extra_repos`.

The SDK has a three-tier delivery flow:

| Tier | Repo | Versioning |
|------|------|-----------|
| Upstream | `kubeflow/sdk` | Semantic (`0.4.0`) |
| Midstream (ODH) | `opendatahub-io/kubeflow-sdk` | RHAI (`v0.3.0+rhaiv.2`) |
| Downstream | AIPCC indexes (no separate repo) | Same as midstream |

Current shipped version: **v0.3.0+rhaiv.2** (RHOAI 3.4 GA). Upstream is at **0.4.0**.

### Sub-packages and Platform Relationships

| Sub-package | Platform Component | Interaction |
|-------------|-------------------|-------------|
| `kubeflow.trainer` | Trainer / Training Operator | Creates TrainJob and ClusterTrainingRuntime CRs via Kubernetes API |
| `kubeflow.optimizer` | (upstream only, not yet shipped in RHOAI) | Creates Experiment CRs for hyperparameter optimization |
| `kubeflow.hub` | Model Registry | REST API client for model registration and versioning |
| `kubeflow.spark` | Spark Operator | Creates SparkConnect sessions via Kubernetes API |

### Midstream Divergence

The midstream fork carries RHOAI-specific extensions not present upstream:

| Path | Purpose |
|------|---------|
| `kubeflow/trainer/rhai/` | TrainingHub/RHAI trainer extensions (checkpoints, S3, LoRA, algorithms) |
| `kubeflow/trainer/algorithms.py` | Centralized training algorithm registry (SFT, OSFT, LoRA, GRPO) |
| `.github/workflows/odh-release.yaml` | Midstream release workflow |
| `.github/workflows/rebase-upstream.yaml` | Daily upstream sync (merge-based) |

These extensions exist because RHOAI ships Training Hub (a higher-level training abstraction) integrated into the SDK's trainer sub-package, whereas upstream Trainer uses the lower-level Kubeflow Training API directly. The divergence is intentional and maintained -- it will either graduate upstream or remain as a permanent midstream extension depending on Training Hub's upstream adoption trajectory.

### Upstream Sync

The midstream syncs with upstream daily via GitHub Actions (`rebase-upstream.yaml`). Conflicts are common in `pyproject.toml` (dependency groups), `kubeflow/__init__.py` (version string), and `kubeflow/trainer/backends/` (both sides modify). A Cursor skill (`team-kubeflow-devx` repo: `skills/upstream-sync-resolver/`) provides tiered automated conflict resolution.

### Release Cadence

The SDK is cut **10 days before each RHOAI code freeze**. Component teams (Trainer, Model Registry, Spark) own their sub-packages; the Kubeflow DevX team cuts releases and manages interoperability.

### Contacts

| Channel | Purpose |
|---------|---------|
| `#forum-openshift-ai-kubeflow-sdk` (Slack) | SDK development and releases |
| `@openshift-ai-kubeflow-devx` (Slack) | Team handle |
| `#kubeflow-ml-experience` (CNCF Slack) | Upstream ML Experience WG |

## Impact on Strategies

- Treat **kubeflow SDK** as a shipped RHOAI component, functionally equivalent to CodeFlare SDK in delivery pattern (pip dependency in workbench/universal images, no operator manifest)
- The SDK is the **developer entry point** for training, optimization, model registry, and Spark. RFEs targeting user-facing training workflows should trace through the SDK API, not just the operator CRDs
- The midstream carries Training Hub extensions (`kubeflow/trainer/rhai/`). Architecture reviewers should not flag these as "upstream divergence risk" without context -- the divergence is intentional and actively managed via daily sync
- The SDK version lags upstream by one minor version in RHOAI GA (currently `0.3.0+rhaiv.2` vs upstream `0.4.0`). Strategies requiring upstream `0.4.0` features (SparkClient, RuntimePatches API) should target RHOAI 3.5+
- `kubeflow.pipelines` (KFP integration) is planned but not yet available. Strategies requiring both Pipelines and Training SDK access must still use `kfp` alongside `kubeflow` as separate packages
- Component teams own their sub-packages but do **not** cut SDK releases. Dependency changes or new optional extras require AIPCC onboarding coordination with the SDK team

## Context

The architecture generation pipeline discovers components via org clone + manifest parsing + adjacent repo scanning. The Kubeflow SDK is not discoverable because: it lives in `opendatahub-io` (not in the `red-hat-data-services` org clone used for RHOAI), it has no Kubernetes manifests, and it ships as a transitive pip dependency rather than a container image. This is the same pattern as CodeFlare SDK (overlay 0004), which was resolved by adding it to `platforms.yaml` as an `extra_repos` entry. This overlay is accompanied by a `platforms.yaml` change to enable full architecture generation in the next pipeline cycle.

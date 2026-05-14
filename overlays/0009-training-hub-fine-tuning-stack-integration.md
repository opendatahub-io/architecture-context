---
id: "0009"
title: Training Hub and fine-tuning stack integration context
status: active
created: 2026-05-13
affects:
  - training-hub
  - trainer
  - training-operator
  - fms-hf-tuning
  - platform
release:
  - "3.4"
  - "3.5"
  - "next"
provenance:
  - https://redhat.atlassian.net/browse/RHOAIENG-62210
author: Fiona Waters
superseded_by: null
---

## Fact

Training Hub (Red-Hat-AI-Innovation-Team/training_hub) is a Python library providing a unified API for LLM post-training algorithms. It is pre-installed in Kubeflow SDK universal images and runs inside training pods orchestrated by the Kubeflow Training Operator (KFTO) via PyTorchJob or by Trainer v2 via TrainJob/ClusterTrainingRuntime. Training Hub is not a standalone service; it has no ingress, no CRDs, and no operator. Integration into the Ray component is upcoming.

The RHOAI fine-tuning stack has four components that existing architecture docs do not cross-reference:

| Component | Role | Algorithms |
|-----------|------|------------|
| **Training Hub** | High-level Python API; algorithm-backend abstraction | SFT, OSFT, LoRA+SFT, LoRA+GRPO, full GRPO (DPO planned) |
| **fms-hf-tuning** | Lower-level container library for SFT | SFT, LoRA, QLoRA, Prompt Tuning |
| **Kubeflow Trainer v2** | Kubernetes operator creating TrainJob/ClusterTrainingRuntime | N/A (orchestration, not algorithms) |
| **Kubeflow Training Operator (KFTO)** | Legacy operator creating PyTorchJob/MPIJob | N/A (orchestration, not algorithms) |

Training Hub and fms-hf-tuning are independent libraries that both run inside KFTO/Trainer pods. Training Hub is the higher-level abstraction supporting multiple algorithms and backends (InstructLab Training, Mini-Trainer, Unsloth, OpenPipe ART, verl). fms-hf-tuning is a narrower SFT-focused library using HuggingFace Transformers + TRL.

Training Hub first ships as a pip dependency (`training_hub[lora]==0.6.0`) in the `distributed-workloads` universal training images starting from rhoai-3.4-ea.2. It is not present in rhoai-3.4-ea.1 or earlier.

## Impact on Strategies

- The end-to-end training lifecycle is: user defines TrainJob (Trainer v2) or PyTorchJob (KFTO) -> operator creates pods with universal training images -> Training Hub or fms-hf-tuning runs inside the pod -> results written to checkpoints. Architecture reviews and RFE feasibility assessments should trace this full path.
- Training Hub, fms-hf-tuning, and KFTO/Trainer v2 are independent components with separate roadmaps. Training Hub and fms-hf-tuning both provide training algorithms; KFTO and Trainer v2 handle orchestration.
- Training Hub supports two GRPO backends: ART (single-GPU, fast iteration) and verl (multi-GPU, scales to 70B+). Backend choice affects GPU resource requirements and should be factored into capacity planning.
- The existing `trainer.md`, `training-operator.md`, and `fms-hf-tuning.md` architecture docs do not mention Training Hub. Until regeneration adds this context, treat this overlay as the integration reference.

## Context

RHOAIENG-62210 investigated whether the fine-tuning domain is adequately represented in architecture context. The generated component docs for trainer, training-operator, and fms-hf-tuning each describe their own component in isolation but do not explain how they compose. Training Hub was not previously included in the architecture-context pipeline. This overlay bridges the gap until the next architecture regeneration cycle incorporates Training Hub references into the related component docs.

---
id: "0005"
title: HardwareProfile platform capability for workload resource management
status: active
created: 2026-05-11
affects:
  - platform
  - rhods-operator
  - notebooks
  - kserve
  - odh-model-controller
release:
  - "2.25"
  - "3.3"
  - "3.4"
  - "next"
provenance:
  - https://github.com/red-hat-data-services/rhods-operator/tree/rhoai-2.25/internal/webhook/hardwareprofile
author: Luca Burgazzoli
superseded_by: null
---

## Fact

**HardwareProfile** (`infrastructure.opendatahub.io`) is a platform capability that lets administrators define reusable hardware resource templates — CPU, memory, and accelerators (NVIDIA, AMD, Intel Gaudi, IBM Spyre) with min/default/max counts — plus scheduling preferences (Kueue queue-based or node-selector-based). When a workload (Notebook or InferenceService) references a HardwareProfile, the platform automatically injects the declared resources and scheduling constraints at admission time. This capability is GA since RHOAI 2.25 (= RHOAI 3.3) and replaces the deprecated AcceleratorProfile mechanism. It continues through 3.4 and next.

## Impact on Strategies

- Workloads do not self-declare hardware resources; **HardwareProfile** is the authoritative template for resource allocation — strategies involving GPU/accelerator provisioning for Notebooks or InferenceServices should reference HardwareProfile, not manual resource specs
- Two scheduling modes are supported: **Kueue queue assignment** (ties to Kueue integration, see overlay 0007) and **direct node placement** (nodeSelector + tolerations) — strategies should specify which scheduling mode applies to their use case
- Cross-component impact: the capability is implemented in **rhods-operator** but directly affects **notebooks**, **kserve** (InferenceServices), and **odh-model-controller** workloads
- RFEs targeting resource management or accelerator profiles should reference HardwareProfile as the GA replacement for the deprecated AcceleratorProfile
- Version mapping: RHOAI 2.25 = RHOAI 3.3; this capability is present in both versioning schemes and continues through 3.4 and next
- Implementation: mutating webhook in rhods-operator (`/mutate-hardware-profile`)

## Context

The generated architecture docs describe HardwareProfile only within `rhods-operator.md` as an internal implementation detail. Queries by affected component (e.g., "what affects kserve?" or "what affects notebooks?") will not discover HardwareProfile unless rhods-operator is also queried. This overlay surfaces HardwareProfile as a platform-level capability so that strategies touching Notebooks, InferenceServices, or resource scheduling are aware of the declarative resource injection pattern and its cross-component scope.

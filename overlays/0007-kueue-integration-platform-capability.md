---
id: "0007"
title: Kueue integration platform capability for workload queue management
status: active
created: 2026-05-11
affects:
  - platform
  - rhods-operator
  - kueue
  - kuberay
  - kserve
  - notebooks
  - kubeflow
release:
  - "2.25"
  - "3.3"
  - "3.4"
  - "next"
provenance:
  - https://github.com/red-hat-data-services/rhods-operator/tree/rhoai-2.25/internal/webhook/kueue
  - https://github.com/opendatahub-io/opendatahub-operator/pull/3263
author: Luca Burgazzoli
superseded_by: null
---

## Fact

**Kueue integration** is a platform capability that provides fair-share quota management and job queueing for AI/ML workloads. When enabled via DataScienceCluster and configured on namespaces, the platform enforces that all supported workloads — Notebooks, PyTorchJobs, RayJobs, RayClusters, and InferenceServices — carry a queue assignment. This enables hierarchical resource quotas, workload prioritization, and preemption across teams. Kueue itself is installed via the Red Hat build of Kueue Operator. When used together with HardwareProfile (see overlay 0005), queue assignment is automatic via the "Queue" scheduling type. In RHOAI 2.25 / 3.3, queue assignment enforcement is implemented via a validating webhook in rhods-operator; in RHOAI 3.4 and next, the validating webhook has been removed and the platform no longer enforces queue assignment at admission time. This capability is GA since RHOAI 2.25 (= RHOAI 3.3) and continues through 3.4 and next.

## Impact on Strategies

- Broadest component scope of all platform capabilities: spans **notebooks** (Notebooks), distributed training via **kubeflow** (PyTorchJobs), Ray workloads via **kuberay** (RayJobs, RayClusters), and model serving via **kserve** (InferenceServices)
- Three activation requirements must all be satisfied for Kueue scheduling: Kueue enabled in DataScienceCluster, namespace labeled for Kueue management (`kueue.x-k8s.io/managed: "true"`), and workload carrying a queue assignment — in RHOAI 2.25 / 3.3, the platform enforces the queue assignment requirement via validating webhook (workloads without it are rejected); in 3.4 and next, all three are still required for Kueue to schedule the workload, but the platform no longer rejects workloads missing a queue assignment
- The legacy namespace label `odh/kueue-managed: "true"` is still supported but deprecated — new strategies should use the standard `kueue.x-k8s.io/managed` label
- Integrates with **HardwareProfile** (overlay 0005): when a HardwareProfile uses "Queue" scheduling type, queue assignment is injected automatically — strategies should document this dependency chain when both capabilities are active
- The RHOAI-specific enforcement is separate from Kueue's own admission control — the platform provides mandatory queue assignment policy while Kueue handles workload suspension, quota accounting, and fair-share scheduling
- Version mapping: RHOAI 2.25 = RHOAI 3.3; this capability is present in both versioning schemes and continues through 3.4 and next
- Implementation: in RHOAI 2.25 / 3.3, validating webhook in rhods-operator (`/validate-kueue`); removed in 3.4 and next with no replacement — queue assignment is no longer enforced at admission time by the platform

## Context

The generated architecture docs describe Kueue validation in `rhods-operator.md` and Kueue's own webhook infrastructure in `kueue.md`, but the RHOAI-specific enforcement policy and its cross-component scope are not surfaced as a platform-level concern. The five validated workload types span four component boundaries (notebooks, kubeflow, kuberay, kserve), and the integration with HardwareProfile's "Queue" scheduling type creates a cross-cutting admission pipeline. This overlay makes that pipeline visible to strategy and architecture reviewers, ensuring that strategies touching any of the affected workload types in Kueue-managed namespaces account for the queue assignment requirement.

---
id: "0006"
title: Connection API platform capability for data source connectivity
status: active
created: 2026-05-11
affects:
  - platform
  - rhods-operator
  - kserve
  - odh-model-controller
  - notebooks
release:
  - "2.25"
  - "3.3"
  - "3.4"
  - "next"
provenance:
  - https://github.com/red-hat-data-services/rhods-operator/tree/rhoai-2.25/internal/webhook/inferenceservice
  - https://github.com/red-hat-data-services/rhods-operator/tree/rhoai-2.25/internal/webhook/notebook
author: Luca Burgazzoli
superseded_by: null
---

## Fact

The **Connection API** is a platform capability that enables secure, declarative data source connectivity for ML workloads. Administrators and users create Connection Secrets representing S3-compatible object storage, OCI container registries, or URI-based data sources. When a workload (InferenceService or Notebook) references a Connection, the platform automatically injects the appropriate credentials and storage configuration at admission time. For InferenceServices, this means automatic model storage resolution (storage URI, pull secrets, or service account depending on connection type); for Notebooks, it means environment-level credential availability. The platform enforces RBAC — users must have access to the referenced Secret. This capability is GA since RHOAI 2.25 (= RHOAI 3.3) and continues through 3.4 and next.

## Impact on Strategies

- Three connection types exist with different behaviors: **S3** (storage credentials + URI for object storage), **OCI** (image pull secrets for private registries), and **URI** (generic HTTP/HTTPS model sources) — strategies must specify which connection type applies to their use case
- The Connection API decouples credential management from workload specification — strategies should not reference direct Secret mounts or manual storage configuration when a Connection type covers the use case
- RBAC enforcement: the submitting user must have "get" permission on the referenced Secret — strategies involving multi-tenant or restricted namespaces must account for this requirement
- Cross-component impact: the capability is implemented in **rhods-operator** but directly modifies **kserve** InferenceService specs and **notebooks** Notebook specs, and complements the controller-time Secret reconciliation in **odh-model-controller**
- Version mapping: RHOAI 2.25 = RHOAI 3.3; this capability is present in both versioning schemes and continues through 3.4 and next
- Implementation: mutating webhooks in rhods-operator (`/platform-connection-isvc` for InferenceServices, `/platform-connection-notebook` for Notebooks)

## Context

The generated architecture docs mention Connection webhooks in `rhods-operator.md` and `odh-model-controller.md` references `storage-config` Secret reconciliation, but the Connection API as a cohesive platform capability is not surfaced at the platform level. The three connection types, their distinct behaviors, and the RBAC authorization model are implementation details buried in single-component docs. This overlay makes the Connection API visible as a platform capability so that strategies involving model serving, data connections, or workload credential management can reference its behavior and cross-component scope.

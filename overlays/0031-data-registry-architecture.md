---
id: "0031"
title: RHOAI Data Registry cross-component architecture
status: active
created: 2026-10-07
affects:
  - platform
  - feast
  - odh-dashboard
  - rhods-operator
  - kube-rbac-proxy
release:
  - "3.6"
  - "next"
provenance:
  - https://redhat.atlassian.net/browse/RHAI-5715
  - https://gitlab.cee.redhat.com/data-strategy/data-registry-production/-/commit/083e368258d8444216a6a2d606a4e18324dab393
  - https://github.com/opendatahub-io/feast/pull/177
  - https://github.com/opendatahub-io/feast/pull/209
  - https://github.com/opendatahub-io/odh-dashboard/pull/9203
  - https://github.com/opendatahub-io/odh-dashboard/pull/9491
  - https://github.com/opendatahub-io/odh-dashboard/pull/9767
  - https://github.com/opendatahub-io/kube-rbac-proxy/pull/28
author: Brian Gallagher
superseded_by: null
---

## Fact

The **RHOAI Data Registry** is a project-scoped data-asset catalog spanning
the Feast backend, the dashboard's federated React and Go BFF module, and
Kubernetes-delegated authorization. It is a distinct capability from the
Feast Feature Store, Model Registry, and the object storage that holds the
registered data.

The current architecture evidence is split by maturity:

- **[Merged]** The Feast operator can reconcile an annotation-gated,
  dedicated Data Registry workload and persist registry metadata in
  PostgreSQL ([Feast #177](https://github.com/opendatahub-io/feast/pull/177)).
- **[Merged]** The dashboard provides a dedicated Data Registry module image
  containing the federated React assets and Go BFF, and the dashboard
  operator supplies its backend-discovery ConfigMap ([Dashboard #9203](https://github.com/opendatahub-io/odh-dashboard/pull/9203),
  [#9491](https://github.com/opendatahub-io/odh-dashboard/pull/9491),
  [#9767](https://github.com/opendatahub-io/odh-dashboard/pull/9767)).
- **[Planned for 3.6]** Data Registry authorization will extract the project
  from the URL path and use it as the namespace in the Kubernetes authorization
  request. `kube-rbac-proxy` provides the path-derived authorization capability
  ([#28](https://github.com/opendatahub-io/kube-rbac-proxy/pull/28)); the Feast
  deployment will configure it for the Data Registry routes so the project path,
  authorization namespace, and persistence hierarchy remain aligned.
- **[Observed]** The maintained API exposes a partial Iceberg REST
  Catalog-compatible surface and adds RHOAI collections, generic tables,
  volumes, labels, search, and connection references. It does not implement the
  complete Iceberg REST Catalog; several table mutation and load operations
  remain deliberately unsupported in the merged backend subset
  ([Feast #209](https://github.com/opendatahub-io/feast/pull/209)).
- **[Observed/contract]** An asset may optionally carry one structured
  `connection_ref`: either a DCH `DataConnection` UUID
  (`{type: dch, id: <UUID>}`) or an RHOAI Connection Secret name
  (`{type: rhai, secret_name: <name>}`). The registry stores the reference,
  not the underlying credentials. End-to-end runtime validation and released
  user-interface availability for both variants must be verified separately.
- **[In review]** End-to-end DSC capability configuration, Data Registry
  namespace provisioning, and shared operator lifecycle remain dependent on
  the open Feast module-operator work. Treat those transitions as in review,
  not as shipped platform behavior.

## Impact on Strategies

- Model Data Registry as a cross-component capability, not as a standalone
  repository or as an ordinary Feast Feature Store deployment. The principal
  runtime components are `feast`, `odh-dashboard`, PostgreSQL, and
  `kube-rbac-proxy`; the platform and module operators form the control-plane
  path.
- Draw two request paths: dashboard users traverse the federated React module
  and Go BFF, while notebooks, Iceberg clients, and REST clients may call the
  protected backend directly. Backend authorization is therefore required
  even when the dashboard BFF is present.
- Keep the boundaries explicit: the registry stores metadata, locations, and
  one optional structured connection reference; PostgreSQL stores registry
  metadata; the referenced S3/MinIO or other object storage stores the
  physical data; and connection or Secret authorization is separate from
  registry metadata visibility. The registry must not be modeled as a
  credential-vending data plane.
- Treat DCH and RHOAI connections as different integration paths: DCH is
  referenced by a DataConnection UUID, while an RHOAI connection is
  represented by a Secret name. Neither reference shape means that the
  registry owns or returns the connection credentials.
- Treat the RHOAI/OpenShift project as the tenant and authorization boundary.
  The project path, Kubernetes authorization namespace, and persistence
  hierarchy must remain aligned. A registry collection is a grouping beneath
  the project, not the service namespace where the shared workload runs.
- Do not infer complete Iceberg interoperability from the presence of
  Iceberg-shaped routes or the maintained contract. State route-level support
  and client qualification separately, and mark unsupported or unverified
  operations explicitly.
- Treat historical POC manifests and temporary development images as
  background evidence only. They are not architecture-context deployment
  dependencies.

## Context

The generated architecture context already contains separate `feast.md` and
`odh-dashboard.md` documents, but it does not surface the Data Registry's
logical component boundary or its end-to-end request and control-plane flows.
This overlay makes the cross-component architecture discoverable until a
future regeneration incorporates the maintained Data Registry evidence.

The source baseline for this overlay is the Data Registry technical
documentation at commit `083e368258d8444216a6a2d606a4e18324dab393`, inspected
on 2026-10-07. Claims about implementation remain subordinate to the cited
merged code and current PR state.

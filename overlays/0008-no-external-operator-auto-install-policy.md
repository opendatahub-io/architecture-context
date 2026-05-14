---
id: "0008"
title: Platform policy — RHOAI does not auto-install external operator dependencies
status: active
created: 2026-05-14
affects:
  - platform
  - rhods-operator
release:
  - "all"
provenance:
  - https://redhat.atlassian.net/browse/RHAIRFE-2109
  - https://github.com/opendatahub-io/architecture-decision-records/blob/main/architecture-decision-records/ODH-ADR-0007-gitops-repository-openshift-ai-lifecycle.md
  - https://github.com/opendatahub-io/opendatahub-operator/pull/3544
author: Luca Burgazzoli
superseded_by: null
---

## Fact

**RHOAI does not install or manage external operator dependencies on the customer's behalf.** Many RHOAI capabilities depend on optional OpenShift operators (e.g., Cluster Observability Operator, OpenTelemetry, Tempo, Loki), but the platform does not auto-install, upgrade, configure, or remove them. The full lifecycle of these external operators — installation, version selection, configuration, upgrade cadence, and removal — is the cluster administrator's responsibility. The reference GitOps repository (ODH-ADR-0007) provides declarative manifests that administrators can adopt to manage these dependencies through their own GitOps workflow. When an external operator dependency is missing, the platform must surface this clearly on platform-level CRs (DSC and/or DSCI) so that administrators and users understand why a capability is unavailable. The exact placement — DSCI for infrastructure-wide dependencies or DSC for component-scoped dependencies — depends on the nature of the dependency; a single operator may be required by both an infrastructure service (e.g., monitoring) and a component, appearing in both contexts. This policy exists because auto-installing external operators creates day-2 ownership problems: conflicting configuration, divergent upgrade policies, CVE response ambiguity, unclear uninstall semantics, shared-cluster conflicts with other tenants using the same operator, and support-boundary ambiguity between RHOAI and the external operator's lifecycle.

## Impact on Strategies

- Strategies **must not** propose auto-installing, auto-upgrading, or auto-configuring external operators — this is a standing platform policy, not a gap to be closed
- Required external operators must be documented as **prerequisites** with clear installation guidance; the reference GitOps repository (ODH-ADR-0007) is the sanctioned path for dependency lifecycle guidance
- Components must surface missing operator dependencies on platform-level CRs (DSC/DSCI) — the exact placement depends on whether the dependency is infrastructure-wide or component-scoped, and a single operator may appear in both contexts (e.g., COO required by both the monitoring service and a component)
- Shared-cluster scenarios require extra care — external operators may already be installed and configured by other teams or applications unrelated to RHOAI; auto-management would risk breaking those consumers
- Strategies should distinguish between "dependency is missing" (surfaced via status conditions) and "dependency is present but misconfigured" (out of scope for RHOAI to remediate)

## Context

The generated architecture docs do not capture this platform-wide policy. Multiple RFEs (including RHAIRFE-2109) have requested automated lifecycle management for external operator dependencies, and the conversation around these requests consistently reaffirms the same conclusion: auto-install creates more problems than it solves at day-2. This overlay makes the standing policy explicit so that strategy reviewers, architecture agents, and component teams apply it consistently when evaluating proposals that involve external operator dependencies.

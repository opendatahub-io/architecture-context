---
id: "0022"
title: Versioned base LLMInferenceServiceConfig for revision management across RHOAI upgrades
status: active
created: 2026-07-29
affects:
  - kserve
  - odh-model-controller
  - llm-d-inference-scheduler
  - llm-d-router
  - llm-d-kv-cache
release:
  - "3.5"
  - "next"
provenance:
  - https://issues.redhat.com/browse/RHOAIENG-40563
  - https://github.com/opendatahub-io/kserve/pull/999
  - https://github.com/opendatahub-io/opendatahub-operator/pull/2949
author: Pierangelo Di Pilato
superseded_by: null
---

## Fact

The Kserve module operator creates version-stamped base `LLMInferenceServiceConfig` resources named after the RHOAI 
version (e.g., `v3-2-0-kserve-config-llm-decode-template`). When KServe reconciles an `LLMInferenceService`, it resolves
the current version config and persists the versioned config name in `status.annotations`. On RHOAI upgrade, KServe
continues using the pinned version config, and the Operator retains previous version configs (no removal). Customers
upgrade by updating `status.annotations` to the new version or removing annotations entirely to track the latest.

This moves revision management to the backend (KServe + Operator) rather than the Dashboard, avoiding the need to
clone base configs into user namespaces -- which would pollute namespaces and complicate GitOps workflows. It also
prevents automatic runtime upgrades on RHOAI rollout -- existing deployments stay on their pinned config version,
and users decide when to upgrade.

See also: [Overlay 0011](0011-kserve-llm-d-architecture.md) for the full LLMInferenceService and
LLMInferenceServiceConfig architecture, including config inheritance via `spec.baseRefs` and the preset configs
this versioning scheme applies to.

## Impact on Strategies

- Upgrade strategies for RHOAI must account for versioned base configs: the Operator creates new version-stamped
  `LLMInferenceServiceConfig` resources on upgrade but does not remove previous versions, so the system namespace
  accumulates config resources over time.
- GitOps strategies benefit because users no longer need to clone and manage base configs in their namespaces -- the
  version pin lives in `status.annotations` on the `LLMInferenceService` itself.
- The Dashboard no longer needs revision management logic for `LLMInferenceService` (unlike `InferenceService` where
  it clones `ServingRuntime` per instance). Dashboard creates `LLMInferenceService` normally; KServe handles version
  pinning transparently.
- Rollback and canary upgrade strategies are supported: different `LLMInferenceService` instances can reference
  different version configs simultaneously, enabling per-service upgrade sequencing.
- The config preservation hierarchy documented in [Overlay 0011](0011-kserve-llm-d-architecture.md)
  (`preserveSchedulerConfig()`) interacts with versioned configs -- the version pin determines which base config is
  used, while the preservation hierarchy determines how scheduler customizations survive within that version.

## Context

The generated architecture docs describe `LLMInferenceServiceConfig` as a static configuration template
(`spec.baseRefs`). They do not capture the version-stamped naming convention, the Operator's responsibility for
creating and retaining versioned configs across upgrades, or the `status.annotations` mechanism that pins an
`LLMInferenceService` to a specific config version. This overlay captures the revision management design before it
lands in the codebase.
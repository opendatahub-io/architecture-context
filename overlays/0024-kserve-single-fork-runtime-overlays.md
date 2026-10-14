---
id: "0024"
title: KServe uses a single downstream fork on all platforms, not separate builds
status: active
created: 2026-08-07
affects:
  - kserve
release:
  - "all"
provenance:
  - https://github.com/opendatahub-io/opendatahub-operator/blob/main/build/manifests-config.yaml
  - https://github.com/opendatahub-io/opendatahub-operator/blob/main/internal/controller/components/kserve/kserve.go
  - https://github.com/opendatahub-io/opendatahub-operator/blob/main/internal/controller/components/kserve/kserve_controller_actions.go
  - https://github.com/opendatahub-io/opendatahub-operator/blob/main/pkg/cluster/const.go
author: Kyle Lape
superseded_by: null
---

## Fact

There is no separate "upstream" or "non-distro" KServe build. Both OpenShift and XKS (EKS, AKS, CoreWeave) use the same downstream red-hat-data-services/kserve fork and the same operator image. On XKS, a Helm chart deploys the RHOAI operator, which then selects between internal kustomize manifest paths (`overlays/odh` for OpenShift, `overlays/odh-xks` for XKS) at runtime based on `ODH_PLATFORM_TYPE`. The Go `distro` build tag exists in the KServe source but does not produce a separate deployable artifact.

## Impact on Strategies

* Do not reference an "upstream" or "non-distro" KServe build as a deployment target for EKS or any other platform
* When describing platform differences, reference the runtime overlay selection, not separate builds
* The deployment mechanism differs (OLM on OpenShift, Helm chart on XKS) but the KServe image is the same

## Context

The generated architecture docs describe the `distro` vs `!distro` Go build tags in KServe source, which the strategy pipeline interpreted as separate build artifacts for different platforms. In practice, the product ships a single image from the downstream fork and the operator selects the correct kustomize overlay at runtime.

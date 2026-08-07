---
id: "0019"
title: kgateway is not a supported Gateway API implementation on OpenShift
status: active
created: 2026-08-07
affects:
  - llm-d
  - llm-d-inference-scheduler
  - llm-d-router
  - kserve
release:
  - "all"
provenance: []
author: Kyle Lape
superseded_by: null
---

## Fact

The llm-d repo ships kustomize recipes for kgateway (`guides/recipes/gateway/kgateway/` and `guides/recipes/gateway/kgateway-openshift/`) and the llm-d-inference-scheduler has a dev overlay (`deploy/environments/dev/kubernetes-kgateway/`). These are development/experimental configurations only. kgateway is not a supported or validated Gateway API implementation on OpenShift. Istio is the only supported GatewayClass provider on OpenShift.

## Impact on Strategies

* Do not list kgateway as a supported gateway option on any platform
* When describing the OpenShift gateway stack, reference Istio only
* The existence of kustomize recipes for kgateway does not indicate support status

## Context

The generated architecture docs for llm-d list kgateway as a distribution variant alongside Istio, including an OpenShift-specific variant. This led the strategy pipeline to state "On OpenShift, Istio or kgateway provides the GatewayClass," implying kgateway is a supported option. The presence of kustomize recipes does not indicate support status.

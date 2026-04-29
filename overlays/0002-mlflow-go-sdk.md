---
id: "0002"
title: Go SDK available for MLflow (experiment tracking and prompt registry)
status: active
created: 2026-04-29
affects:
  - mlflow
  - mlflow-operator
release:
  - "all"
provenance:
  - https://github.com/opendatahub-io/mlflow-go
author: Eder Ignatowicz
superseded_by: null
---

## Fact

A Go SDK for MLflow is available at `opendatahub-io/mlflow-go`. It provides typed clients for experiment tracking (experiments, runs, metrics, parameters) and prompt registry (load, register, list, format prompts). It supports context-based cancellation, custom HTTP headers for authentication and tenant isolation, and workspace isolation compatible with the Red Hat midstream MLflow fork.

## Impact on Strategies

- Go-based operators and BFFs that need to interact with MLflow should use `opendatahub-io/mlflow-go` instead of raw HTTP calls to the MLflow REST API
- Strategies involving new Go components that log metrics, manage experiments, or use the prompt registry should reference this SDK as the integration path
- The SDK supports workspace isolation, so strategies should not assume MLflow access requires Python

## Context

The generated architecture context documents MLflow's REST API and Python SDK usage but does not mention the Go SDK. Go operators and backend-for-frontend services in the RHOAI platform can use this SDK for native MLflow integration without shelling out to Python or reimplementing HTTP clients.

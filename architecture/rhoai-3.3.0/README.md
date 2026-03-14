# RHOAI 3.3.0 - Component Architectures

Generated from: checkouts/red-hat-data-services.rhoai-3.3
Platform version from: checkouts/red-hat-data-services.rhoai-3.3/rhods-operator
Date: 2026-03-13

## Components

| Component Repository | Architecture File |
|----------------------|-------------------|
| data-science-pipelines-operator | [data-science-pipelines-operator.md](./data-science-pipelines-operator.md) |
| feast | [feast.md](./feast.md) |
| kserve | [kserve.md](./kserve.md) |
| kubeflow | [kubeflow.md](./kubeflow.md) |
| kuberay | [kuberay.md](./kuberay.md) |
| llama-stack-k8s-operator | [llama-stack-k8s-operator.md](./llama-stack-k8s-operator.md) |
| mlflow-operator | [mlflow-operator.md](./mlflow-operator.md) |
| model-registry-operator | [model-registry-operator.md](./model-registry-operator.md) |
| notebooks | [notebooks.md](./notebooks.md) |
| odh-dashboard | [odh-dashboard.md](./odh-dashboard.md) |
| odh-model-controller | [odh-model-controller.md](./odh-model-controller.md) |
| trainer | [trainer.md](./trainer.md) |
| training-operator | [training-operator.md](./training-operator.md) |
| trustyai-service-operator | [trustyai-service-operator.md](./trustyai-service-operator.md) |

## Summary

- **Platform**: RHOAI
- **Version**: 3.3.0
- **Components**: 14
- **Source**: checkouts/red-hat-data-services.rhoai-3.3

## Using These Files

These are individual component architecture summaries. To create a platform-level view:

```bash
/aggregate-platform-architecture --distribution=rhoai --version=3.3.0
```

To generate diagrams from a component:

```bash
/generate-architecture-diagrams --architecture=./odh-dashboard.md
```

# ODH 3.3.0 - Component Architectures

Generated from: checkouts/opendatahub-io
Platform version from: checkouts/opendatahub-io/opendatahub-operator
Date: 2026-03-12

## Components

| Component Repository | Architecture File |
|----------------------|-------------------|
| data-science-pipelines-operator | [data-science-pipelines-operator.md](./data-science-pipelines-operator.md) |
| feast | [feast.md](./feast.md) |
| kserve | [kserve.md](./kserve.md) |
| kubeflow | [kubeflow.md](./kubeflow.md) |
| kuberay | [kuberay.md](./kuberay.md) |
| llama-stack-k8s-operator | [llama-stack-k8s-operator.md](./llama-stack-k8s-operator.md) |
| mlflow | [mlflow.md](./mlflow.md) |
| mlflow-operator | [mlflow-operator.md](./mlflow-operator.md) |
| model-registry-operator | [model-registry-operator.md](./model-registry-operator.md) |
| notebooks | [notebooks.md](./notebooks.md) |
| odh-dashboard | [odh-dashboard.md](./odh-dashboard.md) |
| odh-model-controller | [odh-model-controller.md](./odh-model-controller.md) |
| opendatahub-operator | [opendatahub-operator.md](./opendatahub-operator.md) |
| spark-operator | [spark-operator.md](./spark-operator.md) |
| trainer | [trainer.md](./trainer.md) |
| training-operator | [training-operator.md](./training-operator.md) |
| trustyai-service-operator | [trustyai-service-operator.md](./trustyai-service-operator.md) |

## Summary

- **Platform**: ODH
- **Version**: 3.3.0
- **Components**: 17
- **Source**: checkouts/opendatahub-io

## Using These Files

These are individual component architecture summaries. To create a platform-level view:

```bash
/aggregate-platform-architecture --distribution=odh --version=3.3.0
```

To generate diagrams from a component:

```bash
/generate-architecture-diagrams --architecture=./kubeflow.md
```

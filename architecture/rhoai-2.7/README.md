# RHOAI 2.7 - Component Architectures

Generated from: checkouts/red-hat-data-services.rhoai-2.7
Platform version from: checkouts/red-hat-data-services.rhoai-2.7/rhods-operator
Date: 2026-03-15

## Components

| Component Repository | Architecture File |
|----------------------|-------------------|
| codeflare-operator | [codeflare-operator.md](./codeflare-operator.md) |
| data-science-pipelines-operator | [data-science-pipelines-operator.md](./data-science-pipelines-operator.md) |
| kserve | [kserve.md](./kserve.md) |
| kubeflow | [kubeflow.md](./kubeflow.md) |
| kuberay | [kuberay.md](./kuberay.md) |
| modelmesh-serving | [modelmesh-serving.md](./modelmesh-serving.md) |
| notebooks | [notebooks.md](./notebooks.md) |
| odh-model-controller | [odh-model-controller.md](./odh-model-controller.md) |
| rhods-operator | [rhods-operator.md](./rhods-operator.md) |
| trustyai-service-operator | [trustyai-service-operator.md](./trustyai-service-operator.md) |

## Summary

- **Platform**: RHOAI
- **Version**: 2.7
- **Components**: 10
- **Source**: checkouts/red-hat-data-services.rhoai-2.7

## Using These Files

These are individual component architecture summaries. To create a platform-level view:

```bash
/aggregate-platform-architecture --distribution=rhoai --version=2.7
```

To generate diagrams from a component:

```bash
/generate-architecture-diagrams --architecture=./kubeflow.md
```

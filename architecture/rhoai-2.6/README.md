# RHOAI 2.6 - Component Architectures

Generated from: checkouts/red-hat-data-services.rhoai-2.6
Platform version from: checkouts/red-hat-data-services.rhoai-2.6/rhods-operator
Date: 2026-03-20

## Components

| Component Repository | Architecture File |
|----------------------|-------------------|
| caikit-tgis-serving | [caikit-tgis-serving.md](./caikit-tgis-serving.md) |
| codeflare-operator | [codeflare-operator.md](./codeflare-operator.md) |
| data-science-pipelines | [data-science-pipelines.md](./data-science-pipelines.md) |
| data-science-pipelines-operator | [data-science-pipelines-operator.md](./data-science-pipelines-operator.md) |
| data-science-pipelines-tekton | [data-science-pipelines-tekton.md](./data-science-pipelines-tekton.md) |
| kf-poc-rhods-operator | [kf-poc-rhods-operator.md](./kf-poc-rhods-operator.md) |
| kserve | [kserve.md](./kserve.md) |
| kubeflow | [kubeflow.md](./kubeflow.md) |
| kuberay | [kuberay.md](./kuberay.md) |
| modelmesh | [modelmesh.md](./modelmesh.md) |
| modelmesh-runtime-adapter | [modelmesh-runtime-adapter.md](./modelmesh-runtime-adapter.md) |
| modelmesh-serving | [modelmesh-serving.md](./modelmesh-serving.md) |
| notebooks | [notebooks.md](./notebooks.md) |
| notebooks-downstream-z-test | [notebooks-downstream-z-test.md](./notebooks-downstream-z-test.md) |
| odh-dashboard | [odh-dashboard.md](./odh-dashboard.md) |
| odh-manifests | [odh-manifests.md](./odh-manifests.md) |
| odh-model-controller | [odh-model-controller.md](./odh-model-controller.md) |
| rest-proxy | [rest-proxy.md](./rest-proxy.md) |
| rhods-operator | [rhods-operator.md](./rhods-operator.md) |
| text-generation-inference | [text-generation-inference.md](./text-generation-inference.md) |
| trustyai-explainability | [trustyai-explainability.md](./trustyai-explainability.md) |
| trustyai-service-operator | [trustyai-service-operator.md](./trustyai-service-operator.md) |

## Summary

- **Platform**: RHOAI
- **Version**: 2.6
- **Components**: 22
- **Source**: checkouts/red-hat-data-services.rhoai-2.6

## Using These Files

These are individual component architecture summaries. To create a platform-level view:

```bash
/aggregate-platform-architecture --distribution=rhoai --version=2.6
```

To generate diagrams from a component:

```bash
/generate-architecture-diagrams --architecture=./odh-manifests.md
```

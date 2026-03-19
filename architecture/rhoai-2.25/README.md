# RHOAI 2.25 - Component Architectures

Generated from: checkouts/red-hat-data-services.rhoai-2.25
Platform version from: checkouts/red-hat-data-services.rhoai-2.25/rhods-operator
Date: 2026-03-18

## Components

| Component Repository | Architecture File |
|----------------------|-------------------|
| RHOAI-Build-Config | [RHOAI-Build-Config.md](./RHOAI-Build-Config.md) |
| argo-workflows | [argo-workflows.md](./argo-workflows.md) |
| caikit-nlp | [caikit-nlp.md](./caikit-nlp.md) |
| caikit-tgis-serving | [caikit-tgis-serving.md](./caikit-tgis-serving.md) |
| codeflare-operator | [codeflare-operator.md](./codeflare-operator.md) |
| data-science-pipelines | [data-science-pipelines.md](./data-science-pipelines.md) |
| data-science-pipelines-operator | [data-science-pipelines-operator.md](./data-science-pipelines-operator.md) |
| data-science-pipelines-tekton | [data-science-pipelines-tekton.md](./data-science-pipelines-tekton.md) |
| distributed-workloads | [distributed-workloads.md](./distributed-workloads.md) |
| feast | [feast.md](./feast.md) |
| fms-guardrails-orchestrator | [fms-guardrails-orchestrator.md](./fms-guardrails-orchestrator.md) |
| guardrails-detectors | [guardrails-detectors.md](./guardrails-detectors.md) |
| guardrails-regex-detector | [guardrails-regex-detector.md](./guardrails-regex-detector.md) |
| ilab-on-ocp | [ilab-on-ocp.md](./ilab-on-ocp.md) |
| kserve | [kserve.md](./kserve.md) |
| kubeflow | [kubeflow.md](./kubeflow.md) |
| kuberay | [kuberay.md](./kuberay.md) |
| kueue | [kueue.md](./kueue.md) |
| llama-stack-k8s-operator | [llama-stack-k8s-operator.md](./llama-stack-k8s-operator.md) |
| llama-stack-provider-ragas | [llama-stack-provider-ragas.md](./llama-stack-provider-ragas.md) |
| llama-stack-provider-trustyai-garak | [llama-stack-provider-trustyai-garak.md](./llama-stack-provider-trustyai-garak.md) |
| llm-d-inference-scheduler | [llm-d-inference-scheduler.md](./llm-d-inference-scheduler.md) |
| llm-d-routing-sidecar | [llm-d-routing-sidecar.md](./llm-d-routing-sidecar.md) |
| lm-evaluation-harness | [lm-evaluation-harness.md](./lm-evaluation-harness.md) |
| ml-metadata | [ml-metadata.md](./ml-metadata.md) |
| model-metadata-collection | [model-metadata-collection.md](./model-metadata-collection.md) |
| model-registry | [model-registry.md](./model-registry.md) |
| model-registry-operator | [model-registry-operator.md](./model-registry-operator.md) |
| modelmesh | [modelmesh.md](./modelmesh.md) |
| modelmesh-runtime-adapter | [modelmesh-runtime-adapter.md](./modelmesh-runtime-adapter.md) |
| modelmesh-serving | [modelmesh-serving.md](./modelmesh-serving.md) |
| notebooks | [notebooks.md](./notebooks.md) |
| odh-dashboard | [odh-dashboard.md](./odh-dashboard.md) |
| odh-model-controller | [odh-model-controller.md](./odh-model-controller.md) |
| openvino_model_server | [openvino_model_server.md](./openvino_model_server.md) |
| rest-proxy | [rest-proxy.md](./rest-proxy.md) |
| rhods-operator | [rhods-operator.md](./rhods-operator.md) |
| text-generation-inference | [text-generation-inference.md](./text-generation-inference.md) |
| training-operator | [training-operator.md](./training-operator.md) |
| trustyai-explainability | [trustyai-explainability.md](./trustyai-explainability.md) |
| trustyai-service-operator | [trustyai-service-operator.md](./trustyai-service-operator.md) |
| vllm | [vllm.md](./vllm.md) |
| vllm-cpu | [vllm-cpu.md](./vllm-cpu.md) |
| vllm-gaudi | [vllm-gaudi.md](./vllm-gaudi.md) |
| vllm-orchestrator-gateway | [vllm-orchestrator-gateway.md](./vllm-orchestrator-gateway.md) |
| vllm-rocm | [vllm-rocm.md](./vllm-rocm.md) |

## Summary

- **Platform**: RHOAI
- **Version**: 2.25
- **Components**: 46
- **Source**: checkouts/red-hat-data-services.rhoai-2.25

## Using These Files

These are individual component architecture summaries. To create a platform-level view:

```bash
/aggregate-platform-architecture --distribution=rhoai --version=2.25
```

To generate diagrams from a component:

```bash
/generate-architecture-diagrams --architecture=./odh-dashboard.md
```

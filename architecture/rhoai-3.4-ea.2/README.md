# RHOAI 3.4-ea.2 - Component Architectures

Generated from: checkouts/red-hat-data-services.rhoai-3.4-ea.2
Platform version from: checkouts/red-hat-data-services.rhoai-3.4-ea.2/rhods-operator
Date: 2026-03-18

## Components

| Component Repository | Architecture File |
|----------------------|-------------------|
| MLServer | [MLServer.md](./MLServer.md) |
| NeMo-Guardrails | [NeMo-Guardrails.md](./NeMo-Guardrails.md) |
| RHOAI-Build-Config | [RHOAI-Build-Config.md](./RHOAI-Build-Config.md) |
| argo-workflows | [argo-workflows.md](./argo-workflows.md) |
| batch-gateway | [batch-gateway.md](./batch-gateway.md) |
| data-science-pipelines | [data-science-pipelines.md](./data-science-pipelines.md) |
| data-science-pipelines-operator | [data-science-pipelines-operator.md](./data-science-pipelines-operator.md) |
| distributed-workloads | [distributed-workloads.md](./distributed-workloads.md) |
| eval-hub | [eval-hub.md](./eval-hub.md) |
| feast | [feast.md](./feast.md) |
| fms-guardrails-orchestrator | [fms-guardrails-orchestrator.md](./fms-guardrails-orchestrator.md) |
| guardrails-detectors | [guardrails-detectors.md](./guardrails-detectors.md) |
| guardrails-regex-detector | [guardrails-regex-detector.md](./guardrails-regex-detector.md) |
| kserve | [kserve.md](./kserve.md) |
| kube-auth-proxy | [kube-auth-proxy.md](./kube-auth-proxy.md) |
| kubeflow | [kubeflow.md](./kubeflow.md) |
| kuberay | [kuberay.md](./kuberay.md) |
| llama-stack-distribution | [llama-stack-distribution.md](./llama-stack-distribution.md) |
| llama-stack-k8s-operator | [llama-stack-k8s-operator.md](./llama-stack-k8s-operator.md) |
| llama-stack-provider-ragas | [llama-stack-provider-ragas.md](./llama-stack-provider-ragas.md) |
| llama-stack-provider-trustyai-garak | [llama-stack-provider-trustyai-garak.md](./llama-stack-provider-trustyai-garak.md) |
| llm-d-inference-scheduler | [llm-d-inference-scheduler.md](./llm-d-inference-scheduler.md) |
| llm-d-kv-cache | [llm-d-kv-cache.md](./llm-d-kv-cache.md) |
| lm-evaluation-harness | [lm-evaluation-harness.md](./lm-evaluation-harness.md) |
| ml-metadata | [ml-metadata.md](./ml-metadata.md) |
| mlflow | [mlflow.md](./mlflow.md) |
| mlflow-operator | [mlflow-operator.md](./mlflow-operator.md) |
| model-metadata-collection | [model-metadata-collection.md](./model-metadata-collection.md) |
| model-registry | [model-registry.md](./model-registry.md) |
| model-registry-operator | [model-registry-operator.md](./model-registry-operator.md) |
| models-as-a-service | [models-as-a-service.md](./models-as-a-service.md) |
| notebooks | [notebooks.md](./notebooks.md) |
| odh-dashboard | [odh-dashboard.md](./odh-dashboard.md) |
| odh-model-controller | [odh-model-controller.md](./odh-model-controller.md) |
| openvino_model_server | [openvino_model_server.md](./openvino_model_server.md) |
| rhods-operator | [rhods-operator.md](./rhods-operator.md) |
| spark-operator | [spark-operator.md](./spark-operator.md) |
| trainer | [trainer.md](./trainer.md) |
| training-operator | [training-operator.md](./training-operator.md) |
| trustyai-explainability | [trustyai-explainability.md](./trustyai-explainability.md) |
| trustyai-service-operator | [trustyai-service-operator.md](./trustyai-service-operator.md) |
| vllm-cpu | [vllm-cpu.md](./vllm-cpu.md) |
| vllm-gaudi | [vllm-gaudi.md](./vllm-gaudi.md) |
| vllm-orchestrator-gateway | [vllm-orchestrator-gateway.md](./vllm-orchestrator-gateway.md) |
| workload-variant-autoscaler | [workload-variant-autoscaler.md](./workload-variant-autoscaler.md) |

## Summary

- **Platform**: RHOAI
- **Version**: 3.4-ea.2
- **Components**: 45
- **Source**: checkouts/red-hat-data-services.rhoai-3.4-ea.2

## Using These Files

These are individual component architecture summaries. To create a platform-level view:

```bash
/aggregate-platform-architecture --distribution=rhoai --version=3.4-ea.2
```

To generate diagrams from a component:

```bash
/generate-architecture-diagrams --architecture=./odh-dashboard.md
```

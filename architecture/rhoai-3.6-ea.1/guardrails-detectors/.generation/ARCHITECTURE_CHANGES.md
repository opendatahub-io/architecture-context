# Architecture Changes: guardrails-detectors

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | vLLM inference server :: HTTP client | * | <empty> | <empty> | LLM Judge detector delegates content evaluation to external vLLM server via VLLM_BASE_URL env var using vllm-judge HTTP client | detectors/llm_judge/detector.py:25-37, detectors/llm_judge/deploy/servingruntime.yaml:34-35 |
| add | integration_points | KServe :: ServingRuntime | * | <empty> | <empty> | Both detector types are packaged as KServe ServingRuntime definitions for deployment in the model serving infrastructure | detectors/llm_judge/deploy/servingruntime.yaml:1-4, detectors/huggingface/deploy/servingruntime.yaml:1 |
| add | internal_dependencies | KServe | * | <empty> | <empty> | Detectors are deployed as KServe ServingRuntimes (serving.kserve.io/v1alpha1) as the primary deployment mechanism | detectors/llm_judge/deploy/servingruntime.yaml:1, detectors/huggingface/deploy/servingruntime.yaml:1 |
| add | internal_dependencies | vLLM inference service | * | <empty> | <empty> | LLM Judge detector requires a running vLLM predictor service for content evaluation | detectors/llm_judge/detector.py:25-28, detectors/llm_judge/deploy/servingruntime.yaml:34-35 |
| add | internal_dependencies | MinIO | * | <empty> | <empty> | HuggingFace detector loads models from MinIO object storage via S3-compatible data connection secret | detectors/huggingface/deploy/model_container.yaml:1, detectors/huggingface/deploy/model_container.yaml:94-117 |

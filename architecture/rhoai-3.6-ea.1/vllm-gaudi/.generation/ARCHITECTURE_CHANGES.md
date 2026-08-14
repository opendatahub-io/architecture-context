# Architecture Changes: vllm-gaudi

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | OpenAI-compatible API :: All | * | <empty> | <empty> | vLLM server supports optional API key authentication via --api-key flag; authentication is delegated to upstream vLLM and platform | Dockerfile.konflux.gaudi:244, vllm_gaudi/__init__.py:6-8 |
| add | integration_points | vLLM (upstream) :: Python package | * | <empty> | <empty> | Upstream vLLM is installed at build time as the inference engine framework providing the OpenAI-compatible API server | Dockerfile.konflux.gaudi:206-213 |
| add | integration_points | Intel Gaudi Runtime (SynapseAI) :: System library | * | <empty> | <empty> | Habana SynapseAI runtime provides HPU driver and kernel execution via habana_frameworks.torch | Dockerfile.konflux.gaudi:7-8, vllm_gaudi/platform.py:7 |
| add | integration_points | Ray :: Python package | * | <empty> | <empty> | Ray provides distributed compute orchestration for multi-HPU inference | requirements.txt:2 |
| add | integration_points | Hugging Face Transformers :: Python package | * | <empty> | <empty> | Transformers library provides tokenizer and model weight loading | requirements.txt:6 |
| add | internal_dependencies | KServe | * | <empty> | <empty> | Platform deploys this image as a KServe ServingRuntime; runtime definition is external to this repo | Dockerfile.konflux.gaudi:246-253 |

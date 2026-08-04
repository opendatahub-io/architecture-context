# Architecture Changes: vllm-gaudi

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | vLLM (upstream) :: build-time install | * | <empty> | <empty> | vLLM upstream is cloned and installed as the core inference engine providing the OpenAI-compatible API server | Dockerfile.konflux.gaudi:194-217 |
| add | integration_points | Intel Gaudi SynapseAI :: build-time install | * | <empty> | <empty> | Habana SynapseAI drivers and runtime libraries are installed from Intel artifact repository | Dockerfile.konflux.gaudi:94-127 |
| add | integration_points | PyTorch (Habana) :: build-time install | * | <empty> | <empty> | PyTorch for Gaudi is installed from Habana artifact storage for HPU compute support | Dockerfile.konflux.gaudi:154-166 |

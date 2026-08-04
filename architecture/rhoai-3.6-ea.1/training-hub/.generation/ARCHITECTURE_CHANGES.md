# Architecture Changes: training-hub

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | LLM Inference API :: All | * | <empty> | <empty> | GEPA algorithm authenticates outbound LLM API calls via OPENAI_API_KEY env var through litellm client | src/training_hub/algorithms/gepa.py:64-71 |
| add | integration_points | MLflow Tracking Server :: library-call | * | <empty> | <empty> | MLflowGEPABackend integrates with MLflow tracking server for prompt optimization experiment tracking and prompt registry | src/training_hub/algorithms/gepa.py:150-174 |
| add | integration_points | LLM Inference API :: library-call | * | <empty> | <empty> | GEPA algorithm connects to external LLM inference API via litellm using OPENAI_API_BASE env var for prompt optimization | src/training_hub/algorithms/gepa.py:62-71 |
| add | integration_points | vLLM Engine :: library-call | * | <empty> | <empty> | ART GRPO backend co-locates vLLM inference engine in-process for rollout generation during RL training | src/training_hub/algorithms/lora_grpo.py:60-77 |
| add | internal_dependencies | instructlab-training | * | <empty> | <empty> | SFT backend imports and delegates to instructlab.training.run_training for supervised fine-tuning execution | src/training_hub/algorithms/sft.py:3-8 |
| add | internal_dependencies | rhai-innovation-mini-trainer | * | <empty> | <empty> | OSFT backend delegates to rhai-innovation-mini-trainer for orthogonal subspace fine-tuning | pyproject.toml:18 |

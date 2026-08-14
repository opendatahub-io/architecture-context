# Architecture Changes: training_hub

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | instructlab-training | * | <empty> | <empty> | SFT backend imports and delegates training execution to instructlab-training run_training() and TrainingArgs | src/training_hub/algorithms/sft.py:2-7 |
| add | internal_dependencies | rhai-innovation-mini-trainer | * | <empty> | <empty> | OSFT backend delegates training execution to rhai-innovation-mini-trainer | src/training_hub/algorithms/osft.py:3 |
| add | integration_points | OpenAI-compatible LLM endpoints :: HTTP client (via litellm) | * | <empty> | <empty> | GEPA algorithm sets OPENAI_API_BASE and OPENAI_API_KEY environment variables for litellm outbound inference calls | src/training_hub/algorithms/gepa.py:63-71 |
| add | integration_points | MLflow Tracking Server :: HTTP client (via mlflow SDK) | * | <empty> | <empty> | MLflowGEPABackend imports and calls mlflow.genai.optimize_prompts() for experiment tracking and prompt registry | src/training_hub/algorithms/gepa.py:173-174 |

workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Trains and fine-tunes LLM models using Training Hub API or CLI"

        trainingHub = softwareSystem "Training Hub" "Algorithm-focused Python library and CLI providing unified interface across multiple LLM training backends for SFT, RL, prompt optimization, and embedding fine-tuning" {
            cli = container "thub CLI" "Command-line interface with YAML config support, lazy algorithm imports, dotted-path callable resolution" "Python Console Script"
            registry = container "AlgorithmRegistry" "Central dispatch mapping algorithm names to Algorithm classes and backends (Strategy + Registry pattern)" "Python Module"
            callbackFramework = container "TrainingHubCallback" "Unified lifecycle hooks (9 hooks) bridged to each backend's native callback system with subprocess serialization support" "Python Module"

            sftBackend = container "SFT Backend" "Supervised fine-tuning via InstructLab Training with torchrun for multi-GPU/multi-node" "Python + torchrun"
            osftBackend = container "OSFT Backend" "Orthogonal Subspace Fine-Tuning for continual learning via Mini-Trainer" "Python + torchrun"
            loraSftBackend = container "LoRA SFT Backend" "Parameter-efficient LoRA/QLoRA fine-tuning via Unsloth with multi-GPU DDP" "Python + Unsloth"
            artGrpoBackend = container "ART GRPO Backend" "Single-GPU LoRA + GRPO via ART/OpenPipe with vLLM time-sharing in spawned subprocess" "Python + vLLM"
            verlGrpoBackend = container "verl GRPO Backend" "Multi-GPU distributed LoRA/full GRPO via FSDP + vLLM rollout generation" "Python + verl + Ray"
            gepaBackend = container "GEPA Backend" "Gradient-free evolutionary prompt optimization via LLM API calls (no GPU)" "Python + litellm"
            embeddingBackend = container "Embedding SFT Backend" "Contrastive fine-tuning for embedding models using sentence-transformers" "Python + sentence-transformers"
            estimators = container "VRAM Estimators" "Analytical GPU VRAM estimation for various training methods" "Python"
        }

        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        llmApi = softwareSystem "OpenAI-Compatible LLM API" "LLM inference for GEPA optimization and GRPO rollouts" "External"
        wandb = softwareSystem "Weights & Biases" "Experiment tracking and visualization" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and prompt registry" "External"
        kubeflow = softwareSystem "Kubeflow" "ML pipeline orchestration with progress tracking" "Internal Platform"
        pypi = softwareSystem "PyPI" "Python package distribution with Sigstore signing" "External"

        dataScientist -> trainingHub "Trains models via Python API or thub CLI"
        dataScientist -> cli "Runs training via thub sft/osft/lora-sft/lora-grpo/gepa/embedding-sft"

        cli -> registry "Dispatches to algorithm via lazy imports"
        registry -> sftBackend "Routes SFT requests"
        registry -> osftBackend "Routes OSFT requests"
        registry -> loraSftBackend "Routes LoRA SFT requests"
        registry -> artGrpoBackend "Routes single-GPU GRPO requests"
        registry -> verlGrpoBackend "Routes distributed GRPO requests"
        registry -> gepaBackend "Routes prompt optimization requests"
        registry -> embeddingBackend "Routes embedding fine-tuning requests"

        callbackFramework -> sftBackend "Provides lifecycle hooks"
        callbackFramework -> osftBackend "Provides lifecycle hooks"
        callbackFramework -> loraSftBackend "Provides lifecycle hooks"
        callbackFramework -> artGrpoBackend "Provides lifecycle hooks"
        callbackFramework -> verlGrpoBackend "Provides lifecycle hooks"
        callbackFramework -> embeddingBackend "Provides lifecycle hooks"

        trainingHub -> huggingFaceHub "Downloads models and datasets" "HTTPS/443, Bearer HF_TOKEN"
        gepaBackend -> llmApi "Task evaluation and reflection mutations" "HTTPS/443, Bearer OPENAI_API_KEY"
        trainingHub -> wandb "Experiment tracking (optional)" "HTTPS/443, API Key"
        gepaBackend -> mlflow "Prompt registry integration (optional)" "HTTPS, Token"
        trainingHub -> kubeflow "Progress tracking via training_metrics.jsonl" "Filesystem"
        trainingHub -> pypi "Published as training-hub package" "HTTPS/443, Sigstore"
    }

    views {
        systemContext trainingHub "SystemContext" {
            include *
            autoLayout
        }

        container trainingHub "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

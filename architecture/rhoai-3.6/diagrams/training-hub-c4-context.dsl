workspace {
    model {
        user = person "ML Engineer / Data Scientist" "Runs LLM training jobs using Training Hub API or CLI"

        trainingHub = softwareSystem "Training Hub" "Unified Python library and CLI for LLM training algorithms with pluggable backends" {
            pythonAPI = container "Python API" "Convenience functions: sft(), osft(), lora_sft(), lora_grpo(), grpo(), gepa(), embedding_sft()" "Python 3.11+"
            cli = container "thub CLI" "Command-line interface with YAML config and subcommands" "Python console_script"
            registry = container "AlgorithmRegistry" "Strategy + Registry pattern mapping algorithm names to classes and backends" "Python"
            callbacks = container "TrainingHubCallback" "Unified callback system with per-backend adapters" "Python"
            jitCheckpoint = container "JIT Checkpoint" "SIGTERM-based preemption checkpointing with cross-rank coordination" "Python + torch.distributed"
            checkpointManager = container "Checkpoint Manager" "Background LIFO upload worker with hardlink staging and fsspec" "Python"
            memoryEstimator = container "GPU Memory Estimator" "VRAM estimation for SFT, OSFT, LoRA, QLoRA training runs" "Python"
            visualization = container "Training Visualization" "Training loss curve plotting with EMA smoothing" "Python + matplotlib"
        }

        instructlabTraining = softwareSystem "InstructLab Training" "SFT backend (torchrun)" "External"
        miniTrainer = softwareSystem "Mini-Trainer" "OSFT backend (torchrun)" "External"
        unsloth = softwareSystem "Unsloth" "Efficient LoRA training" "External"
        openPipeART = softwareSystem "OpenPipe ART" "Single-GPU GRPO backend (vLLM + Unsloth)" "External"
        verl = softwareSystem "verl" "Multi-GPU distributed GRPO (FSDP + vLLM)" "External"
        gepaLib = softwareSystem "gepa Library" "Gradient-free prompt optimization" "External"
        sentenceTransformers = softwareSystem "sentence-transformers" "Contrastive embedding fine-tuning" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset registry" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Remote checkpoint mirroring and restore" "External"
        openaiAPI = softwareSystem "OpenAI-Compatible API" "LLM inference for GEPA prompt optimization" "External"
        wandb = softwareSystem "Weights & Biases" "Experiment tracking (optional)" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking (optional)" "External"
        volcano = softwareSystem "Volcano Scheduler" "Multi-node job scheduling for verl backend" "Internal RHOAI"

        user -> trainingHub "Runs training via Python API or thub CLI"
        trainingHub -> instructlabTraining "Delegates SFT training" "Python API + torchrun"
        trainingHub -> miniTrainer "Delegates OSFT training" "Python API + torchrun"
        trainingHub -> unsloth "Delegates LoRA SFT training" "Python API"
        trainingHub -> openPipeART "Delegates single-GPU GRPO" "Spawned subprocess"
        trainingHub -> verl "Delegates multi-GPU GRPO" "torchrun + Hydra CLI"
        trainingHub -> gepaLib "Delegates prompt optimization" "Python API"
        trainingHub -> sentenceTransformers "Delegates embedding fine-tuning" "Python API"
        trainingHub -> huggingfaceHub "Downloads models and datasets" "HTTPS/443"
        trainingHub -> s3Storage "Mirrors and restores checkpoints" "HTTPS/443 (S3 API)"
        trainingHub -> openaiAPI "Evaluates prompts for GEPA" "HTTPS/443"
        trainingHub -> wandb "Reports experiment metrics" "HTTPS/443"
        trainingHub -> mlflow "Reports experiment metrics" "HTTP(S)"
        verl -> volcano "Schedules multi-node training jobs" "Kubernetes API"
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
            element "Internal RHOAI" {
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

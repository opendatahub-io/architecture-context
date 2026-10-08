workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Configures and launches training jobs via Python API or thub CLI"

        trainingHub = softwareSystem "Training Hub" "Algorithm-focused Python library providing a unified interface for LLM training, continual learning, reinforcement learning, prompt optimization, and embedding fine-tuning" {
            cli = container "thub CLI" "Command-line interface with 7 subcommands, YAML config support" "Python console_script"
            registry = container "AlgorithmRegistry" "Strategy + Registry pattern mapping algorithm names to classes and backends" "Python Module"
            sftBackend = container "SFT Backend" "Supervised Fine-Tuning via InstructLab Training with torchrun" "Python Module"
            osftBackend = container "OSFT Backend" "Orthogonal Subspace Fine-Tuning via Mini-Trainer" "Python Module"
            loraSftBackend = container "LoRA SFT Backend" "Parameter-efficient fine-tuning via Unsloth with QLoRA" "Python Module"
            artGrpoBackend = container "ART GRPO Backend" "Single-GPU LoRA + GRPO via OpenPipe ART with co-located vLLM" "Python Module"
            verlGrpoBackend = container "verl GRPO Backend" "Multi-GPU GRPO with FSDP + vLLM via torchrun" "Python Module"
            gepaBackend = container "GEPA Backend" "Gradient-free prompt optimization using evolutionary search" "Python Module"
            embeddingBackend = container "Embedding SFT Backend" "Contrastive embedding fine-tuning via sentence-transformers" "Python Module"
            callbackSystem = container "Callback System" "Unified lifecycle hooks across backends with torchrun-safe serialization" "Python Module"
            checkpointManager = container "Checkpoint Manager" "Remote checkpoint mirroring and restore via fsspec" "Python Module"
            jitCheckpoint = container "JIT Checkpoint" "SIGTERM-based preemption checkpointing for graceful pod shutdown" "Python Module"
        }

        # External Systems
        instructlabTraining = softwareSystem "InstructLab Training" "SFT training library" "External"
        miniTrainer = softwareSystem "RHAI Innovation Mini-Trainer" "OSFT training library for continual learning" "External"
        unsloth = softwareSystem "Unsloth" "Optimized LoRA training with 2x speedup" "External"
        openPipeArt = softwareSystem "OpenPipe ART" "Single-GPU GRPO framework" "External"
        verl = softwareSystem "verl" "Multi-GPU GRPO with FSDP" "External"
        vllm = softwareSystem "vLLM" "LLM inference engine for GRPO rollouts" "External"
        gepaLib = softwareSystem "gepa Library" "Genetic-Pareto prompt optimization" "External"
        litellm = softwareSystem "litellm" "Multi-provider LLM API client" "External"
        sentenceTransformers = softwareSystem "sentence-transformers" "Contrastive embedding training" "External"

        # External Services
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External Service"
        llmApiEndpoints = softwareSystem "LLM API Endpoints" "OpenAI / vLLM compatible APIs for GEPA" "External Service"
        s3Storage = softwareSystem "S3-compatible Storage" "Remote checkpoint storage" "External Service"
        mlflowServer = softwareSystem "MLflow Server" "Experiment tracking and prompt registry" "External Service"
        wandb = softwareSystem "Weights & Biases" "Optional experiment logging" "External Service"

        # Internal Platform
        kubeflow = softwareSystem "Kubeflow Training" "Orchestrates training jobs on Kubernetes" "Internal RHOAI"
        volcano = softwareSystem "Volcano" "Multi-node job scheduling" "Internal RHOAI"

        # Relationships
        user -> trainingHub "Configures and runs training" "Python API / CLI"
        kubeflow -> trainingHub "Invokes training algorithms" "Python API"

        trainingHub -> instructlabTraining "SFT training" "In-process"
        trainingHub -> miniTrainer "OSFT training" "In-process"
        trainingHub -> unsloth "LoRA training" "In-process"
        trainingHub -> openPipeArt "GRPO training" "Spawned subprocess"
        trainingHub -> verl "GRPO training" "torchrun / NCCL"
        trainingHub -> vllm "Inference rollouts" "In-process"
        trainingHub -> gepaLib "Prompt optimization" "In-process"
        trainingHub -> litellm "LLM API routing" "In-process"
        trainingHub -> sentenceTransformers "Embedding training" "In-process"

        trainingHub -> huggingfaceHub "Downloads models and datasets" "HTTPS/443"
        trainingHub -> llmApiEndpoints "GEPA prompt optimization" "HTTPS/443"
        trainingHub -> s3Storage "Remote checkpoint mirroring" "HTTPS/443"
        trainingHub -> mlflowServer "Experiment tracking" "HTTP/HTTPS"
        trainingHub -> wandb "Experiment logging" "HTTPS/443"

        trainingHub -> kubeflow "Reports progress" "training_metrics.jsonl"
        trainingHub -> volcano "References for scheduling" "Resource reference"
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
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}

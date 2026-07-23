workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs LLM training workflows"
        mlEngineer = person "ML Engineer" "Builds training pipelines using Training Hub API"
        codingAgent = person "AI Coding Agent" "Claude Code / Codex CLI invoking training via plugin"

        trainingHub = softwareSystem "Training Hub" "Unified Algorithm + Backend abstraction for LLM fine-tuning, RL, and prompt optimization" {
            algorithmFramework = container "Algorithm + Backend Framework" "Core abstraction with AlgorithmRegistry, Algorithm ABC, Backend ABC" "Python Library"
            sftAlgorithm = container "SFT Algorithm" "Supervised Fine-Tuning via InstructLab Training" "Python Module"
            osftAlgorithm = container "OSFT Algorithm" "Orthogonal Subspace Fine-Tuning via Mini-Trainer" "Python Module"
            loraSftAlgorithm = container "LoRA + SFT Algorithm" "Parameter-efficient LoRA/QLoRA via Unsloth" "Python Module"
            loraGrpoAlgorithm = container "LoRA + GRPO Algorithm" "RL fine-tuning via ART (single-GPU) or verl (multi-GPU)" "Python Module"
            gepaAlgorithm = container "GEPA Algorithm" "Gradient-free evolutionary prompt optimization" "Python Module"
            memoryEstimator = container "Memory Estimator" "GPU memory profiling for training configurations" "Python Module"
            visualization = container "Visualization" "Training loss curve plotting" "Python Module"
            rewardFunctions = container "Reward Functions" "Tool-call verification and binary rewards for GRPO" "Python Module"
            itsRollout = container "ITS Rollout Adapter" "BestOfN, BeamSearch sampling strategies for GRPO" "Python Module"
        }

        # External training framework dependencies
        instructlabTraining = softwareSystem "InstructLab Training" "Training framework for SFT with torchrun support" "External Library"
        miniTrainer = softwareSystem "Mini-Trainer" "Training framework for OSFT with subspace unfreezing" "External Library"
        unsloth = softwareSystem "Unsloth" "Optimized LoRA/QLoRA training with FastModel" "External Library"
        openpipeArt = softwareSystem "OpenPipe ART" "Single-GPU GRPO with vLLM time-sharing" "External Library"
        verl = softwareSystem "verl" "Multi-GPU distributed GRPO via FSDP" "External Library"
        gepaLib = softwareSystem "GEPA" "Gradient-free evolutionary prompt optimization engine" "External Library"

        # Infrastructure dependencies
        pytorch = softwareSystem "PyTorch" "Deep learning framework with torchrun distributed training" "External Infrastructure"
        ray = softwareSystem "Ray" "Distributed compute framework for verl backend" "External Infrastructure"
        vllm = softwareSystem "vLLM" "High-throughput LLM inference engine for GRPO rollouts" "External Infrastructure"

        # External services
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset registry" "External Service"
        mlflow = softwareSystem "MLflow" "Experiment tracking and prompt registry" "External Service"
        wandb = softwareSystem "Weights & Biases" "Training metrics logging platform" "External Service"
        llmApi = softwareSystem "LLM API" "External LLM for GEPA judge/mutator (via litellm)" "External Service"

        # Consuming systems
        rhoaiPipelines = softwareSystem "RHOAI Training Pipelines" "Upstream pipeline orchestration that imports Training Hub" "Internal RHOAI"

        # Relationships - Users
        dataScientist -> trainingHub "Invokes training_hub.sft(), lora_grpo(), gepa()" "Python API"
        mlEngineer -> trainingHub "Integrates into training pipelines" "Python API"
        codingAgent -> trainingHub "Invokes training via plugin manifests" "Claude Code / Codex Plugin"

        # Relationships - Internal containers
        algorithmFramework -> sftAlgorithm "creates via registry"
        algorithmFramework -> osftAlgorithm "creates via registry"
        algorithmFramework -> loraSftAlgorithm "creates via registry"
        algorithmFramework -> loraGrpoAlgorithm "creates via registry"
        algorithmFramework -> gepaAlgorithm "creates via registry"
        loraGrpoAlgorithm -> rewardFunctions "evaluates rewards"
        loraGrpoAlgorithm -> itsRollout "sampling strategies"

        # Relationships - Backend delegations
        sftAlgorithm -> instructlabTraining "delegates training" "Python import"
        osftAlgorithm -> miniTrainer "delegates training" "Python import"
        loraSftAlgorithm -> unsloth "delegates training" "Python import"
        loraGrpoAlgorithm -> openpipeArt "ART backend (single-GPU)" "Python import"
        loraGrpoAlgorithm -> verl "verl backend (multi-GPU)" "Subprocess"
        gepaAlgorithm -> gepaLib "delegates optimization" "Python import"

        # Relationships - Infrastructure
        sftAlgorithm -> pytorch "torchrun distributed training" "TCP (NCCL/Gloo)"
        verl -> ray "distributed compute" "TCP"
        loraGrpoAlgorithm -> vllm "rollout generation" "In-process / TCP"

        # Relationships - External services
        trainingHub -> huggingfaceHub "Downloads models and datasets" "HTTPS/443"
        gepaAlgorithm -> llmApi "Judge/mutator LLM calls" "HTTPS"
        gepaAlgorithm -> mlflow "Prompt registry, experiment logging" "HTTP/HTTPS"
        trainingHub -> wandb "Training metrics logging (optional)" "HTTPS/443"

        # Relationships - Consuming systems
        rhoaiPipelines -> trainingHub "imports as Python library" "pip install training-hub"
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
            element "External Library" {
                background #999999
                color #ffffff
            }
            element "External Infrastructure" {
                background #775555
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
            element "Person" {
                shape person
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

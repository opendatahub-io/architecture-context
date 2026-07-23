workspace {
    model {
        dataScientist = person "Data Scientist" "Fine-tunes and trains LLMs using notebooks or scripts"
        mlEngineer = person "ML Engineer" "Builds training pipelines using Training Hub APIs"

        trainingHub = softwareSystem "Training Hub" "Algorithm-focused Python library for LLM fine-tuning, continual learning, and reinforcement learning" {
            algorithmLayer = container "Algorithm Layer" "Defines training semantics: SFT, OSFT, LoRA, GRPO, GEPA" "Python Module"
            backendLayer = container "Backend Layer" "Executes training against specific engines (instructlab-training, Unsloth, ART, verl, gepa)" "Python Module"
            registry = container "Algorithm-Backend Registry" "Factory pattern connecting algorithms to their backend implementations" "Python Module"
            profiling = container "Profiling Module" "Analytical GPU memory estimation for capacity planning" "Python Module"
            visualization = container "Visualization Module" "Multi-run training loss curve plotting" "Python Module"
            rewards = container "Reward Functions" "Tool-call and binary reward functions for RLVR training" "Python Module"
        }

        instructlabTraining = softwareSystem "instructlab-training" "SFT backend engine for distributed training via torchrun" "External"
        miniTrainer = softwareSystem "rhai-innovation-mini-trainer" "OSFT backend engine for orthogonal subspace fine-tuning" "External"
        unsloth = softwareSystem "Unsloth" "Optimized LoRA backend with fused GPU kernels" "External"
        artOpenPipe = softwareSystem "OpenPipe ART" "GRPO backend for RL via subprocess with vLLM rollouts" "External"
        verl = softwareSystem "verl (Volcano Engine RL)" "GRPO backend for FSDP multi-GPU reinforcement learning" "External"
        gepaEngine = softwareSystem "gepa" "Genetic-Pareto prompt optimization engine" "External"

        vllm = softwareSystem "vLLM" "High-throughput LLM inference server for GRPO rollout generation" "Internal RHOAI"
        itsHub = softwareSystem "ITS Hub" "Generation algorithm adapter for GRPO rollouts" "Internal RHOAI"

        pytorch = softwareSystem "PyTorch" "Deep learning framework, distributed training via torchrun" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloading model configs and weights" "External"
        wandb = softwareSystem "Weights & Biases" "Experiment tracking and visualization" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and GEPA prompt optimization" "External"
        llmProviders = softwareSystem "LLM API Providers" "Reward model inference via litellm abstraction" "External"

        # User interactions
        dataScientist -> trainingHub "Calls Python API from notebooks" "Python"
        mlEngineer -> trainingHub "Integrates into training pipelines" "Python"

        # Internal flows
        algorithmLayer -> registry "Registers algorithms"
        registry -> backendLayer "Resolves and delegates to backends"

        # Backend engine dependencies
        backendLayer -> instructlabTraining "Delegates SFT training" "Python import"
        backendLayer -> miniTrainer "Delegates OSFT training" "Python import"
        backendLayer -> unsloth "Delegates LoRA training" "Python import"
        backendLayer -> artOpenPipe "Launches GRPO training" "subprocess"
        backendLayer -> verl "Launches FSDP GRPO training" "subprocess"
        backendLayer -> gepaEngine "Delegates prompt optimization" "Python import"

        # Platform integrations
        backendLayer -> vllm "Starts inference server for rollouts" "subprocess/HTTP"
        algorithmLayer -> itsHub "Wraps generation algorithms as rollout functions" "Python import"

        # External service integrations
        backendLayer -> pytorch "Distributed training via torchrun" "NCCL/Gloo"
        profiling -> huggingface "Downloads model configs" "HTTPS/443"
        backendLayer -> wandb "Logs training metrics" "HTTPS/443"
        backendLayer -> mlflow "Logs experiments, GEPA optimization" "HTTPS/443"
        backendLayer -> llmProviders "Reward model evaluation" "HTTPS/443"
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

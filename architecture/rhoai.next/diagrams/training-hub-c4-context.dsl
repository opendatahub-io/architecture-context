workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Writes training scripts using training-hub to fine-tune LLMs"

        trainingHub = softwareSystem "training-hub" "Algorithm-focused Python SDK providing unified interface for LLM fine-tuning (SFT, OSFT, LoRA, GRPO)" {
            algorithmFramework = container "Algorithm Framework" "Abstract Algorithm/Backend/Registry pattern for pluggable algorithm-backend composition" "Python ABC"
            sftAlgorithm = container "SFT Algorithm" "Supervised Fine-Tuning via instructlab-training backend" "Python Module"
            osftAlgorithm = container "OSFT Algorithm" "Orthogonal Subspace Fine-Tuning via mini-trainer backend" "Python Module"
            loraSftAlgorithm = container "LoRA+SFT Algorithm" "Parameter-efficient SFT via Unsloth backend (QLoRA, DoRA, RSLoRA)" "Python Module"
            loraGrpoAlgorithm = container "LoRA+GRPO Algorithm" "Reinforcement learning from verifiable rewards via ART or verl backends" "Python Module"
            grpoAlgorithm = container "GRPO Algorithm" "Full fine-tuning GRPO via verl backend" "Python Module"
            peftExtender = container "PEFT Extender" "Composable parameter-efficient fine-tuning parameter definitions" "Python ABC"
            profilingModule = container "Profiling Module" "GPU memory estimation (Basic, OSFT, LoRA, QLoRA estimators) and timing estimation" "Python Module"
            visualizationModule = container "Visualization Module" "Training loss curve plotting with EMA smoothing and multi-run comparison" "Python Module"
            rewardFunctions = container "Reward Functions" "tool_call_reward and binary_reward for GRPO training" "Python Module"
        }

        instructlabTraining = softwareSystem "instructlab-training" "SFT backend: torchrun-based distributed training and data preprocessing" "Internal"
        miniTrainer = softwareSystem "rhai-innovation-mini-trainer" "OSFT backend: orthogonal subspace training engine with SVD decomposition" "Internal"
        unsloth = softwareSystem "Unsloth" "Optimized LoRA backend: FastModel/FastLanguageModel with VLM support" "External"
        openPipeART = softwareSystem "OpenPipe ART" "Single-GPU GRPO backend: co-located vLLM inference + LoRA training" "External"
        verl = softwareSystem "verl" "Multi-GPU distributed GRPO backend: FSDP + vLLM rollout workers" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework: DDP/FSDP distributed training, NCCL" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Pre-trained model weights and tokenizer repository" "External"
        wandb = softwareSystem "WandB" "Experiment tracking and metrics visualization" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and model registry" "External"
        gpuCluster = softwareSystem "GPU Cluster" "NVIDIA GPU infrastructure for model training (NCCL communication)" "Infrastructure"

        # User interactions
        dataScientist -> trainingHub "Imports and calls training functions" "Python API"

        # Algorithm-Backend wiring
        algorithmFramework -> sftAlgorithm "Registers and instantiates"
        algorithmFramework -> osftAlgorithm "Registers and instantiates"
        algorithmFramework -> loraSftAlgorithm "Registers and instantiates"
        algorithmFramework -> loraGrpoAlgorithm "Registers and instantiates"
        algorithmFramework -> grpoAlgorithm "Registers and instantiates"
        peftExtender -> loraSftAlgorithm "Composes LoRA params with"
        peftExtender -> loraGrpoAlgorithm "Composes LoRA params with"

        # Backend delegations
        sftAlgorithm -> instructlabTraining "Delegates training execution" "Python import"
        osftAlgorithm -> miniTrainer "Delegates training execution" "Python import"
        loraSftAlgorithm -> unsloth "Delegates LoRA training" "Python import"
        loraGrpoAlgorithm -> openPipeART "Delegates single-GPU GRPO" "Subprocess"
        loraGrpoAlgorithm -> verl "Delegates multi-GPU GRPO" "Subprocess"
        grpoAlgorithm -> verl "Delegates full fine-tuning GRPO" "Subprocess"

        # External connections
        trainingHub -> huggingfaceHub "Downloads model weights and tokenizers" "HTTPS/443"
        trainingHub -> wandb "Uploads experiment metrics" "HTTPS/443"
        trainingHub -> mlflow "Uploads experiment metrics" "HTTPS"
        trainingHub -> gpuCluster "Distributed training coordination" "TCP/NCCL"
        instructlabTraining -> pytorch "Uses for distributed training" "In-process"
        verl -> pytorch "Uses for FSDP training" "In-process"
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
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
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

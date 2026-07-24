workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Fine-tunes LLMs using training-hub library via Python scripts or notebooks"

        trainingHub = softwareSystem "training-hub" "Unified Python library providing consistent API for fine-tuning LLMs using multiple training algorithms (SFT, OSFT, LoRA, GRPO) with pluggable backends" {
            publicAPI = container "Public API" "Entry points: sft(), osft(), lora_sft(), lora_grpo(), grpo(), estimate(), plot_loss()" "Python Module"
            algorithmRegistry = container "Algorithm Registry" "Dynamic registration and factory creation of algorithm-backend pairs" "Python Module"

            sftAlgorithm = container "SFT Algorithm" "Full-parameter Supervised Fine-Tuning with torchrun orchestration" "Python Module"
            osftAlgorithm = container "OSFT Algorithm" "Orthogonal Subspace Fine-Tuning with SVD-based parameter selection" "Python Module"
            loraSFTAlgorithm = container "LoRA+SFT Algorithm" "Parameter-efficient LoRA fine-tuning with quantization and VLM support" "Python Module"
            loraGRPOAlgorithm = container "LoRA+GRPO Algorithm" "Group Relative Policy Optimization with LoRA adapters" "Python Module"
            grpoAlgorithm = container "GRPO Algorithm" "Full fine-tuning GRPO (lora_r=0) for reinforcement learning" "Python Module"

            memoryEstimator = container "Memory Estimator" "GPU memory profiling for SFT, OSFT, LoRA, QLoRA" "Python Module"
            visualization = container "Visualization" "Training loss curve plotting with multi-run comparison and EMA smoothing" "Python Module"
            rewardFunctions = container "Reward Functions" "Tool-call verification and binary threshold rewards for GRPO" "Python Module"
            torchrunUtils = container "Distributed Training Utils" "torchrun parameter resolution with hierarchical precedence" "Python Module"
        }

        instructlabTraining = softwareSystem "instructlab-training" "SFT training execution backend and data processing" "Internal Platform"
        miniTrainer = softwareSystem "rhai-innovation-mini-trainer" "OSFT training execution backend" "Internal Platform"
        unsloth = softwareSystem "Unsloth" "LoRA model loading and PEFT configuration backend" "External"
        openPipeART = softwareSystem "OpenPipe ART" "GRPO training orchestration via CLI subprocess" "External"
        verl = softwareSystem "verl" "GRPO training with FSDP via CLI subprocess" "External"
        vllm = softwareSystem "vLLM" "Inference server for rollout generation during GRPO training" "External"

        pytorch = softwareSystem "PyTorch" "Core deep learning framework with torchrun distributed training" "External"
        transformers = softwareSystem "HuggingFace Transformers" "Model loading, tokenization, trainer infrastructure" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset downloads" "External"

        wandb = softwareSystem "Weights & Biases" "Experiment tracking and metric logging (optional)" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and metric logging (optional)" "External"
        tensorboard = softwareSystem "TensorBoard" "Experiment tracking via log files (optional)" "External"

        gpuCluster = softwareSystem "GPU Cluster" "Multi-GPU/multi-node training via NCCL/NVLink" "Infrastructure"

        # Relationships - User
        dataScientist -> trainingHub "Fine-tunes models using" "pip install training-hub / Python API"

        # Relationships - Public API to Algorithms
        publicAPI -> algorithmRegistry "Creates algorithm instances via"
        algorithmRegistry -> sftAlgorithm "Instantiates"
        algorithmRegistry -> osftAlgorithm "Instantiates"
        algorithmRegistry -> loraSFTAlgorithm "Instantiates"
        algorithmRegistry -> loraGRPOAlgorithm "Instantiates"
        algorithmRegistry -> grpoAlgorithm "Instantiates"

        # Relationships - Algorithms to Backends
        sftAlgorithm -> instructlabTraining "Executes training via" "Python API"
        osftAlgorithm -> miniTrainer "Executes training via" "Python API"
        loraSFTAlgorithm -> unsloth "Loads LoRA models via" "Python API"
        loraGRPOAlgorithm -> openPipeART "Orchestrates GRPO via" "CLI subprocess"
        loraGRPOAlgorithm -> verl "Orchestrates GRPO via" "CLI subprocess"
        grpoAlgorithm -> verl "Orchestrates GRPO via" "CLI subprocess"

        # Relationships - Distributed Training
        sftAlgorithm -> torchrunUtils "Resolves distributed params"
        osftAlgorithm -> torchrunUtils "Resolves distributed params"
        torchrunUtils -> pytorch "Launches distributed training via" "torchrun/TCP"
        pytorch -> gpuCluster "Trains across GPUs via" "NCCL (NVLink/PCIe)"
        verl -> gpuCluster "FSDP training via" "NCCL"
        verl -> vllm "Starts for rollout generation" "subprocess/TCP"
        openPipeART -> vllm "Starts for rollout generation" "subprocess/TCP"

        # Relationships - GRPO rewards
        loraGRPOAlgorithm -> rewardFunctions "Uses reward functions"
        grpoAlgorithm -> rewardFunctions "Uses reward functions"

        # Relationships - Utilities
        publicAPI -> memoryEstimator "Estimates GPU memory"
        publicAPI -> visualization "Plots training loss"
        memoryEstimator -> huggingfaceHub "Fetches model config" "HTTPS/443"

        # Relationships - External Services
        trainingHub -> huggingfaceHub "Downloads models and datasets" "HTTPS/443 TLS 1.2+"
        trainingHub -> wandb "Logs metrics (auto-detected)" "HTTPS/443 TLS 1.2+"
        trainingHub -> mlflow "Logs metrics (auto-detected)" "HTTP(S)"
        trainingHub -> tensorboard "Writes log files" "Filesystem"
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
            element "Infrastructure" {
                background #f5a623
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

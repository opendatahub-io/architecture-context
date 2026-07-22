workspace {
    model {
        dataScientist = person "Data Scientist" "Configures and launches fine-tuning jobs for large language models"
        mlEngineer = person "ML Engineer" "Manages training infrastructure and monitors training runs"

        fmsHfTuning = softwareSystem "fms-hf-tuning" "Python library and container image for fine-tuning LLMs using HF SFTTrainer with PyTorch FSDP" {
            accelerateLaunch = container "accelerate_launch.py" "Container entry point; parses config, wraps accelerate launch for multi-GPU FSDP training" "Python Entry Point"
            sftTrainer = container "tuning.sft_trainer" "Core training orchestrator; loads models, tokenizers, data, runs SFT training via HF SFTTrainer" "Python Module"
            dataPipeline = container "tuning.data" "Data preprocessing pipeline with pluggable handlers for tokenization, chat templates, vision data" "Python Package"
            configLayer = container "tuning.config" "Configuration dataclasses for model args, data args, training args, PEFT configs, acceleration configs" "Python Package"
            trainerController = container "tuning.trainercontroller" "Rule-based training loop control for early stopping and custom metrics" "Python Package"
            trackers = container "tuning.trackers" "Pluggable experiment tracking (file, AimStack, MLflow, ClearML)" "Python Package"
        }

        kubeflowTrainingOperator = softwareSystem "Kubeflow Training Operator" "Orchestrates distributed training jobs via PyTorchJob CRD" "Internal Platform"
        kueue = softwareSystem "Kueue" "Queue management for Kubernetes batch workloads" "Internal Platform"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Repository for pre-trained models, tokenizers, and datasets" "External"
        fmsAcceleration = softwareSystem "fms-acceleration" "Optional acceleration framework for QLoRA, fused ops, padding-free attention, ScatterMoE" "External"
        aimStack = softwareSystem "AimStack" "Experiment tracking and visualization server" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking, model registry, and deployment platform" "External"
        clearml = softwareSystem "ClearML" "Experiment management and MLOps platform" "External"
        vllm = softwareSystem "vLLM" "High-throughput LLM inference engine (downstream consumer of LoRA adapters)" "External"
        pytorchFSDP = softwareSystem "PyTorch FSDP" "Fully Sharded Data Parallel for distributed training" "External"
        objectStorage = softwareSystem "Object Storage / PVC" "Storage for model checkpoints, LoRA adapters, and training outputs" "External"

        # Relationships
        dataScientist -> kubeflowTrainingOperator "Submits PyTorchJob CR via kubectl/API"
        mlEngineer -> kubeflowTrainingOperator "Monitors and manages training jobs"
        kubeflowTrainingOperator -> fmsHfTuning "Creates PyTorchJob pods running fms-hf-tuning container" "K8s API / mTLS"
        kueue -> kubeflowTrainingOperator "Manages queue scheduling for training jobs" "K8s API"
        fmsHfTuning -> huggingFaceHub "Downloads pre-trained models and datasets" "HTTPS/443"
        fmsHfTuning -> fmsAcceleration "Uses optional acceleration plugins" "Python API"
        fmsHfTuning -> aimStack "Sends experiment metrics" "HTTP"
        fmsHfTuning -> mlflow "Sends experiment metrics" "HTTP/HTTPS"
        fmsHfTuning -> clearml "Sends experiment metrics" "HTTPS"
        fmsHfTuning -> pytorchFSDP "Distributed gradient synchronization" "TCP/29500 NCCL"
        fmsHfTuning -> objectStorage "Saves model checkpoints and LoRA adapters" "Filesystem"
        fmsHfTuning -> vllm "Produces vLLM-compatible LoRA adapters (new_embeddings.safetensors)" "File output"

        # Internal container relationships
        accelerateLaunch -> sftTrainer "Launches training via accelerate" "Python subprocess"
        sftTrainer -> dataPipeline "Preprocesses training data" "Python API"
        sftTrainer -> configLayer "Reads training configuration" "Python API"
        sftTrainer -> trainerController "Evaluates training loop rules" "Python callback"
        sftTrainer -> trackers "Logs training metrics" "Python API"
    }

    views {
        systemContext fmsHfTuning "SystemContext" {
            include *
            autoLayout
        }

        container fmsHfTuning "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

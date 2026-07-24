workspace {
    model {
        dataScientist = person "Data Scientist" "Creates training configurations and submits fine-tuning jobs"
        mlEngineer = person "ML Engineer" "Manages training infrastructure and monitors experiments"

        fmsHfTuning = softwareSystem "fms-hf-tuning" "Production-ready framework for supervised fine-tuning (SFT) of large language models using HF Transformers, PEFT, and PyTorch FSDP" {
            accelerateLauncher = container "accelerate_launch.py" "Container entrypoint that wraps accelerate launch for multi-GPU training with automatic FSDP configuration" "Python Entrypoint"
            sftTrainer = container "SFT Trainer" "Core SFT training engine — model loading, PEFT config, data preprocessing, SFTTrainer orchestration, and model saving" "Python / HF SFTTrainer"
            dataPreprocessor = container "Data Preprocessing Pipeline" "Dataset loading, format detection (pretokenized/single-seq/chat/vision), chat templates, tokenization, multimodal processing, ODM" "Python Module"
            configSystem = container "Configuration System" "Configuration dataclasses for model, data, training, PEFT, quantization, and acceleration framework parameters" "Python Dataclasses"
            trackerFramework = container "Experiment Trackers" "Pluggable experiment tracking — file logging, AimStack, MLflow, ClearML, HF Resource Scanner" "Python Plugin Framework"
            trainerController = container "Trainer Controller" "User-defined YAML rules and metrics to control the training loop (early stopping, dynamic scaling)" "Python Callbacks"
            accelerationFramework = container "Acceleration Framework" "Quantized LoRA, fused ops, padding-free flash attention, multipack, ScatterMoE, ODM" "fms-acceleration Plugins"
        }

        kfto = softwareSystem "Kubeflow Training Operator" "Orchestrates distributed training jobs as PyTorchJob custom resources" "Internal Platform"
        kueue = softwareSystem "Kueue" "Optional queue management for training job scheduling" "Internal Platform"
        hfHub = softwareSystem "Hugging Face Hub" "Hosts pre-trained models and datasets" "External"
        aimStack = softwareSystem "AimStack" "Experiment tracking and visualization server" "External"
        mlflow = softwareSystem "MLflow" "ML experiment tracking, model registry" "External"
        clearml = softwareSystem "ClearML" "Experiment management and automation" "External"
        pvc = softwareSystem "Persistent Volume" "NFS/CSI storage for model artifacts, training data, and outputs" "Infrastructure"
        gpu = softwareSystem "GPU Infrastructure" "NVIDIA GPUs with CUDA 12.1 for model training" "Infrastructure"

        # Person relationships
        dataScientist -> fmsHfTuning "Submits training config via JSON (env var or mounted file)"
        mlEngineer -> kfto "Creates PyTorchJob CRs"
        mlEngineer -> mlflow "Monitors training metrics"

        # System relationships
        kfto -> fmsHfTuning "Creates Pod(s) with training config"
        kueue -> kfto "Queue management for job scheduling"
        fmsHfTuning -> hfHub "Downloads pre-trained models and datasets" "HTTPS/443"
        fmsHfTuning -> aimStack "Reports experiment metrics" "HTTP/configurable"
        fmsHfTuning -> mlflow "Reports experiment metrics" "HTTP or HTTPS/configurable"
        fmsHfTuning -> clearml "Reports experiment metrics" "HTTPS/configurable"
        fmsHfTuning -> pvc "Reads training data, writes model artifacts" "Filesystem"
        fmsHfTuning -> gpu "Runs training computations" "CUDA/NCCL"

        # Container relationships
        accelerateLauncher -> sftTrainer "Launches training via accelerate launch"
        sftTrainer -> dataPreprocessor "Preprocesses datasets"
        sftTrainer -> configSystem "Reads training configuration"
        sftTrainer -> trackerFramework "Reports training metrics"
        sftTrainer -> trainerController "Evaluates training loop rules"
        sftTrainer -> accelerationFramework "Loads acceleration plugins"
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
                background #4a90e2
                color #ffffff
                shape person
            }
        }
    }
}

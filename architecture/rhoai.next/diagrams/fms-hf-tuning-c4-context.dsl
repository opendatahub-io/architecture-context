workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and fine-tunes large language models using SFT"
        mlEngineer = person "ML Engineer" "Configures distributed training jobs and monitors experiments"

        fmsHfTuning = softwareSystem "FMS HF Tuning" "Production-ready fine-tuning framework for LLMs using HuggingFace Transformers, TRL, and PyTorch FSDP" {
            accelerateLaunch = container "accelerate_launch.py" "Container entry point: JSON config parsing, multi-GPU auto-detection, FSDP defaults, vLLM post-processing" "Python CLI"
            sftTrainer = container "sft_trainer.py" "Core training orchestration: model loading, tokenization, dataset preparation, SFTTrainer initialization, model saving" "Python Library"
            dataModule = container "Data Module" "Configurable data preprocessing pipeline: JSON/JSONL/Arrow/Parquet, chat templates, vision data, online data mixing" "Python Library"
            configModule = container "Config Module" "Hierarchical dataclass-based configuration for model, data, training, PEFT, acceleration, and tracker settings" "Python Library"
            trackersModule = container "Trackers Module" "Pluggable experiment tracking: Aim, MLflow, ClearML, HFResourceScanner, file-based JSONL logging" "Python Library"
            trainerController = container "Trainer Controller" "Rule-driven training loop control using simpleeval for safe expression evaluation" "Python Library"
            sumLossTrainer = container "Sum Loss SFT Trainer" "Custom SFTTrainer with sum-based loss reduction for consistent token weighting" "Python Library"
            fmsRecommender = container "FMS Recommender" "Configuration optimization tool using FMSAdapter for optimized launch commands" "Python CLI"
        }

        kfto = softwareSystem "Kubeflow Training Operator" "Orchestrates distributed training jobs on Kubernetes via PyTorchJob CR" "Internal Platform"
        kueue = softwareSystem "Kueue" "Queue-based scheduling for training jobs, prevents GPU resource contention" "Internal Platform"
        hfHub = softwareSystem "HuggingFace Hub" "Model and dataset registry for downloading pre-trained models and tokenizers" "External"
        hfDatasets = softwareSystem "HuggingFace Datasets" "Dataset registry for downloading training and validation datasets" "External"
        mlflowServer = softwareSystem "MLflow Server" "Experiment tracking server for logging training metrics and run metadata" "External"
        aimServer = softwareSystem "Aim Server" "Experiment tracking server for metrics and experiment metadata" "External"
        clearmlServer = softwareSystem "ClearML Server" "Task management and experiment tracking server" "External"
        fmsAcceleration = softwareSystem "FMS Acceleration Framework" "Hardware-optimized training plugins: QLoRA, fused LoRA, padding-free, ScatterMoE, ODM" "External Library"
        nvidiaGpu = softwareSystem "NVIDIA GPU" "GPU compute via CUDA 12.1, cuDNN 9.6, NCCL 2.18.3" "Hardware"
        pvStorage = softwareSystem "Persistent Volume Storage" "Input data, output models, and cached model storage" "Infrastructure"
        vllm = softwareSystem "vLLM" "Inference engine consuming LoRA adapter checkpoints (safetensors)" "Internal Platform"

        # User relationships
        dataScientist -> fmsHfTuning "Submits fine-tuning jobs via PyTorchJob YAML"
        mlEngineer -> fmsHfTuning "Configures training parameters and monitors experiments"

        # Internal container relationships
        accelerateLaunch -> sftTrainer "Initializes training" "In-process"
        accelerateLaunch -> configModule "Reads JSON config" "In-process"
        sftTrainer -> dataModule "Processes training data" "In-process"
        sftTrainer -> configModule "Reads training configuration" "In-process"
        sftTrainer -> trackersModule "Registers experiment trackers" "In-process"
        sftTrainer -> trainerController "Registers training loop callbacks" "In-process"
        sftTrainer -> sumLossTrainer "Uses for loss computation" "In-process"
        fmsRecommender -> accelerateLaunch "Generates optimized configs" "In-process"

        # External relationships
        kfto -> fmsHfTuning "Creates and manages PyTorchJob pods" "Kubernetes API / TLS 1.2+"
        kueue -> kfto "Schedules training jobs" "Kubernetes API / TLS 1.2+"
        fmsHfTuning -> hfHub "Downloads pre-trained models and tokenizers" "HTTPS/443 / Bearer Token"
        fmsHfTuning -> hfDatasets "Downloads training datasets" "HTTPS/443 / Bearer Token"
        fmsHfTuning -> mlflowServer "Logs training metrics" "HTTP/HTTPS / URI-based"
        fmsHfTuning -> aimServer "Logs training metrics" "HTTP/HTTPS"
        fmsHfTuning -> clearmlServer "Logs training tasks" "HTTPS / API key"
        fmsHfTuning -> fmsAcceleration "Uses acceleration plugins" "In-process"
        fmsHfTuning -> nvidiaGpu "GPU compute for training" "PCIe/NVLink"
        fmsHfTuning -> pvStorage "Reads input data, writes model checkpoints" "Filesystem"
        fmsHfTuning -> vllm "Produces LoRA adapter checkpoints" "Filesystem (safetensors)"
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
            element "External Library" {
                background #b0b0b0
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Hardware" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #d6b656
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
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

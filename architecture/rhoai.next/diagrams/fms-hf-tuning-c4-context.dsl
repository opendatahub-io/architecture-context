workspace {
    model {
        dataScientist = person "Data Scientist" "Defines training configuration and submits fine-tuning jobs"
        mlEngineer = person "ML Engineer" "Monitors training metrics and manages model artifacts"

        fmsHfTuning = softwareSystem "FMS HF Tuning" "Production-ready fine-tuning framework for large language models using HuggingFace Transformers, TRL, and PyTorch FSDP" {
            accelerateLaunch = container "accelerate_launch.py" "Container entry point: JSON config parsing, multi-GPU auto-detection, FSDP defaults, vLLM post-processing" "Python CLI Wrapper"
            sftTrainer = container "sft_trainer.py" "Core training orchestration: model loading, tokenization, dataset preparation, SFTTrainer initialization, model saving" "Python Library"
            dataModule = container "Data Module" "Configurable data preprocessing: JSON/JSONL/Arrow/Parquet/HF datasets, tokenization, chat templates, vision data, online data mixing" "Python Library"
            configModule = container "Config Module" "Hierarchical dataclass-based configuration for model, data, training, PEFT, acceleration, tracker settings" "Python Library"
            trackersModule = container "Trackers Module" "Pluggable experiment tracking with Aim, MLflow, ClearML, HFResourceScanner, and file-based JSONL backends" "Python Library"
            trainerController = container "Trainer Controller" "Rule-driven training loop control using safe expression evaluation (simpleeval) for metrics-based operations" "Python Library"
            sumLossTrainer = container "Sum Loss SFT Trainer" "Custom SFTTrainer with sum-based loss reduction for consistent token weighting across gradient accumulation" "Python Library"
        }

        kfto = softwareSystem "Kubeflow Training Operator" "Orchestrates distributed training jobs on Kubernetes via PyTorchJob CRs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Queue-based scheduling for training jobs, prevents GPU resource contention" "Internal RHOAI"
        hfHub = softwareSystem "HuggingFace Hub" "Model registry for pre-trained models, tokenizers, and datasets" "External"
        hfDatasets = softwareSystem "HuggingFace Datasets" "Dataset registry for training and validation datasets" "External"
        mlflow = softwareSystem "MLflow Server" "Experiment tracking: metrics, run metadata, hyperparameters" "External (optional)"
        aim = softwareSystem "Aim Server" "Experiment tracking: metrics, experiment metadata" "External (optional)"
        clearml = softwareSystem "ClearML Server" "Experiment tracking: tasks, metrics, experiment metadata" "External (optional)"
        fmsAccel = softwareSystem "FMS Acceleration Framework" "Hardware-optimized training plugins: QLoRA, fused LoRA, padding-free attention, ScatterMoE, ODM" "External Library"
        vllm = softwareSystem "vLLM" "Inference engine consuming LoRA adapter checkpoints" "Downstream Consumer"
        pvc = softwareSystem "Persistent Volumes" "Storage for input data, output models, and cached models" "Kubernetes Infrastructure"
        nvidia = softwareSystem "NVIDIA CUDA/cuDNN" "GPU compute: CUDA 12.1, cuDNN 9.6, NCCL 2.18.3" "System Library"

        # User interactions
        dataScientist -> kfto "Submits PyTorchJob CR with training configuration"
        mlEngineer -> mlflow "Monitors training metrics and model performance"

        # System interactions
        kfto -> fmsHfTuning "Creates and manages PyTorchJob pods" "Kubernetes API / TLS 1.2+"
        kueue -> fmsHfTuning "Schedules training jobs via queue labels" "Kubernetes API / TLS 1.2+"
        fmsHfTuning -> hfHub "Downloads pre-trained models and tokenizers" "HTTPS/443 / Bearer Token"
        fmsHfTuning -> hfDatasets "Downloads training datasets" "HTTPS/443 / Bearer Token"
        fmsHfTuning -> pvc "Reads input data, writes model checkpoints" "Filesystem / POSIX"
        fmsHfTuning -> nvidia "GPU compute for training" "PCIe/NVLink"
        fmsHfTuning -> mlflow "Logs training metrics" "HTTP/HTTPS (configurable)"
        fmsHfTuning -> aim "Logs training metrics" "HTTP/HTTPS (configurable)"
        fmsHfTuning -> clearml "Logs training tasks and metrics" "HTTPS / API key"
        fmsHfTuning -> fmsAccel "Uses hardware acceleration plugins" "In-process Python"
        vllm -> pvc "Reads LoRA adapter checkpoints (new_embeddings.safetensors)" "Filesystem"

        # Container interactions
        accelerateLaunch -> sftTrainer "Launches training" "In-process"
        sftTrainer -> dataModule "Loads and preprocesses data" "In-process"
        sftTrainer -> configModule "Reads configuration" "In-process"
        sftTrainer -> trackersModule "Initializes experiment tracking" "In-process"
        sftTrainer -> trainerController "Attaches rule-based callbacks" "In-process"
        sftTrainer -> sumLossTrainer "Uses custom loss computation" "In-process"
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
            element "External (optional)" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External Library" {
                background #f5a623
                color #ffffff
            }
            element "Downstream Consumer" {
                background #4a90e2
                color #ffffff
            }
            element "Kubernetes Infrastructure" {
                background #e8e8e8
                color #333333
            }
            element "System Library" {
                background #e8e8e8
                color #333333
            }
        }
    }
}

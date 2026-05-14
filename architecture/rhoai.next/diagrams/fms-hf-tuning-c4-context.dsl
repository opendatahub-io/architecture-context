workspace {
    model {
        dataScientist = person "Data Scientist" "Configures and launches fine-tuning jobs for large language models"
        mlEngineer = person "ML Engineer" "Manages training infrastructure, monitors experiments"

        fmsHfTuning = softwareSystem "FMS HF Tuning" "Production-ready fine-tuning framework for LLMs using HuggingFace Transformers, TRL, and PyTorch FSDP" {
            accelerateLaunch = container "accelerate_launch.py" "Container entry point: JSON config parsing, multi-GPU auto-detection, FSDP defaults, vLLM post-processing" "Python CLI"
            sftTrainer = container "sft_trainer.py" "Core training orchestration: model loading, tokenization, dataset preparation, SFTTrainer initialization, model saving" "Python Library"
            dataModule = container "Data Module" "Configurable data preprocessing pipeline: JSON/JSONL/Arrow/Parquet/HF datasets with tokenization, chat templates, vision data, online data mixing" "Python Library"
            configModule = container "Config Module" "Hierarchical dataclass-based configuration for model, data, training, PEFT, acceleration, and tracker settings" "Python Library"
            trackersModule = container "Trackers Module" "Pluggable experiment tracking: Aim, MLflow, ClearML, HFResourceScanner, file-based JSONL logging" "Python Library"
            trainerController = container "Trainer Controller" "Rule-driven training loop control using safe expression evaluation (simpleeval) for dynamic decisions" "Python Library"
            sumLossTrainer = container "SumLoss SFTTrainer" "Custom SFTTrainer with sum-based loss reduction for consistent token weighting across gradient accumulation" "Python Library"
        }

        kfto = softwareSystem "Kubeflow Training Operator" "Orchestrates distributed training jobs as PyTorchJobs on Kubernetes" "Internal Platform"
        kueue = softwareSystem "Kueue" "Queue-based scheduling for training jobs, prevents GPU resource contention" "Internal Platform"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model registry for downloading pre-trained models, tokenizers, and datasets" "External"
        fmsAcceleration = softwareSystem "FMS Acceleration Framework" "Hardware-optimized training plugins: QLoRA, fused LoRA, padding-free attention, ScatterMoE, ODM" "External Library"
        mlflow = softwareSystem "MLflow Server" "Experiment tracking: logs training metrics, run metadata, hyperparameters" "External"
        aim = softwareSystem "Aim Server" "Experiment tracking: logs training metrics, run hashes, experiment metadata" "External"
        clearml = softwareSystem "ClearML Server" "Experiment tracking: logs training tasks, metrics, experiment metadata" "External"
        vllm = softwareSystem "vLLM" "Inference engine consuming LoRA adapter checkpoints post-processed by FMS HF Tuning" "External"
        persistentVolumes = softwareSystem "Persistent Volumes" "Kubernetes PVCs for input data, output models, and cached model storage" "Infrastructure"
        nvidiaGPU = softwareSystem "NVIDIA GPU / CUDA" "GPU compute for training: CUDA 12.1, cuDNN 9.6, NCCL 2.18.3" "Infrastructure"

        # Person relationships
        dataScientist -> fmsHfTuning "Configures training via JSON config, launches as PyTorchJob"
        mlEngineer -> mlflow "Monitors training experiments"
        mlEngineer -> aim "Monitors training experiments"

        # System relationships
        kfto -> fmsHfTuning "Creates and manages PyTorchJob pods" "Kubernetes API / TLS 1.2+"
        kueue -> fmsHfTuning "Schedules training jobs via queue labels" "Kubernetes API / TLS 1.2+"
        fmsHfTuning -> huggingfaceHub "Downloads pre-trained models and tokenizers" "HTTPS/443 / Bearer Token"
        fmsHfTuning -> persistentVolumes "Reads input data, writes model checkpoints" "Filesystem"
        fmsHfTuning -> nvidiaGPU "Executes training computations" "PCIe/NVLink"
        fmsHfTuning -> mlflow "Logs training metrics and metadata" "HTTP/HTTPS / URI-based"
        fmsHfTuning -> aim "Logs training metrics" "HTTP/HTTPS"
        fmsHfTuning -> clearml "Logs training tasks and metrics" "HTTPS / API Key"
        fmsHfTuning -> fmsAcceleration "Uses hardware acceleration plugins" "In-process Python"
        fmsHfTuning -> vllm "Produces compatible LoRA adapter checkpoints" "Filesystem (safetensors)"

        # Container relationships
        accelerateLaunch -> sftTrainer "Launches training" "In-process"
        sftTrainer -> dataModule "Loads and preprocesses data"
        sftTrainer -> configModule "Reads configuration"
        sftTrainer -> trackersModule "Logs experiment metrics"
        sftTrainer -> trainerController "Dynamic training loop control"
        sftTrainer -> sumLossTrainer "Custom loss computation"
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
                background #b8b8b8
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

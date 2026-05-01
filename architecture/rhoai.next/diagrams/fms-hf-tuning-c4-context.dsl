workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and configures fine-tuning jobs for LLMs"
        mlEngineer = person "ML Engineer" "Manages training infrastructure and deployment pipelines"

        fmsHfTuning = softwareSystem "fms-hf-tuning" "Containerized SFT training toolkit for fine-tuning LLMs using HuggingFace Transformers and TRL" {
            accelerateLaunch = container "accelerate_launch.py" "Container entrypoint that parses JSON config and launches distributed training" "Python Script"
            sftTrainer = container "sft_trainer.py" "Core training engine wrapping HuggingFace SFTTrainer with PEFT, acceleration, and tracker integrations" "Python Module"
            dataPreprocessor = container "Data Preprocessor" "Extensible data pipeline supporting pretokenized, chat, multi-turn, and vision-language formats" "Python Framework"
            trainerController = container "Trainer Controller" "YAML-driven training loop control with early stopping, loss thresholding, and patience-based rules" "Python Framework"
            trackerSystem = container "Tracker System" "Pluggable experiment tracking with file, AimStack, MLflow, ClearML, and HF Resource Scanner backends" "Python Framework"
            accelerationConfigs = container "Acceleration Configs" "Configuration for fms-acceleration plugins: QLoRA, padding-free, multipack, ScatterMoE, ODM" "Python Configs"
        }

        kfto = softwareSystem "Kubeflow Training Operator" "Creates and manages PyTorchJob CRs to run training workloads" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Queue-based job scheduling for training workloads" "Internal RHOAI"
        gpuOperator = softwareSystem "NVIDIA GPU Operator" "Provides GPU device plugin and drivers for training pods" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Pre-trained model and tokenizer registry" "External"
        huggingfaceDatasets = softwareSystem "HuggingFace Datasets" "Dataset loading and processing library" "External"
        fmsAcceleration = softwareSystem "fms-acceleration" "GPU optimization plugins (QLoRA, padding-free, multipack, ScatterMoE, ODM)" "External"
        aimStack = softwareSystem "AimStack" "Experiment tracking and visualization server" "External"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and model registry" "External"
        clearml = softwareSystem "ClearML" "ML experiment management platform" "External"
        pvcStorage = softwareSystem "PVC Storage" "Persistent volume storage for models, data, and checkpoints" "Kubernetes"
        vllm = softwareSystem "vLLM" "High-throughput LLM serving engine (post-processing target)" "Internal RHOAI"

        dataScientist -> kfto "Submits PyTorchJob with training config"
        mlEngineer -> kfto "Manages training infrastructure"
        kfto -> fmsHfTuning "Runs as PyTorchJob worker pods" "Kubernetes API / TLS 1.3"
        kueue -> kfto "Schedules training jobs via queue"
        fmsHfTuning -> huggingfaceHub "Downloads models and tokenizers" "HTTPS/443 / Bearer Token"
        fmsHfTuning -> huggingfaceDatasets "Loads datasets" "HTTPS/443"
        fmsHfTuning -> pvcStorage "Reads model weights, training data; writes checkpoints" "Local filesystem"
        fmsHfTuning -> gpuOperator "Uses GPU resources" "PCIe/NVLink"
        fmsHfTuning -> fmsAcceleration "Loads optimization plugins" "Python import"
        fmsHfTuning -> aimStack "Pushes training metrics" "HTTP(S) / configurable"
        fmsHfTuning -> mlflow "Pushes training metrics" "HTTP(S) / configurable"
        fmsHfTuning -> clearml "Pushes training metrics" "HTTP(S) / API key"
        fmsHfTuning -> vllm "Post-processes LoRA adapters for serving compatibility" "File I/O"

        accelerateLaunch -> sftTrainer "subprocess launch"
        sftTrainer -> dataPreprocessor "loads and processes training data"
        sftTrainer -> trainerController "applies callback-driven training policies"
        sftTrainer -> trackerSystem "reports metrics to configured backends"
        sftTrainer -> accelerationConfigs "applies GPU optimization configurations"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates fine-tuning jobs to customize LLMs for specific tasks"
        mlEngineer = person "ML Engineer" "Configures training infrastructure and acceleration plugins"

        fmsHfTuning = softwareSystem "fms-hf-tuning" "Containerized supervised fine-tuning toolkit for LLMs using HuggingFace Transformers and TRL" {
            accelerateLaunch = container "accelerate_launch.py" "Container entrypoint: parses JSON config, configures Accelerate launch args, invokes distributed training" "Python Script"
            sftTrainer = container "sft_trainer.py" "Core training engine wrapping HuggingFace SFTTrainer with PEFT, acceleration, and tracker integrations" "Python Module"
            dataPreprocessor = container "Data Preprocessor" "Extensible data pipeline supporting pretokenized, Jinja template, chat, multi-turn, and vision-language formats" "Python Framework"
            trainerController = container "Trainer Controller" "YAML-driven training loop control with pluggable metrics, rules, and operations (early stopping, patience)" "Python Framework"
            trackerSystem = container "Tracker System" "Pluggable experiment tracking with file, AimStack, MLflow, ClearML, and HF Resource Scanner backends" "Python Framework"
            accelerationConfigs = container "Acceleration Configs" "Configuration for fms-acceleration plugins: QLoRA, padding-free, multipack, ScatterMoE, ODM" "Python Configs"
        }

        kfto = softwareSystem "Kubeflow Training Operator" "Creates and manages PyTorchJob resources for distributed training" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Queue-based workload scheduling for Kubernetes batch jobs" "Internal RHOAI"
        gpuOperator = softwareSystem "NVIDIA GPU Operator" "Provides GPU device plugin and CUDA runtime to training pods" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model and dataset registry for downloading pre-trained models and tokenizers" "External"
        hfDatasets = softwareSystem "HuggingFace Datasets" "Dataset loading library for training data from Hub or local paths" "External"
        fmsAcceleration = softwareSystem "fms-acceleration" "GPU optimization plugins: QLoRA, padding-free flash attention, multipack, ScatterMoE, ODM" "Internal RHOAI"
        aimStack = softwareSystem "AimStack" "Experiment tracking server for training metrics visualization" "External"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and model registry" "External"
        clearml = softwareSystem "ClearML" "ML experiment tracking and pipeline management" "External"
        vllm = softwareSystem "vLLM" "High-throughput LLM serving engine consuming LoRA adapters from fine-tuning output" "Internal RHOAI"
        pvcStorage = softwareSystem "PVC Storage" "Persistent volume claims for model weights, training data, and output artifacts" "Kubernetes"

        # Person relationships
        dataScientist -> kfto "Submits PyTorchJob via kubectl/Dashboard"
        mlEngineer -> fmsHfTuning "Configures training JSON and acceleration plugins"

        # System context relationships
        kfto -> fmsHfTuning "Runs as PyTorchJob worker pods" "Kubernetes API / TLS 1.3"
        kueue -> kfto "Schedules training workloads" "Label annotation"
        fmsHfTuning -> hfHub "Downloads models and tokenizers" "HTTPS/443 / Bearer Token"
        fmsHfTuning -> hfDatasets "Loads training datasets" "HTTPS/443 / TLS 1.2+"
        fmsHfTuning -> pvcStorage "Reads model weights, training data; writes checkpoints" "Local filesystem"
        fmsHfTuning -> gpuOperator "Uses GPU resources for training" "PCIe/NVLink"
        fmsHfTuning -> fmsAcceleration "Loads acceleration plugins at runtime" "Python import"
        fmsHfTuning -> aimStack "Pushes training metrics" "HTTP/HTTPS"
        fmsHfTuning -> mlflow "Pushes training metrics" "HTTP/HTTPS"
        fmsHfTuning -> clearml "Pushes training metrics" "HTTP/HTTPS"
        vllm -> fmsHfTuning "Consumes LoRA adapter output" "File I/O"

        # Container relationships
        accelerateLaunch -> sftTrainer "Launches as subprocess" "accelerate launch"
        sftTrainer -> dataPreprocessor "Processes training data" "Python call"
        sftTrainer -> trainerController "Evaluates training loop rules" "TrainerCallback"
        sftTrainer -> trackerSystem "Reports training metrics" "Python call"
        sftTrainer -> accelerationConfigs "Loads acceleration plugin configs" "Python import"
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

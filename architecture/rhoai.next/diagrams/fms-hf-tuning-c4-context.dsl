workspace {
    model {
        dataScientist = person "Data Scientist" "Configures and submits fine-tuning jobs via PyTorchJob manifests"

        fmsHfTuning = softwareSystem "fms-hf-tuning" "Python library and container image for fine-tuning LLMs using HF SFTTrainer with PyTorch FSDP" {
            accelerateLaunch = container "accelerate_launch.py" "Container entry point that wraps accelerate launch, auto-detects GPUs, configures FSDP" "Python CLI"
            sftTrainer = container "SFT Trainer Engine" "Core fine-tuning engine wrapping HuggingFace SFTTrainer with data preprocessing pipeline" "Python Library"
            dataPreprocessor = container "Data Preprocessing Pipeline" "Configurable chain of DataHandler operations with Jinja2 sandboxed templates" "Python Library"
            trainerController = container "Trainer Controller Framework" "Rule-based control system for training loop with simpleeval expressions" "Python Library"
            accelerationBridge = container "Acceleration Config Bridge" "Bridges CLI args to fms-acceleration YAML configuration for plugins" "Python Library"
        }

        kfto = softwareSystem "Kubeflow Training Operator" "Orchestrates distributed training jobs as PyTorchJob resources on Kubernetes" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Optional job queuing and resource quota management for training workloads" "Internal RHOAI"
        hfHub = softwareSystem "HuggingFace Hub" "Public model registry for pre-trained models and tokenizers" "External"
        fmsAcceleration = softwareSystem "fms-acceleration Framework" "Plugin ecosystem for quantized LoRA, fused operations, padding-free attention, ScatterMoE, ODM" "External"
        vllm = softwareSystem "vLLM" "High-throughput LLM inference engine that consumes LoRA adapter artifacts" "Internal RHOAI"
        experimentTrackers = softwareSystem "Experiment Trackers" "Optional remote tracking servers (Aim, MLflow, ClearML) for training metrics" "External"
        pvStorage = softwareSystem "PV Storage" "Kubernetes Persistent Volumes for training data, model artifacts, and checkpoints" "Infrastructure"

        dataScientist -> kfto "Submits PyTorchJob manifest with fms-hf-tuning image" "kubectl/API"
        kfto -> fmsHfTuning "Creates training pods using container image" "Kubernetes API"
        kueue -> kfto "Schedules jobs based on resource quotas" "kueue.x-k8s.io label"

        fmsHfTuning -> hfHub "Downloads pre-trained models and tokenizers" "HTTPS/443, Bearer Token"
        fmsHfTuning -> pvStorage "Reads training data, writes checkpoints and final model" "File I/O (PVC mount)"
        fmsHfTuning -> fmsAcceleration "Loads acceleration plugins at runtime" "Python import"
        fmsHfTuning -> experimentTrackers "Sends training metrics" "HTTP/HTTPS, configurable"
        fmsHfTuning -> vllm "Produces LoRA adapter artifacts (new_embeddings.safetensors)" "File (safetensors on PVC)"

        accelerateLaunch -> sftTrainer "Launches training" "Python module"
        sftTrainer -> dataPreprocessor "Initializes data pipeline" "Python API"
        sftTrainer -> trainerController "Evaluates training loop rules" "Callback API"
        sftTrainer -> accelerationBridge "Loads acceleration config" "Python API"
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
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Configures and submits fine-tuning jobs"
        mlEngineer = person "ML Engineer" "Manages training infrastructure and acceleration plugins"

        fmsHfTuning = softwareSystem "fms-hf-tuning" "Production-ready framework for supervised fine-tuning of foundation models using SFTTrainer with PyTorch FSDP" {
            entrypoint = container "accelerate_launch.py" "Container entrypoint: reads JSON config, constructs accelerate launch args, handles termination logging" "Python Script"
            sftTrainer = container "sft_trainer.py" "Core training logic: model loading, PEFT config, SFTTrainer initialization, training execution" "Python Module"
            trainerController = container "trainercontroller" "Policy-driven training loop control with configurable metrics, rules, and operations" "Python Subsystem"
            trackers = container "trackers" "Pluggable experiment tracking: file logging, Aim, MLflow, ClearML" "Python Subsystem"
            dataModule = container "data" "Data loading, preprocessing, tokenization, and collation with multiple format support" "Python Subsystem"
            configModule = container "config" "ModelArguments, DataArguments, TrainingArguments, PEFTConfig dataclasses" "Python Subsystem"
        }

        trainingOperator = softwareSystem "Training Operator" "Kubernetes operator (codeflare/kubeflow) that schedules fine-tuning Jobs" "External"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Model and dataset registry" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Dataset and artifact storage" "External"
        aimServer = softwareSystem "Aim Server" "Experiment tracking server" "External"
        mlflowServer = softwareSystem "MLflow Tracking Server" "Experiment tracking and model registry" "External"

        fmsAcceleration = softwareSystem "fms-acceleration" "Acceleration framework with plugins for quantized LoRA, fused ops, padding-free attention, MoE, data mixing" "External"

        dataScientist -> fmsHfTuning "Configures training via JSON config file"
        mlEngineer -> trainingOperator "Submits training job manifests"
        trainingOperator -> fmsHfTuning "Launches container as Kubernetes Job"
        fmsHfTuning -> huggingFaceHub "Downloads models and tokenizers" "HTTPS/443"
        fmsHfTuning -> s3Storage "Downloads datasets" "HTTPS"
        fmsHfTuning -> aimServer "Sends experiment metrics" "TCP"
        fmsHfTuning -> mlflowServer "Sends experiment metrics" "HTTP/HTTPS"
        fmsHfTuning -> fmsAcceleration "Loads acceleration plugins dynamically"

        entrypoint -> sftTrainer "Delegates training via accelerate launch"
        sftTrainer -> trainerController "Initializes training loop policies"
        sftTrainer -> trackers "Initializes experiment tracking"
        sftTrainer -> dataModule "Loads and preprocesses training data"
        sftTrainer -> configModule "Reads training configuration"
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
            element "Person" {
                shape person
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

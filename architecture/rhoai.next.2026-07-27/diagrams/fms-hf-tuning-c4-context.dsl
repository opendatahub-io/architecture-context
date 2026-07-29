workspace {
    model {
        dataScientist = person "Data Scientist" "Configures and launches model fine-tuning jobs"
        platformEngineer = person "Platform Engineer" "Deploys and manages tuning infrastructure"

        fmsHfTuning = softwareSystem "fms-hf-tuning" "Python library and CLI for fine-tuning HuggingFace transformer models using PEFT, TRL, and Accelerate" {
            cli = container "CLI Entrypoint" "sft_trainer.py - parses arguments, orchestrates tuning workflow" "Python CLI"
            sftTrainer = container "SFT Trainer" "Supervised fine-tuning engine using transformers, PEFT, TRL" "Python Module"
            dataFormatter = container "Data Formatter" "Dataset preprocessing, tokenization, and formatting" "Python Module"
            configRecommender = container "Config Recommender" "Recommends optimal tuning hyperparameters" "Python Module (tuning-config-recommender)"
        }

        k8sJob = softwareSystem "Kubernetes Job Controller" "Orchestrates batch workloads on the cluster" "External"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (optional launcher)" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Stores training datasets and model artifacts" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Public model and dataset registry" "External"
        aim = softwareSystem "Aim" "Experiment tracking server (optional)" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking server (optional)" "External"
        clearml = softwareSystem "ClearML" "Experiment tracking server (optional)" "External"

        # Relationships
        dataScientist -> fmsHfTuning "Configures tuning parameters and launches jobs"
        platformEngineer -> k8sJob "Creates Job manifests for tuning workloads"

        k8sJob -> fmsHfTuning "Invokes as container entrypoint"
        dsPipelines -> fmsHfTuning "Launches as pipeline step"

        fmsHfTuning -> s3Storage "Retrieves training datasets" "HTTPS/443, boto3, AWS IAM"
        fmsHfTuning -> hfHub "Downloads pretrained models" "HTTPS/443, hf-transfer"
        fmsHfTuning -> aim "Logs training metrics (optional)"
        fmsHfTuning -> mlflow "Logs training metrics (optional)"
        fmsHfTuning -> clearml "Logs training metrics (optional)"

        # Internal container relationships
        cli -> sftTrainer "Initializes and runs training"
        cli -> dataFormatter "Prepares dataset"
        cli -> configRecommender "Gets recommended config"
        sftTrainer -> dataFormatter "Consumes formatted data"
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

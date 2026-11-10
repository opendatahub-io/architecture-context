workspace {
    model {
        dataScientist = person "Data Scientist" "Runs LLM post-training via the Python API, thub CLI or a workbench"

        trainingHub = softwareSystem "Training Hub" "Algorithm-focused Python library and thub CLI for LLM post-training (SFT, OSFT, LoRA-SFT, GRPO, GEPA, embedding SFT). Runs inside training pods; opens no listeners." {
            cli = container "thub CLI" "argparse subcommands per algorithm, YAML --config via safe_load" "Python console script"
            api = container "Python API" "sft, osft, lora_sft, lora_grpo, grpo, gepa, embedding_sft entry points" "Python"
            registry = container "AlgorithmRegistry" "Algorithm-to-backend dispatch and extension point" "Python"
            backends = container "Algorithm Backends" "InstructLab SFT, Mini-Trainer OSFT, Unsloth LoRA, ART/verl GRPO, GEPA/MLflow, sentence-transformers" "Python"
            callbacks = container "Callbacks / Adapters" "TrainingHubCallback bridged into each backend; source serialized across torchrun and exec'd in workers" "Python"
            checkpoint = container "JIT Checkpoint + Checkpoint Manager" "SIGTERM-triggered checkpointing with fsspec/S3 mirror and restore" "Python"
            profiling = container "Profiling and Visualization" "Memory/runtime estimators and loss plotting" "Python"
        }

        trainer = softwareSystem "Kubeflow Trainer v2 / KFTO" "Creates training pods and injects PET_* torchrun env" "Internal RHOAI"
        universalImage = softwareSystem "Universal Training Image" "distributed-workloads images that pip-install Training Hub" "Internal RHOAI"
        workbench = softwareSystem "Notebooks / Workbenches" "Interactive use of the universal image" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking and GEPA MLflow backend" "Internal RHOAI"
        modelServing = softwareSystem "Model Serving (vLLM)" "OpenAI-compatible LLM endpoint for GEPA" "Internal RHOAI"
        aipcc = softwareSystem "AIPCC" "Wheels and base images for the universal image" "Internal RHOAI"

        trainingLibs = softwareSystem "Training Backends" "instructlab-training, rhai-innovation-mini-trainer, Unsloth/TRL, OpenPipe ART + vLLM, verl, sentence-transformers" "External"
        s3 = softwareSystem "S3-compatible Storage" "Checkpoint mirror and restore (MinIO, ODF, AWS)" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model, tokenizer and dataset downloads" "External"
        wandb = softwareSystem "Weights & Biases" "Optional metrics tracking" "External"

        dataScientist -> trainingHub "Calls sft()/osft()/... or thub <algorithm>"
        dataScientist -> workbench "Uses interactively"
        trainer -> trainingHub "Launches pods with PET_* env" "Pod spec"
        universalImage -> trainingHub "Packages" "pip install"
        aipcc -> universalImage "Supplies wheels and base images"
        workbench -> trainingHub "Imports"
        trainingHub -> trainingLibs "Delegates training (torchrun, subprocess, in-process)"
        trainingHub -> s3 "Mirrors and restores checkpoints" "HTTPS/443, AWS creds"
        trainingHub -> mlflow "Logs runs / GEPA backend" "HTTP/HTTPS"
        trainingHub -> modelServing "GEPA task and reflection LLM calls via litellm" "HTTP/HTTPS, Bearer"
        trainingHub -> hfHub "Downloads models and datasets" "HTTPS/443"
        trainingHub -> wandb "Optional metrics" "HTTPS/443, API key"

        cli -> api "Invokes"
        api -> registry "Creates algorithm"
        registry -> backends "Dispatches to"
        backends -> callbacks "Invokes hooks"
        callbacks -> checkpoint "Triggers JIT checkpoint"
        backends -> trainingLibs "Runs"
        checkpoint -> s3 "Uploads/restores" "HTTPS/443"
        backends -> modelServing "GEPA LLM calls" "HTTP/HTTPS"
        backends -> mlflow "Tracking" "HTTP/HTTPS"
        api -> hfHub "Model/dataset download" "HTTPS/443"
        profiling -> api "Used alongside"
    }

    views {
        systemContext trainingHub "SystemContext" {
            include *
            autoLayout
        }

        container trainingHub "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Person" {
                shape Person
            }
        }
    }
}

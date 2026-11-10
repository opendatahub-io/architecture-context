workspace "training-hub" "Training Hub (RHOAI 3.7-ea.1) - in-process LLM post-training library" {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Runs post-training via notebook, thub CLI or Kubeflow SDK"

        trainingHub = softwareSystem "Training Hub" "Python library + CLI (thub) v0.11.2 for LLM post-training: SFT, OSFT, LoRA, GRPO, GEPA, embedding SFT. Runs in-process; no Kubernetes footprint" {
            cli = container "thub CLI" "argparse CLI; merges YAML config with flags; resolves callables via importlib" "Python console script"
            api = container "Public Python API" "sft, osft, lora_sft, lora_grpo, grpo, gepa, embedding_sft, estimate, plot_loss" "Python"
            registry = container "AlgorithmRegistry" "Maps algorithms to Algorithm classes and named Backends; create_algorithm()" "Python"
            backends = container "Algorithm backends" "InstructLab-Training, Mini-Trainer, Unsloth, OpenPipe ART, verl, GEPA/MLflow, SentenceTransformers" "Python adapters"
            callbacks = container "Callbacks + adapters" "TrainingHubCallback API; serializes callbacks (base64, 0600, exec) across torchrun" "Python"
            checkpoint = container "JIT checkpoint + checkpoint manager" "SIGTERM-triggered save; PVC or fsspec/S3 mirroring and resume" "Python"
            profiling = container "Profiling + visualization" "GPU memory / runtime estimators; loss plotting" "Python"
        }

        distributedWorkloads = softwareSystem "distributed-workloads universal images" "odh-th-torch-{cpu,cuda,rocm}-py312-rhel9; pip-installs training-hub 0.11.2" "Internal RHOAI"
        kubeflowSdk = softwareSystem "Kubeflow SDK (TrainingHubTrainer)" "Generates training scripts calling Training Hub" "Internal RHOAI"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer v2 / KFTO" "Creates training pods and injects PET_* rendezvous env" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches (Notebooks)" "Interactive Jupyter environment using universal images" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload queueing; preemption delivers SIGTERM" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking; GEPA MLflow backend" "Internal RHOAI"
        serving = softwareSystem "Model serving (vLLM / KServe) or OpenAI-compatible endpoint" "Task/reflection and rollout LLMs" "Internal RHOAI"

        huggingFace = softwareSystem "Hugging Face Hub" "Model and dataset hosting" "External"
        s3 = softwareSystem "S3-compatible object storage" "Checkpoint mirroring and restore" "External"
        wandb = softwareSystem "Weights & Biases" "Optional metric logging" "External"

        dataScientist -> trainingHub "Calls Python API / thub CLI"
        dataScientist -> kubeflowSdk "Submits TrainingHubTrainer jobs"
        kubeflowSdk -> trainingHub "Generated script calls algorithms in TrainJob pods"
        distributedWorkloads -> trainingHub "Packages (pip dependency)"
        kubeflowTrainer -> trainingHub "Injects PET_*/MASTER_PORT env" "env / c10d 29500/TCP"
        workbenches -> trainingHub "Hosts interactive use"
        kueue -> trainingHub "Preemption SIGTERM" "signal"

        trainingHub -> huggingFace "Downloads models/datasets" "HTTPS/443, optional HF token"
        trainingHub -> s3 "Mirrors/restores checkpoints" "HTTPS/443, AWS credentials"
        trainingHub -> mlflow "Logs experiments" "HTTP/HTTPS URI-defined"
        trainingHub -> serving "GEPA / GRPO LLM calls via LiteLLM" "HTTP/HTTPS URI-defined, OPENAI_API_KEY"
        trainingHub -> wandb "Logs metrics" "HTTPS/443, WANDB_API_KEY"

        dataScientist -> cli "Runs thub <algorithm> --config"
        dataScientist -> api "Calls sft()/osft()/..."
        cli -> api "Invokes algorithm functions"
        api -> registry "create_algorithm()"
        registry -> backends "Selects backend"
        backends -> callbacks "Dispatches callbacks"
        backends -> checkpoint "Saves / resumes checkpoints"
        checkpoint -> s3 "Background upload (node 0)" "HTTPS/443"
        backends -> serving "LLM calls (GEPA/GRPO)" "HTTP/HTTPS"
        backends -> mlflow "Tracking" "HTTP/HTTPS"
        backends -> huggingFace "Model/dataset download" "HTTPS/443"
        backends -> wandb "Metrics" "HTTPS/443"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}

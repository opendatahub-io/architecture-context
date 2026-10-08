workspace {
    model {
        dataScientist = person "Data Scientist" "Trains and fine-tunes LLM models using Training Hub"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and training infrastructure"

        trainingHub = softwareSystem "Training Hub" "Algorithm-focused Python library and CLI for LLM training, continual learning, and reinforcement learning" {
            cli = container "thub CLI" "Command-line interface for YAML-driven training workflows" "Python console_scripts"
            algorithmRegistry = container "Algorithm Registry" "Strategy + Registry pattern mapping algorithm names to backend implementations" "Python"
            sftAlgorithm = container "SFT Algorithm" "Supervised Fine-Tuning via InstructLab-Training with multi-node torchrun" "Python"
            osftAlgorithm = container "OSFT Algorithm" "Orthogonal Subspace Fine-Tuning via Mini-Trainer with FSDP" "Python"
            loraAlgorithm = container "LoRA Algorithms" "LoRA + SFT via Unsloth, LoRA + GRPO via ART/verl" "Python"
            gepaAlgorithm = container "GEPA Algorithm" "Gradient-free prompt optimization via evolutionary search" "Python"
            embeddingAlgorithm = container "Embedding SFT" "Contrastive embedding fine-tuning via SentenceTransformers" "Python"
            adapterLayer = container "Adapter Bridge Layer" "Translates TrainingHubCallback hooks into native backend interfaces with serialization" "Python"
            checkpointInfra = container "Checkpoint Infrastructure" "JIT preemption checkpoint (SIGTERM), remote mirroring via fsspec" "Python"
            memoryEstimator = container "GPU Memory Estimator" "VRAM estimation for SFT, OSFT, LoRA, QLoRA configurations" "Python"
        }

        kubeflow = softwareSystem "Kubeflow / Training Operator" "Manages training pods and job lifecycle on Kubernetes" "Internal RHOAI"
        volcano = softwareSystem "Volcano Job Scheduler" "Distributed training job scheduling and resource management" "Internal RHOAI"

        instructlabTraining = softwareSystem "InstructLab-Training" "SFT backend with torchrun multi-node support" "Internal RHOAI"
        miniTrainer = softwareSystem "Mini-Trainer" "OSFT backend with FSDP distributed training" "Internal RHOAI"

        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Remote checkpoint and model artifact storage" "External"
        openaiAPI = softwareSystem "OpenAI-Compatible API" "LLM API for GEPA prompt optimization" "External"
        wandb = softwareSystem "Weights & Biases" "ML experiment tracking platform" "External"
        mlflowServer = softwareSystem "MLflow Server" "Experiment tracking and prompt registry" "External"

        # Relationships
        dataScientist -> trainingHub "Runs training via thub CLI or Python API"
        platformAdmin -> kubeflow "Configures training infrastructure"

        kubeflow -> trainingHub "Launches training pods containing Training Hub"
        trainingHub -> instructlabTraining "Uses as SFT backend" "Python API"
        trainingHub -> miniTrainer "Uses as OSFT backend" "Python API"
        trainingHub -> huggingfaceHub "Downloads models and datasets" "HTTPS/443"
        trainingHub -> s3Storage "Stores and restores checkpoints" "HTTPS/443"
        trainingHub -> openaiAPI "GEPA prompt optimization LLM calls" "HTTPS/443"
        trainingHub -> wandb "Optional experiment tracking" "HTTPS/443"
        trainingHub -> mlflowServer "Optional experiment tracking and prompt registry" "HTTP/HTTPS"
        trainingHub -> volcano "verl backend uses for distributed scheduling"
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

workspace {
    model {
        dataScientist = person "Data Scientist" "Runs training experiments via Python API or thub CLI"
        mlEngineer = person "ML Engineer" "Configures training pipelines in Kubeflow"
        codingAgent = person "Coding Agent" "Claude Code or Codex CLI using Training Hub plugin"

        trainingHub = softwareSystem "Training Hub" "Algorithm-focused Python library and CLI for LLM post-training: SFT, OSFT, LoRA, GRPO, GEPA, Embedding SFT" {
            registry = container "AlgorithmRegistry" "Strategy + Registry pattern mapping algorithm names to classes and backends" "Python"
            cli = container "thub CLI" "Command-line interface with YAML config support and lazy imports" "Python console_scripts"
            callbackSystem = container "Callback System" "Cross-backend lifecycle hooks with class-source serialization for subprocess boundary" "Python"

            sftAlgorithm = container "SFT Algorithm" "Supervised Fine-Tuning via InstructLab Training" "Python"
            osftAlgorithm = container "OSFT Algorithm" "Orthogonal Subspace Fine-Tuning via Mini-Trainer" "Python"
            loraSftAlgorithm = container "LoRA SFT Algorithm" "LoRA + SFT via Unsloth (2x faster, 70% less VRAM)" "Python"
            loraGrpoAlgorithm = container "LoRA GRPO Algorithm" "LoRA + GRPO via ART (single-GPU) or verl (multi-GPU)" "Python"
            grpoAlgorithm = container "GRPO Algorithm" "Full-parameter GRPO via verl (multi-GPU FSDP)" "Python"
            gepaAlgorithm = container "GEPA Algorithm" "Gradient-free Genetic-Pareto prompt optimization" "Python"
            embeddingSftAlgorithm = container "Embedding SFT Algorithm" "Contrastive embedding fine-tuning via SentenceTransformers" "Python"
        }

        instructlabTraining = softwareSystem "InstructLab Training" "SFT training backend with torchrun support" "Internal Dependency"
        miniTrainer = softwareSystem "Mini-Trainer" "OSFT backend with orthogonal subspace projection" "Internal Dependency"
        unsloth = softwareSystem "Unsloth" "Optimized LoRA training library" "External Dependency"
        art = softwareSystem "OpenPipe ART" "Single-GPU GRPO with co-located vLLM + Unsloth" "External Dependency"
        verl = softwareSystem "verl (Volcano Engine RL)" "Multi-GPU distributed GRPO with FSDP + vLLM" "External Dependency"
        vllm = softwareSystem "vLLM" "High-throughput LLM inference engine" "External Dependency"
        gepaLib = softwareSystem "GEPA Library" "Gradient-free prompt optimization engine" "External Dependency"
        sentenceTransformers = softwareSystem "SentenceTransformers" "Contrastive embedding model training" "External Dependency"

        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External Service"
        llmApi = softwareSystem "OpenAI-compatible API" "LLM inference endpoint for GEPA" "External Service"
        mlflow = softwareSystem "MLflow" "Experiment tracking and prompt registry" "External Service"
        wandb = softwareSystem "Weights & Biases" "Experiment tracking platform" "External Service"
        kubeflow = softwareSystem "Kubeflow Training Operator" "Kubernetes-native ML training orchestrator" "Platform"

        dataScientist -> trainingHub "Runs training via Python API or thub CLI"
        mlEngineer -> kubeflow "Configures training pipelines"
        codingAgent -> trainingHub "Guided training setup via plugin skills"
        kubeflow -> trainingHub "Invokes training_hub as a dependency in training pods"

        trainingHub -> instructlabTraining "SFT backend" "Python import"
        trainingHub -> miniTrainer "OSFT backend" "Python import"
        trainingHub -> unsloth "LoRA backend" "Python import"
        trainingHub -> art "ART GRPO backend" "Python import + subprocess"
        trainingHub -> verl "verl GRPO backend" "torchrun subprocess"
        trainingHub -> vllm "Rollout generation" "subprocess (ephemeral)"
        trainingHub -> gepaLib "Prompt optimization" "Python import"
        trainingHub -> sentenceTransformers "Embedding training" "Python import"

        trainingHub -> huggingfaceHub "Downloads models and datasets" "HTTPS/443"
        trainingHub -> llmApi "GEPA LLM calls" "HTTPS/443"
        trainingHub -> mlflow "Experiment tracking" "HTTP/HTTPS"
        trainingHub -> wandb "Experiment tracking" "HTTPS/443"
        trainingHub -> kubeflow "Emits training_metrics.jsonl for progress" "Filesystem"
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
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Internal Dependency" {
                background #7ed321
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

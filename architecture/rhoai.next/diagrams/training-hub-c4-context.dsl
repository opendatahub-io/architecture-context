workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and fine-tunes ML models using notebooks and scripts"
        mlEngineer = person "ML Engineer" "Builds training pipelines and integrates training into CI/CD"

        trainingHub = softwareSystem "training-hub" "Unified Python library for LLM training: SFT, OSFT, LoRA, GRPO, GEPA" {
            algorithmRegistry = container "AlgorithmRegistry" "Plugin registry mapping (algorithm, backend) pairs to implementations" "Python"
            sftAlgorithm = container "SFT Algorithm" "Full-parameter supervised fine-tuning" "Python"
            osftAlgorithm = container "OSFT Algorithm" "Orthogonal subspace fine-tuning (arXiv:2504.07097)" "Python"
            loraSftAlgorithm = container "LoRA SFT Algorithm" "LoRA/QLoRA parameter-efficient fine-tuning" "Python"
            loraGrpoAlgorithm = container "LoRA GRPO Algorithm" "Reinforcement learning from verifiable rewards" "Python"
            gepaAlgorithm = container "GEPA Algorithm" "Gradient-free evolutionary prompt optimization" "Python"
            memoryEstimator = container "Memory Estimator" "GPU memory profiling for SFT, OSFT, LoRA, QLoRA" "Python"
            timingEstimator = container "Timing Estimator" "Training runtime extrapolation" "Python"
            visualization = container "Visualization" "Training loss curve plotting with EMA smoothing" "Python (matplotlib)"
            codingPlugins = container "Coding Agent Plugins" "Claude Code and Codex CLI skills-first integration" "Python"
        }

        # External training framework dependencies
        instructlabTraining = softwareSystem "instructlab-training" "SFT training framework (run_training, TorchrunArgs)" "External"
        miniTrainer = softwareSystem "rhai-innovation-mini-trainer" "Mini-trainer for orthogonal subspace fine-tuning" "External"
        unsloth = softwareSystem "Unsloth" "Fast LoRA fine-tuning with memory optimizations" "External"
        art = softwareSystem "OpenPipe ART" "Co-located vLLM + training for GRPO" "External"
        verl = softwareSystem "verl" "Distributed multi-GPU GRPO training framework" "External"
        gepaLib = softwareSystem "gepa" "Gradient-free evolutionary prompt optimization library" "External"

        # Core ML dependencies
        pytorch = softwareSystem "PyTorch" "Deep learning framework with NCCL/Gloo distributed training" "External"
        huggingface = softwareSystem "Hugging Face Ecosystem" "transformers, datasets, peft, trl, accelerate" "External"

        # External services (runtime-optional)
        wandb = softwareSystem "Weights & Biases" "Experiment logging and metrics tracking" "External Service"
        mlflow = softwareSystem "MLflow" "Experiment tracking and GEPA optimize_prompts" "External Service"
        llmApi = softwareSystem "LLM API (via litellm)" "LLM inference for GEPA evaluation and GRPO rewards" "External Service"

        # Consumers
        instructlabCli = softwareSystem "InstructLab CLI" "CLI tool that imports training-hub for model fine-tuning" "Internal RHOAI"
        rhoaiWorkbench = softwareSystem "RHOAI Workbench" "Jupyter notebooks running on GPU compute nodes" "Internal RHOAI"

        # Relationships — Users
        dataScientist -> trainingHub "Calls sft(), osft(), lora_sft(), lora_grpo(), gepa()" "Python API"
        mlEngineer -> trainingHub "Integrates into training pipelines" "Python API"

        # Relationships — Internal wiring
        algorithmRegistry -> sftAlgorithm "Resolves"
        algorithmRegistry -> osftAlgorithm "Resolves"
        algorithmRegistry -> loraSftAlgorithm "Resolves"
        algorithmRegistry -> loraGrpoAlgorithm "Resolves"
        algorithmRegistry -> gepaAlgorithm "Resolves"

        # Relationships — Backend dependencies
        sftAlgorithm -> instructlabTraining "Delegates training via run_training()" "Python import"
        osftAlgorithm -> miniTrainer "Delegates OSFT via mini-trainer" "Python import"
        loraSftAlgorithm -> unsloth "Uses FastLanguageModel for LoRA fine-tuning" "Python import"
        loraGrpoAlgorithm -> art "Launches co-located vLLM + Unsloth training" "Subprocess"
        loraGrpoAlgorithm -> verl "Launches distributed GRPO training" "Subprocess/CLI"
        gepaAlgorithm -> gepaLib "Calls optimize() for prompt evolution" "Python import"

        # Relationships — Core dependencies
        trainingHub -> pytorch "Uses for all GPU training operations" "Python import"
        trainingHub -> huggingface "Model loading, tokenization, PEFT, training loops" "Python import"

        # Relationships — External services (optional, runtime)
        trainingHub -> wandb "Logs experiment metrics" "HTTPS/443, API Key"
        trainingHub -> mlflow "Tracks experiments, GEPA backend" "HTTP/HTTPS, Configurable"
        gepaAlgorithm -> llmApi "Evaluates prompts via LLM calls" "HTTPS/443, API Key"

        # Relationships — Consumers
        instructlabCli -> trainingHub "Imports as pip dependency" "Python import"
        rhoaiWorkbench -> trainingHub "Imports in notebook cells" "Python import"
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
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
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

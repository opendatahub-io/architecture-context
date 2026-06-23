workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and fine-tunes ML models using RHOAI"
        rhoaiComponent = person "RHOAI Orchestrator" "Higher-level RHOAI component that manages training jobs"

        trainingHub = softwareSystem "Training Hub" "Unified Python SDK providing a common interface for multiple fine-tuning algorithms (SFT, OSFT, LoRA, GRPO, GEPA)" {
            algorithmRegistry = container "Algorithm Registry" "Central registry mapping algorithm names to Algorithm classes and backend names to Backend classes" "Python Module"
            sftAlgorithm = container "SFT Algorithm" "Full-parameter supervised fine-tuning via instructlab-training backend" "Python Module"
            osftAlgorithm = container "OSFT Algorithm" "Orthogonal Subspace Fine-Tuning for continual learning via mini-trainer backend" "Python Module"
            loraSftAlgorithm = container "LoRA SFT Algorithm" "Parameter-efficient LoRA/QLoRA fine-tuning via Unsloth backend with VLM support" "Python Module"
            grpoAlgorithm = container "LoRA GRPO / GRPO Algorithm" "Reinforcement learning from verifiable rewards via ART (single-GPU) or verl (multi-GPU) backends" "Python Module"
            gepaAlgorithm = container "GEPA Algorithm" "Genetic-Pareto prompt optimization (no weight modification) via gepa or MLflow backends" "Python Module"
            memoryEstimator = container "Memory Estimator" "GPU VRAM estimation for SFT, OSFT, LoRA, and QLoRA training methods" "Python Module"
            timingEstimator = container "Timing Estimator" "Experimental runtime estimation by running training on data subsets" "Python Module"
            visualization = container "Visualization" "Training loss curve plotting with multi-run comparison and EMA smoothing" "Python Module"
            torchrunUtils = container "Torchrun Utilities" "PyTorch distributed training parameter handling (multi-node/multi-GPU)" "Python Module"
            peftExtender = container "PEFT Extender" "Reusable LoRA parameter definitions and defaults for algorithm composition" "Python Module"
        }

        instructlabTraining = softwareSystem "instructlab-training" "SFT training backend and data processing utilities" "External Library"
        miniTrainer = softwareSystem "rhai-innovation-mini-trainer" "OSFT training backend (mini-trainer)" "External Library"
        unsloth = softwareSystem "Unsloth" "LoRA model loading with optimizations" "External Library"
        trl = softwareSystem "TRL" "HuggingFace SFTTrainer for LoRA training" "External Library"
        art = softwareSystem "OpenPipe ART" "Single-GPU GRPO training framework" "External Library"
        verl = softwareSystem "verl" "Distributed multi-GPU GRPO framework with FSDP" "External Library"
        gepaLib = softwareSystem "gepa" "Genetic-Pareto prompt optimization library" "External Library"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and tokenizer repository" "External Service"
        vllm = softwareSystem "vLLM" "LLM inference server for GRPO rollouts and GEPA evaluation" "External Service"
        wandb = softwareSystem "Weights & Biases" "Experiment tracking platform" "External Service"
        mlflow = softwareSystem "MLflow" "Experiment tracking and prompt registry" "External Service"
        tensorboard = softwareSystem "TensorBoard" "Training visualization via local event files" "External Service"
        itsHub = softwareSystem "ITS Hub" "Generation algorithms (BestOfN, SelfConsistency) for GRPO rollout strategies" "Internal RHOAI"

        dataScientist -> trainingHub "Calls sft(), osft(), lora_sft(), lora_grpo(), grpo(), gepa()" "Python API"
        rhoaiComponent -> trainingHub "Invokes training functions in managed containers" "Python API"

        trainingHub -> instructlabTraining "Uses as SFT backend" "Python import"
        trainingHub -> miniTrainer "Uses as OSFT backend" "Python import"
        trainingHub -> unsloth "Uses for LoRA model loading" "Python import"
        trainingHub -> trl "Uses SFTTrainer for LoRA training" "Python import"
        trainingHub -> art "Uses for single-GPU GRPO" "Subprocess"
        trainingHub -> verl "Uses for multi-GPU GRPO with FSDP" "Subprocess (Hydra)"
        trainingHub -> gepaLib "Uses for prompt optimization" "Python import"
        trainingHub -> huggingfaceHub "Downloads models and tokenizers" "HTTPS/443"
        trainingHub -> vllm "Inference rollouts for GRPO training" "HTTP (configurable)"
        trainingHub -> wandb "Uploads experiment metrics" "HTTPS/443"
        trainingHub -> mlflow "Tracks experiments, registers prompts" "HTTP/HTTPS (configurable)"
        trainingHub -> tensorboard "Writes event files locally" "Local filesystem"
        trainingHub -> itsHub "Uses generation algorithms as GRPO rollout strategies" "Python import (optional)"

        algorithmRegistry -> sftAlgorithm "Routes sft() calls"
        algorithmRegistry -> osftAlgorithm "Routes osft() calls"
        algorithmRegistry -> loraSftAlgorithm "Routes lora_sft() calls"
        algorithmRegistry -> grpoAlgorithm "Routes lora_grpo()/grpo() calls"
        algorithmRegistry -> gepaAlgorithm "Routes gepa() calls"
        sftAlgorithm -> torchrunUtils "Uses for distributed config"
        osftAlgorithm -> torchrunUtils "Uses for distributed config"
        loraSftAlgorithm -> peftExtender "Uses for LoRA param composition"
        grpoAlgorithm -> peftExtender "Uses for LoRA param composition"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External Library" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #E8A317
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

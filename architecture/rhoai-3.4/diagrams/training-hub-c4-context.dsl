workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Fine-tunes LLMs using training-hub API"

        trainingHub = softwareSystem "training-hub" "Unified Python library for multiple LLM fine-tuning algorithms with pluggable backends" {
            algorithmRegistry = container "Algorithm Registry" "Factory + lookup for algorithm/backend pairs" "Python Module"
            sftAlgorithm = container "SFT Algorithm" "Full-parameter supervised fine-tuning" "Python Module"
            osftAlgorithm = container "OSFT Algorithm" "Orthogonal subspace fine-tuning with SVD partial unfreezing" "Python Module"
            loraSftAlgorithm = container "LoRA SFT Algorithm" "LoRA parameter-efficient SFT with QLoRA support" "Python Module"
            loraGrpoAlgorithm = container "LoRA GRPO Algorithm" "Group Relative Policy Optimization with LoRA" "Python Module"
            memoryEstimator = container "Memory Estimator" "GPU memory estimation for SFT/OSFT/LoRA/QLoRA" "Python Module"
            timingEstimator = container "Timing Estimator" "Runtime estimation via subset extrapolation" "Python Module"
            visualization = container "Visualization" "Training loss curve plotting" "Python Module"
        }

        instructlabTraining = softwareSystem "InstructLab Training" "SFT training backend and data processing" "External Library"
        miniTrainer = softwareSystem "RHAI Mini-Trainer" "OSFT training backend" "External Library"
        unsloth = softwareSystem "Unsloth" "Optimized LoRA training backend" "External Library"
        art = softwareSystem "ART (OpenPipe)" "Single-GPU GRPO training" "External Library"
        verl = softwareSystem "verl" "Distributed multi-GPU GRPO training" "External Library"

        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External Service"
        wandb = softwareSystem "Weights & Biases" "Experiment tracking platform" "External Service"
        mlflow = softwareSystem "MLflow" "Experiment tracking and model registry" "External Service"
        torchrun = softwareSystem "PyTorch Distributed (torchrun)" "Multi-GPU gradient synchronization" "Infrastructure"
        vllm = softwareSystem "vLLM" "Inference server for GRPO rollouts" "External Library"
        pypi = softwareSystem "PyPI" "Python package distribution" "External Service"

        # User interactions
        user -> trainingHub "Calls sft(), osft(), lora_sft(), lora_grpo(), grpo(), estimate()" "Python API"

        # Backend delegations
        trainingHub -> instructlabTraining "Delegates SFT training" "In-process Python call"
        trainingHub -> miniTrainer "Delegates OSFT training" "In-process Python call"
        trainingHub -> unsloth "Delegates LoRA training" "In-process Python call"
        trainingHub -> art "Launches GRPO training (single-GPU)" "Subprocess + CLI"
        trainingHub -> verl "Launches GRPO training (multi-GPU)" "Subprocess + Hydra config"

        # External service connections
        trainingHub -> huggingfaceHub "Downloads models, tokenizers, datasets" "HTTPS/443, TLS 1.2+, HF_TOKEN"
        trainingHub -> wandb "Logs training metrics" "HTTPS/443, TLS 1.2+, API Key"
        trainingHub -> mlflow "Logs experiments and models" "HTTP(S), configurable"
        trainingHub -> torchrun "Coordinates multi-GPU training" "TCP/29500, no encryption"
        art -> vllm "Uses for GRPO rollout inference" "Co-located process"

        # Distribution
        trainingHub -> pypi "Published as pip package" "HTTPS/443, Sigstore signed"
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
            element "External Library" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #e74c3c
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

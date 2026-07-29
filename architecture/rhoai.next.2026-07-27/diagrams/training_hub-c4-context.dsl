workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Fine-tunes and trains language models using training_hub"

        trainingHub = softwareSystem "Training Hub" "Algorithm-focused Python library providing pluggable backend architecture for LM training, continual learning, and reinforcement learning" {
            convenienceFunctions = container "Convenience Functions" "User-facing API: sft(), osft(), lora_sft(), lora_grpo(), gepa()" "Python"
            algorithmRegistry = container "AlgorithmRegistry" "Runtime discovery and selection of algorithm-backend combinations" "Python"
            sftAlgorithm = container "SFT Algorithm" "Supervised fine-tuning strategy" "Python"
            osftAlgorithm = container "OSFT Algorithm" "Orthogonal supervised fine-tuning strategy" "Python"
            loraSftAlgorithm = container "LoRA SFT Algorithm" "Low-Rank Adaptation SFT strategy" "Python"
            loraGrpoAlgorithm = container "LoRA GRPO Algorithm" "Low-Rank Adaptation GRPO reinforcement learning strategy" "Python"
            gepaAlgorithm = container "GEPA Algorithm" "GEPA continual learning strategy" "Python"
            gpuProfiler = container "GPU Memory Profiler" "GPU memory profiling and estimation utilities" "Python"
            lossViz = container "Loss Visualization" "Training loss visualization module" "Python"
        }

        instructlabTraining = softwareSystem "instructlab-training" "InstructLab training framework backend" "External Framework" {
            tags "External"
        }
        miniTrainer = softwareSystem "rhai-innovation-mini-trainer" "RHAI Innovation mini-trainer framework backend" "External Framework" {
            tags "External"
        }
        unsloth = softwareSystem "Unsloth" "Unsloth training framework for LoRA fine-tuning" "External Framework" {
            tags "External"
        }
        art = softwareSystem "OpenPipe ART" "Autonomous Reasoning Tuning framework with vLLM engine management" "External Framework" {
            tags "External"
        }
        verl = softwareSystem "verl" "Volcano Engine RL framework for distributed GRPO training via Ray/torchrun" "External Framework" {
            tags "External"
        }
        gepaPkg = softwareSystem "GEPA Package" "GEPA continual learning framework" "External Framework" {
            tags "External"
        }

        llmApi = softwareSystem "LLM API" "OpenAI-compatible API for GRPO reward scoring (via litellm)" "External Service" {
            tags "External Service"
        }
        mlflow = softwareSystem "MLflow" "ML experiment tracking and metric logging server" "External Service" {
            tags "External Service"
        }
        wandb = softwareSystem "Weights & Biases" "ML experiment tracking and visualization platform" "External Service" {
            tags "External Service"
        }

        pytorch = softwareSystem "PyTorch" "Deep learning framework (torch, FSDP, distributed)" "External" {
            tags "External"
        }
        transformers = softwareSystem "Transformers" "Hugging Face model library" "External" {
            tags "External"
        }

        # Relationships
        user -> trainingHub "Imports and calls training functions" "Python API"
        convenienceFunctions -> algorithmRegistry "Looks up algorithm-backend pair"
        algorithmRegistry -> sftAlgorithm "Dispatches"
        algorithmRegistry -> osftAlgorithm "Dispatches"
        algorithmRegistry -> loraSftAlgorithm "Dispatches"
        algorithmRegistry -> loraGrpoAlgorithm "Dispatches"
        algorithmRegistry -> gepaAlgorithm "Dispatches"

        sftAlgorithm -> instructlabTraining "In-process training call"
        sftAlgorithm -> miniTrainer "In-process training call"
        osftAlgorithm -> instructlabTraining "In-process training call"
        loraSftAlgorithm -> unsloth "In-process training call"
        loraGrpoAlgorithm -> art "Co-located vLLM engine management"
        loraGrpoAlgorithm -> verl "Subprocess: Ray/torchrun workers"
        gepaAlgorithm -> gepaPkg "In-process training call"

        loraGrpoAlgorithm -> llmApi "GRPO reward scoring" "HTTPS/443"
        trainingHub -> mlflow "Metrics and parameter logging" "HTTPS"
        trainingHub -> wandb "Training metrics logging" "HTTPS/443"

        trainingHub -> pytorch "Deep learning primitives"
        trainingHub -> transformers "Model loading and tokenization"
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
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Framework" {
                background #7b68ee
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

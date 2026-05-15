workspace {
    model {
        dataScientist = person "Data Scientist" "Fine-tunes LLMs using training-hub SDK in notebooks or GPU machines"

        trainingHub = softwareSystem "training-hub" "Unified Python SDK for LLM fine-tuning across multiple algorithms (SFT, OSFT, LoRA, GRPO) and backends" {
            publicAPI = container "Public API" "Top-level functions: sft(), osft(), lora_sft(), lora_grpo(), grpo()" "Python Module"
            algorithmRegistry = container "Algorithm Registry" "Strategy pattern mapping (algorithm, backend) tuples to implementations" "Python Module"
            paramTranslation = container "Parameter Translation" "Converts consistent API params to backend-native formats" "Python Module"

            sftBackend = container "SFT Backend" "Full-parameter supervised fine-tuning via instructlab-training" "Python Module"
            osftBackend = container "OSFT Backend" "Orthogonal Subspace Fine-Tuning via mini-trainer" "Python Module"
            loraSFTBackend = container "LoRA SFT Backend" "Parameter-efficient fine-tuning via Unsloth with QLoRA" "Python Module"
            loraGRPOBackend = container "LoRA GRPO Backend" "RL from verifiable rewards via ART or verl" "Python Module"
            fullGRPOBackend = container "Full GRPO Backend" "Full-parameter GRPO via verl with FSDP" "Python Module"

            memoryEstimator = container "Memory Estimator" "Per-algorithm GPU VRAM calculators with lower/expected/upper bounds" "Python Module"
            timingEstimator = container "Timing Estimator" "Sample-based training time extrapolation" "Python Module"
            visualization = container "Visualization" "Loss curve plotting with multi-run comparison and EMA smoothing" "Python Module"
        }

        instructlabTraining = softwareSystem "instructlab-training" "SFT training engine and data processor" "External PyPI"
        miniTrainer = softwareSystem "rhai-innovation-mini-trainer" "OSFT training engine" "External PyPI"
        unsloth = softwareSystem "Unsloth" "Optimized LoRA training with Triton kernels" "External PyPI"
        artBackendSys = softwareSystem "openpipe-art" "Single-GPU LoRA GRPO with vLLM rollouts" "External PyPI"
        verlBackendSys = softwareSystem "verl" "Distributed multi-GPU GRPO with FSDP and vLLM" "External PyPI"

        pytorch = softwareSystem "PyTorch" "Deep learning framework with torchrun distributed training" "External"
        transformers = softwareSystem "HuggingFace Transformers" "Model loading, tokenization, AutoConfig" "External PyPI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Pretrained model and dataset repository" "External Service"
        wandb = softwareSystem "Weights & Biases" "Experiment tracking and metrics platform" "External Service"
        mlflow = softwareSystem "MLflow" "Experiment tracking and model registry" "External Service"
        tensorboard = softwareSystem "TensorBoard" "Training visualization via local log files" "External"
        localGPU = softwareSystem "Local GPU(s)" "NVIDIA GPU hardware with CUDA/NCCL" "Infrastructure"

        dataScientist -> trainingHub "Calls fine-tuning functions via Python API"
        trainingHub -> instructlabTraining "Delegates SFT training" "In-process Python API"
        trainingHub -> miniTrainer "Delegates OSFT training" "In-process Python API"
        trainingHub -> unsloth "Delegates LoRA SFT training" "In-process Python API"
        trainingHub -> artBackendSys "Delegates single-GPU GRPO" "Subprocess"
        trainingHub -> verlBackendSys "Delegates multi-GPU GRPO" "CLI / torchrun"
        trainingHub -> pytorch "Training execution and distributed orchestration" "In-process / torchrun"
        trainingHub -> transformers "Model loading and tokenization" "In-process Python API"
        trainingHub -> huggingfaceHub "Downloads models, tokenizers, datasets, configs" "HTTPS/443 TLS 1.2+"
        trainingHub -> wandb "Logs experiment metrics" "HTTPS/443 TLS 1.2+"
        trainingHub -> mlflow "Logs experiment metrics" "HTTP(S) configurable"
        trainingHub -> tensorboard "Writes training logs" "Local filesystem"
        trainingHub -> localGPU "Executes training workloads" "CUDA / NCCL"
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
            element "External PyPI" {
                background #b8860b
                color #ffffff
            }
            element "External Service" {
                background #cc6600
                color #ffffff
            }
            element "Infrastructure" {
                background #666666
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

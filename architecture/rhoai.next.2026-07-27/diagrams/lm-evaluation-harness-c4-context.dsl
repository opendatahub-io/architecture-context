workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Runs LLM evaluation benchmarks via CLI"
        ciPipeline = person "CI Pipeline" "Automated evaluation orchestration"

        lmEvalHarness = softwareSystem "lm-evaluation-harness" "CLI-driven language model evaluation framework with pluggable model backends for automated LLM benchmarking" {
            cliEntryPoint = container "lm-eval CLI" "CLI entry point parsing arguments, orchestrating evaluation, outputting results" "Python CLI"
            taskManager = container "TaskManager" "Loads and configures benchmark tasks from YAML definitions" "Python Module"
            evaluator = container "Evaluator" "Runs simple_evaluate() loop across tasks and samples, scores results" "Python Module"
            modelBackends = container "Model Backends" "Plugin registry of model backends: HuggingFace, Anthropic, OpenAI, Watsonx, Local" "Python Plugins"
            s3Downloader = container "S3 Downloader" "Utility script for pre-fetching evaluation assets from S3-compatible storage" "Python Script"
            evalHubAdapter = container "eval-hub-sdk Adapter" "Integration adapter for RHOAI platform evaluation orchestration" "Python SDK v0.4.4"
        }

        anthropicAPI = softwareSystem "Anthropic API" "LLM inference service for Claude models" "External"
        openaiAPI = softwareSystem "OpenAI API" "LLM inference service for GPT models" "External"
        watsonxAPI = softwareSystem "IBM Watsonx AI" "IBM LLM inference service" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model weights, datasets, and results hosting" "External"
        huggingfaceDatasets = softwareSystem "HuggingFace Datasets Server" "Dataset retrieval API" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Evaluation asset storage (AWS S3 or compatible)" "External"
        wandb = softwareSystem "Weights & Biases" "Optional experiment tracking and metrics logging" "External"

        # User interactions
        user -> lmEvalHarness "Runs lm-eval CLI with model and task arguments"
        ciPipeline -> lmEvalHarness "Invokes evaluation via eval-hub-sdk adapter"

        # Internal flows
        cliEntryPoint -> taskManager "Loads task configurations"
        cliEntryPoint -> evaluator "Runs evaluation"
        evaluator -> modelBackends "Instantiates selected backend"
        cliEntryPoint -> evalHubAdapter "Platform orchestration"

        # External dependencies
        modelBackends -> anthropicAPI "LLM inference requests" "HTTPS/443 API Key"
        modelBackends -> openaiAPI "LLM inference requests" "HTTPS/443 API Key"
        modelBackends -> watsonxAPI "LLM inference requests" "HTTPS/443 API Key"
        modelBackends -> huggingfaceHub "Downloads model weights" "HTTPS/443 HF_TOKEN"
        taskManager -> huggingfaceHub "Downloads task datasets" "HTTPS/443"
        taskManager -> huggingfaceDatasets "Retrieves datasets" "HTTPS/443"
        s3Downloader -> s3Storage "Pre-fetches evaluation assets" "HTTPS AWS IAM"
        lmEvalHarness -> huggingfaceHub "Pushes evaluation results" "HTTPS/443 HF_TOKEN"
        lmEvalHarness -> wandb "Logs metrics (optional)" "HTTPS/443"
    }

    views {
        systemContext lmEvalHarness "SystemContext" {
            include *
            autoLayout
        }

        container lmEvalHarness "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #7ed321
                color #ffffff
            }
        }
    }
}

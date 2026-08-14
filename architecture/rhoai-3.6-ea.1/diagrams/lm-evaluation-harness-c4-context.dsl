workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Configures and triggers model evaluations"

        lmEvalHarness = softwareSystem "lm-evaluation-harness" "Batch-oriented Python framework for language model evaluation, packaged as odh-ta-lmes-job-rhel9 container image" {
            lmEvalCLI = container "lm-eval CLI" "Console script entry point for evaluation runs" "Python 3.11"
            modelBackends = container "Model Backends" "Plugin-based LLM connectors: openai, anthropic, watsonx, local-chat-completions" "Python"
            evalFramework = container "Evaluation Framework" "lm_eval core with Unitxt catalog for standardized task definitions" "Python"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Creates and manages evaluation Kubernetes Jobs" "Internal RHOAI"

        openaiAPI = softwareSystem "OpenAI API" "LLM inference provider" "External"
        anthropicAPI = softwareSystem "Anthropic API" "LLM inference provider" "External"
        watsonxAPI = softwareSystem "IBM watsonx API" "LLM inference provider" "External"
        servingRuntime = softwareSystem "Model Serving Runtime" "In-cluster vLLM/Caikit with OpenAI-compatible API" "Internal RHOAI"

        huggingFace = softwareSystem "Hugging Face Hub" "Evaluation datasets, models, and tokenizers" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifacts and dataset storage" "External"

        kubeAPI = softwareSystem "Kubernetes API" "Cluster orchestration and job management" "Infrastructure"

        datascientist -> trustyaiOperator "Triggers evaluation via TrustyAI API"
        trustyaiOperator -> kubeAPI "Creates Kubernetes Job" "Kubernetes API"
        trustyaiOperator -> lmEvalHarness "Launches as Kubernetes Job with env vars and args"

        lmEvalHarness -> openaiAPI "Sends evaluation prompts" "HTTPS/443, API key"
        lmEvalHarness -> anthropicAPI "Sends evaluation prompts" "HTTPS/443, API key"
        lmEvalHarness -> watsonxAPI "Sends evaluation prompts" "HTTPS/443, API key"
        lmEvalHarness -> servingRuntime "Sends evaluation prompts" "HTTP(S), API key"
        lmEvalHarness -> huggingFace "Downloads datasets, models, tokenizers" "HTTPS/443, HF_TOKEN"
        lmEvalHarness -> s3Storage "Downloads model artifacts" "HTTPS/443, AWS credentials"

        lmEvalCLI -> evalFramework "Orchestrates evaluation"
        evalFramework -> modelBackends "Dispatches inference requests"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

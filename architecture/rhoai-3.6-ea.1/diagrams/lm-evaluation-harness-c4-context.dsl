workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Defines evaluation benchmarks and reviews model quality metrics"

        lmEvalHarness = softwareSystem "lm-evaluation-harness" "Batch-oriented evaluation runtime for language models, executing benchmarks against OpenAI-compatible endpoints" {
            adapter = container "LMEvalAdapter" "EvalHub FrameworkAdapter that translates JobSpec into lm-eval calls" "Python"
            lmEvalFramework = container "lm-eval Framework" "EleutherAI evaluation framework (simple_evaluate)" "Python Library"
            localCompletions = container "local-completions Backend" "HTTP client for OpenAI-compatible completions API" "Python HTTP Client"
            credResolver = container "Credential Resolver" "Resolves model endpoint credentials via EvalHub SDK" "Python"
            errorSanitizer = container "Error Sanitizer" "Redacts credentials from error messages before callback" "Python"

            adapter -> lmEvalFramework "Invokes simple_evaluate()"
            lmEvalFramework -> localCompletions "Sends prompt batches"
            adapter -> credResolver "Resolves API keys"
            adapter -> errorSanitizer "Sanitizes error output"
        }

        evalHub = softwareSystem "EvalHub Service" "Job orchestration, status reporting, and result collection for ML evaluation workloads" "Internal RHOAI"
        modelServing = softwareSystem "Model Serving Endpoint" "OpenAI-compatible inference endpoint (vLLM, KServe)" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Dataset and tokenizer repository" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for data artifacts" "External"

        evalHub -> lmEvalHarness "Dispatches JobSpec" "EvalHub SDK"
        lmEvalHarness -> evalHub "Returns EvaluationResult, status callbacks" "EvalHub SDK"
        lmEvalHarness -> modelServing "POST /v1/completions" "HTTPS, API Key"
        lmEvalHarness -> huggingfaceHub "Downloads datasets and tokenizers" "HTTPS/443, HF_TOKEN"
        lmEvalHarness -> s3Storage "Retrieves data artifacts" "HTTPS, AWS IAM"
        datascientist -> evalHub "Configures evaluation benchmarks"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

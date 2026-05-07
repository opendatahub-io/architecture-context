workspace {
    model {
        dataScientist = person "Data Scientist" "Triggers LM evaluations via TrustyAI LMEval CRs"

        lmEvalHarness = softwareSystem "lm-evaluation-harness" "Framework for evaluating language models through standardized benchmarks, deployed as a batch Kubernetes Job" {
            cli = container "CLI Entry Point" "Parses arguments, configures evaluation, invokes evaluator" "Python CLI (__main__.py)"
            evaluator = container "Evaluator Engine" "Orchestrates model loading, task execution, metric computation" "Python (evaluator.py)"
            modelRegistry = container "Model Registry" "Plugin registry for model backends (HF, vLLM, OpenAI, WatsonX, etc.)" "Python Registry"
            taskRegistry = container "Task Registry" "Dynamic YAML-based task loader with 144+ benchmark categories" "Python + YAML"
            metricEngine = container "Metric Engine" "Computes accuracy, BLEU, perplexity, WER, and custom metrics" "Python (HF Evaluate + Unitxt)"
            responseCache = container "Response Cache" "SQLite-based LM response cache indexed by SHA-256 hashes" "SQLite + Python"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Creates and manages Kubernetes Jobs for LMEval evaluations" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for Job scheduling and management" "Infrastructure"

        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for models, datasets, and results" "External"
        watsonxAI = softwareSystem "IBM WatsonX AI" "IBM hosted model inference platform" "External"
        openaiAPI = softwareSystem "OpenAI-compatible API" "Model inference via OpenAI-compatible endpoints" "External"
        anthropicAPI = softwareSystem "Anthropic API" "Anthropic model inference" "External"
        textSynthAPI = softwareSystem "TextSynth API" "TextSynth model inference" "External"
        wandb = softwareSystem "Weights & Biases" "Experiment tracking and metric logging" "External"

        # Relationships - External
        dataScientist -> trustyaiOperator "Creates LMEval CR via kubectl/dashboard"
        trustyaiOperator -> kubernetesAPI "Creates batch Job" "HTTPS/443"
        kubernetesAPI -> lmEvalHarness "Schedules and runs Pod"

        # Relationships - lm-evaluation-harness to external
        lmEvalHarness -> huggingfaceHub "Downloads models and datasets" "HTTPS/443 Bearer Token"
        lmEvalHarness -> s3Storage "Downloads/uploads models, datasets, results" "HTTPS/443 AWS IAM"
        lmEvalHarness -> watsonxAI "Evaluates models on WatsonX" "HTTPS/443 API Key"
        lmEvalHarness -> openaiAPI "Evaluates via OpenAI-compatible endpoints" "HTTPS API Key"
        lmEvalHarness -> anthropicAPI "Evaluates Anthropic models" "HTTPS/443 API Key"
        lmEvalHarness -> textSynthAPI "Evaluates TextSynth models" "HTTPS/443 API Key"
        lmEvalHarness -> wandb "Logs experiment metrics (optional)" "HTTPS/443 API Key"

        # Internal container relationships
        cli -> evaluator "Invokes evaluation"
        evaluator -> modelRegistry "Loads model backend"
        evaluator -> taskRegistry "Loads evaluation tasks"
        evaluator -> metricEngine "Computes metrics"
        evaluator -> responseCache "Caches/retrieves LM responses"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #e8e8e8
                color #333333
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

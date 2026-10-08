workspace {
    model {
        dataScientist = person "Data Scientist" "Defines evaluation jobs and reviews results"
        mlEngineer = person "ML Engineer" "Deploys models and validates quality"

        evalHubContrib = softwareSystem "eval-hub-contrib" "Community-contributed evaluation framework adapters packaged as K8s Job containers" {
            inspectAdapter = container "Inspect AI Adapter" "UK AISI Inspect AI with Petri/Bloom alignment auditing and 75+ benchmarks" "Python Container (Konflux)"
            lightEvalAdapter = container "LightEval Adapter" "HuggingFace LightEval for commonsense, reasoning, truthfulness evaluation" "Python Container (Konflux)"
            guideLLMAdapter = container "GuideLLM Adapter" "LLM inference server performance benchmarking" "Python Container"
            mtebAdapter = container "MTEB Adapter" "Massive Text Embedding Benchmark for embedding models" "Python Container"
            clearAdapter = container "CLEAR Adapter" "IBM CLEAR agentic trace analysis with LLM-as-judge" "Python Container"
            deepEvalAdapter = container "DeepEval Adapter" "LLM-as-judge for faithfulness, relevancy, hallucination" "Python Container"
            ragasAdapter = container "RAGAS Adapter" "RAG pipeline quality evaluation" "Python Container"
            swebenchAdapter = container "SWE-bench Adapter" "Software engineering benchmark via child K8s Jobs" "Python Container"
            rulerAdapter = container "RULER Adapter" "NVIDIA RULER long-context benchmark" "Python Container"
            wildGuardAdapter = container "WildGuard Adapter" "AllenAI safety classification benchmark" "Python Container"
            ifBenchAdapter = container "IFBench Adapter" "AllenAI instruction-following benchmark" "Python Container"
            nemoAdapter = container "NeMo Guardrails Adapter" "NVIDIA NeMo safety rail evaluation" "Python Container"
        }

        evalHub = softwareSystem "eval-hub" "Orchestration service that schedules and manages evaluation adapter jobs" "Internal RHOAI"
        evalHubSDK = softwareSystem "evalhub-sdk" "Framework adapter SDK providing FrameworkAdapter base class and callback mechanism" "Internal RHOAI"

        openAI = softwareSystem "OpenAI-compatible Endpoint" "LLM inference endpoint (vLLM, Ollama, OpenRouter)" "External"
        anthropic = softwareSystem "Anthropic API" "Claude model inference API" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Dataset and model repository" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking server" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for Job management" "Infrastructure"
        ociRegistry = softwareSystem "OCI Registry" "Container and artifact registry" "External"

        dataScientist -> evalHub "Defines evaluation jobs"
        evalHub -> evalHubContrib "Schedules adapter K8s Jobs" "ConfigMap + K8s RBAC"
        evalHubContrib -> evalHubSDK "Implements FrameworkAdapter" "Python SDK"
        evalHubContrib -> evalHub "Reports results via sidecar" "HTTP localhost"
        evalHubContrib -> openAI "Model inference" "HTTPS/443"
        evalHubContrib -> anthropic "Claude inference" "HTTPS/443"
        evalHubContrib -> huggingFace "Dataset downloads" "HTTPS/443"
        evalHubContrib -> mlflow "Experiment tracking" "HTTPS/8443"
        evalHubContrib -> k8sAPI "Child Job management (SWE-bench)" "HTTPS/443"
        evalHubContrib -> ociRegistry "Artifact persistence" "HTTPS/443"
    }

    views {
        systemContext evalHubContrib "SystemContext" {
            include *
            autoLayout
        }

        container evalHubContrib "Containers" {
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
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}

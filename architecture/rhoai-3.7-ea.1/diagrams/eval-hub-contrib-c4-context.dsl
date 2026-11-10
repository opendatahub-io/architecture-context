workspace "eval-hub-contrib" "RHOAI 3.7-ea.1 evaluation framework adapters" {
    model {
        user = person "Data Scientist" "Submits model evaluation jobs through eval-hub"

        evalHubContrib = softwareSystem "eval-hub-contrib" "Containerized evaluation-framework adapters launched by eval-hub as Kubernetes Jobs" {
            lighteval = container "LightEval adapter" "odh-eval-hub-lighteval-rhel9; LightEval 0.13.0 via LiteLLM; 28 benchmarks; loglikelihood via /v1/completions echo+logprobs" "Python 3.12 batch Job"
            inspect = container "Inspect AI adapter" "odh-eval-hub-inspectai-rhel9; inspect-ai 0.3.278 subprocess; Petri, Bloom, inspect-evals; auditor/judge/grader roles" "Python 3.12 batch Job"
            providerCatalog = container "provider.yaml catalogs" "Benchmarks, metrics, primary scores, runtime.k8s image/entrypoint/resources" "YAML"
            community = container "Community adapters" "15 upstream-only adapters + post-processor (not productized on this branch)" "Python batch Job" "Upstream"
        }

        evalHub = softwareSystem "eval-hub" "TrustyAI EvalHub service: launches Jobs, injects sidecar, projects secrets, receives results" "Internal RHOAI"
        sidecar = softwareSystem "eval-hub sidecar" "localhost:8080 model proxy with credential substitution and callback relay" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes API" "Job scheduling" "Internal RHOAI"
        modelServing = softwareSystem "Model Serving" "KServe / vLLM OpenAI-compatible endpoints" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking" "Internal RHOAI"
        konflux = softwareSystem "Konflux / konflux-central" "Hermetic multi-arch image builds" "Internal RHOAI"
        aipcc = softwareSystem "AIPCC base images and curated Python index" "Build-time base images and wheels" "Internal RHOAI"

        judge = softwareSystem "Judge endpoint" "api.openai.com (default) or OPENAI_JUDGE_BASE_URL" "External"
        anthropic = softwareSystem "Anthropic API" "Optional role/target model" "External"
        hf = softwareSystem "Hugging Face Hub" "Benchmark datasets and tokenizers" "External"
        github = softwareSystem "GitHub" "Inspect task assets, NLTK data" "External"
        oci = softwareSystem "OCI Registry" "Result artifact export" "External"

        user -> evalHub "Submits evaluation job"
        evalHub -> providerCatalog "Reads runtime.k8s definitions"
        evalHub -> k8s "Creates adapter Job" "HTTPS/6443"
        k8s -> lighteval "Runs as Job pod"
        k8s -> inspect "Runs as Job pod"
        lighteval -> sidecar "OpenAI API with reference token" "HTTP/8080 localhost"
        inspect -> sidecar "OpenAI-compatible calls, callbacks" "HTTP/8080 localhost"
        sidecar -> modelServing "Forwards with real key or SA token" "HTTP/HTTPS"
        sidecar -> evalHub "Relays JobPhase status and results" "HTTP"
        inspect -> judge "LLM-as-judge scoring" "HTTPS/443"
        inspect -> anthropic "Optional model role" "HTTPS/443"
        lighteval -> hf "Downloads datasets (unless offline)" "HTTPS/443"
        inspect -> hf "Downloads datasets (unless offline)" "HTTPS/443"
        inspect -> github "Downloads task assets" "HTTPS/443"
        lighteval -> mlflow "Saves metrics and artifacts" "HTTP(S)"
        inspect -> mlflow "Saves metrics and artifacts" "HTTP(S)"
        lighteval -> oci "Pushes result files" "HTTPS/443"
        inspect -> oci "Pushes Inspect logs" "HTTPS/443"
        konflux -> evalHubContrib "Builds productized images"
        aipcc -> evalHubContrib "Supplies base images and wheels"
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
            element "Upstream" {
                background #dddddd
                border dashed
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

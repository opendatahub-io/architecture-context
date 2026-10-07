workspace {
    model {
        user = person "Benchmark Operator" "Data scientist or CI system running LLM inference benchmarks"

        llmdbenchmark = softwareSystem "llm-d-benchmark" "Automated benchmarking and performance evaluation framework for the llm-d LLM inference stack" {
            cli = container "llmdbenchmark CLI" "Main CLI entry point for standup, run, teardown, experiment, plan subcommands" "Python 3.13+"
            configEngine = container "Configuration Engine" "Jinja2 template rendering with layered YAML merge chain (defaults -> scenario -> spec -> CLI overrides)" "Python"
            stepExecutor = container "StepExecutor" "Phased step orchestration with parallelism, dry-run, and error aggregation" "Python"
            doeEngine = container "DoE Engine" "Design of Experiments engine for automated parameter sweeps" "Python"
            benchReport = container "benchmark-report" "Universal Benchmark Report schema (v0.2) for structured result output" "Python Library"
            stackDiscovery = container "llm_d_stack_discovery" "Traces deployed llm-d stacks from endpoint URL through Gateway/Route/InferencePool topology" "Python CLI"
            benchImage = container "Benchmark Container" "Heavyweight image bundling inference-perf, guidellm, vllm-benchmark, aiperf, lm-eval, plus oc/gcloud/aws CLIs" "Container Image"
        }

        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift" "Red Hat Kubernetes distribution with Routes and enhanced security" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API with HTTPRoute resources" "External"
        gaie = softwareSystem "GAIE" "Gateway API Inference Extension - InferencePool and InferenceModel CRDs" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model hosting and metadata service" "External"
        gcs = softwareSystem "Google Cloud Storage" "Cloud object storage for benchmark results" "External"
        s3 = softwareSystem "AWS S3" "Cloud object storage for benchmark results" "External"
        helm = softwareSystem "Helm" "Kubernetes package manager for modelservice deployments" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"
        inferenceEndpoint = softwareSystem "Inference Endpoint" "Target LLM inference service under benchmark" "External"
        modelService = softwareSystem "llm-d-modelservice" "Helm-based llm-d inference stack deployment" "Internal"
        llmdInfra = softwareSystem "llm-d-infra" "Cluster-level infrastructure components (CRDs, controllers)" "Internal"

        user -> llmdbenchmark "Runs benchmarks via CLI or deploys as StatefulSet"
        cli -> configEngine "Renders configurations"
        cli -> stepExecutor "Executes lifecycle phases"
        cli -> doeEngine "Drives parameter sweeps"
        stepExecutor -> benchReport "Generates structured results"
        cli -> k8s "Creates/manages resources via kubectl and Python SDK" "HTTPS/443"
        cli -> helm "Deploys modelservice charts" "CLI"
        cli -> hfHub "Validates model access and loads metadata" "HTTPS/443"
        cli -> gcs "Uploads benchmark results" "HTTPS/443"
        cli -> s3 "Uploads benchmark results" "HTTPS/443"
        benchImage -> inferenceEndpoint "Sends benchmark load" "HTTP/8080"
        stackDiscovery -> k8s "Queries Gateway, Route, InferencePool resources" "HTTPS/443"
        stackDiscovery -> gaie "Traces InferencePool/InferenceModel topology" "HTTPS/443"
        llmdbenchmark -> openshift "Discovers Routes for endpoint access" "HTTPS/443"
        llmdbenchmark -> gatewayAPI "Discovers Gateway and HTTPRoute resources" "HTTPS/443"
        llmdbenchmark -> prometheus "Optional metrics scraping via PodMonitor" "HTTPS"
        llmdbenchmark -> modelService "Deploys via Helm charts"
        llmdInfra -> llmdbenchmark "Provides prerequisite CRDs and controllers"
    }

    views {
        systemContext llmdbenchmark "SystemContext" {
            include *
            autoLayout
        }

        container llmdbenchmark "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

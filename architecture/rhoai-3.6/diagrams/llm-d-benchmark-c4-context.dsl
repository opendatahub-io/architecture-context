workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Runs benchmarks to evaluate LLM inference performance"
        ciPipeline = person "CI/CD Pipeline" "Automated benchmark execution in CI"

        llmdbenchmark = softwareSystem "llm-d-benchmark" "Automated end-to-end benchmarking framework for LLM inference stacks" {
            cli = container "llmdbenchmark CLI" "Orchestrates benchmark lifecycle: plan, standup, run, teardown" "Python 3.14+ CLI"
            renderPlans = container "RenderPlans Engine" "Jinja2 template merge chain for reproducible experiment configuration" "Python Module"
            stepExecutor = container "StepExecutor" "Sequential step runner for lifecycle phases" "Python Module"
            harnessContainer = container "Harness Container" "StatefulSet running benchmarking harnesses (inference-perf, vllm-benchmark, guidellm, aiperf, lm-eval)" "Container Image"
            resultsStore = container "Results Store" "Pluggable storage backend with GCS direct and GCS proxy clients" "Python Module"
            stackDiscovery = container "llm_d_stack_discovery" "Traces llm-d serving stack from Gateway to Pod" "Python CLI Tool"
            benchmarkReport = container "benchmark-report" "Schema library for structured benchmark report format" "Python Library"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster operations, namespace management, workload deployment" "External"
        gcs = softwareSystem "Google Cloud Storage" "Benchmark results persistence" "External"
        prismProxy = softwareSystem "Prism Proxy" "Read-only GCS fallback via prism.llm-d.ai" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model metadata, tokenizer config, gated access" "External"
        llmEndpoint = softwareSystem "LLM Inference Endpoint" "Target system under benchmark load" "External"
        gatewayApi = softwareSystem "Gateway API" "Kubernetes Gateway/HTTPRoute resources for stack discovery" "External"
        openshift = softwareSystem "OpenShift" "Platform detection, Route creation, ClusterVersion" "External"

        # User relationships
        user -> llmdbenchmark "Runs benchmarks via CLI"
        ciPipeline -> llmdbenchmark "Automates benchmark execution"

        # Internal relationships
        cli -> renderPlans "Renders experiment configuration"
        cli -> stepExecutor "Executes lifecycle phases"
        stepExecutor -> harnessContainer "Deploys and monitors"
        harnessContainer -> resultsStore "Stores results"
        harnessContainer -> benchmarkReport "Structures output"
        stackDiscovery -> benchmarkReport "Generates reports"

        # External relationships
        cli -> k8sApi "Provisions infrastructure, deploys workloads" "HTTPS/6443"
        cli -> huggingfaceHub "Verifies model access, fetches metadata" "HTTPS/443"
        harnessContainer -> llmEndpoint "Generates benchmark load" "HTTP/HTTPS"
        resultsStore -> gcs "Uploads/downloads results" "HTTPS/443"
        resultsStore -> prismProxy "Read-only fallback" "HTTPS/443"
        stackDiscovery -> k8sApi "Traces Gateway → HTTPRoute → Service → Pod" "HTTPS/6443"
        stackDiscovery -> gatewayApi "Reads Gateway API resources" "HTTPS/6443"
        cli -> openshift "Platform detection, Route creation" "HTTPS/6443"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

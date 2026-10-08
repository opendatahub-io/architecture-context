workspace {
    model {
        user = person "Developer / SRE" "Runs benchmark experiments against LLM inference endpoints"
        ciPipeline = person "CI Pipeline" "Automates benchmark runs in CI/CD workflows"

        llmDBenchmark = softwareSystem "llm-d-benchmark" "End-to-end benchmarking automation for LLM inference on the llm-d stack" {
            cli = container "llmdbenchmark CLI" "Orchestrates benchmark lifecycle: standup, run, analysis, teardown" "Python 3.14+ CLI"
            harnessImage = container "Benchmark Harness Image" "Bundles 6 benchmark harnesses (inference-perf, guidellm, vllm-benchmark, aiperf, lm-eval, inferencemax) for in-cluster execution" "StatefulSet Container"
            stackDiscovery = container "llm-d-stack-discovery" "Traces deployed llm-d stack topology from endpoint URL through K8s resources" "Python CLI"
            benchmarkReport = container "benchmark-report" "Benchmark Report v0.2 schemas, validators, and converters" "Python Library"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster resource management and operations" "External"
        gatewayAPI = softwareSystem "Gateway API" "Gateway, HTTPRoute, GatewayClass resources" "External"
        gaie = softwareSystem "GAIE (InferencePool/InferenceModel)" "Inference pool and model configuration discovery" "External"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Route-based endpoint exposure" "External"
        serviceMonitor = softwareSystem "ServiceMonitor" "Prometheus-based workload monitoring" "External"

        gcs = softwareSystem "Google Cloud Storage" "Benchmark result storage and retrieval" "External"
        prismProxy = softwareSystem "Prism Proxy" "GCS fallback proxy at prism.llm-d.ai" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model metadata, access verification, tokenizer config" "External"
        vllmEndpoint = softwareSystem "vLLM Inference Endpoint" "Target LLM serving endpoint for benchmark workloads" "External"
        telemetry = softwareSystem "Telemetry Endpoint" "Optional benchmark telemetry reporting" "External"

        # User interactions
        user -> cli "Runs benchmark experiments via CLI"
        ciPipeline -> cli "Automates benchmark runs"
        user -> stackDiscovery "Discovers deployed stack topology"

        # Internal flows
        cli -> harnessImage "Deploys and executes benchmark workloads"
        harnessImage -> benchmarkReport "Produces structured results"
        stackDiscovery -> benchmarkReport "Outputs discovery in Report v0.2 format"

        # External integrations
        cli -> k8sAPI "Deploy, monitor, discover, teardown" "HTTPS/443"
        cli -> gcs "Store benchmark results" "HTTPS/443 Google ADC"
        cli -> prismProxy "GCS fallback access" "HTTPS/443 Bearer"
        cli -> hfHub "Model access and tokenizer config" "HTTPS/443 Bearer"
        cli -> telemetry "Report benchmark telemetry" "HTTPS"
        harnessImage -> vllmEndpoint "Send benchmark inference requests" "HTTP(S)/8000-8200"
        stackDiscovery -> k8sAPI "Discover Routes, Gateways, Pools, Pods" "HTTPS/443"
        stackDiscovery -> gatewayAPI "Query Gateway and HTTPRoute resources" "via K8s API"
        stackDiscovery -> gaie "Query InferencePool and InferenceModel" "via K8s API"
        stackDiscovery -> openshiftRoutes "Query OpenShift Routes" "via K8s API"
        prismProxy -> gcs "Forward storage requests" "HTTPS/443"
    }

    views {
        systemContext llmDBenchmark "SystemContext" {
            include *
            autoLayout
        }

        container llmDBenchmark "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

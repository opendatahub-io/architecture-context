workspace {
    model {
        sre = person "SRE / Platform Engineer" "Configures autoscaling strategies and monitors scaling behavior"
        datascientist = person "Data Scientist" "Deploys inference models that are autoscaled"

        llmdAutoscaling = softwareSystem "llm-d-autoscaling" "KEDA autoscaling blueprints and evaluation test bed for llm-d inference deployments" {
            kedaBlueprints = container "KEDA Blueprint Scenarios" "Recommended ScaledObject configurations for prefill/decode disaggregated autoscaling" "YAML Manifests"
            clusterOverlays = container "Cluster Config Overlays" "Backend-specific overlays (k8s inference-sim, OCP vLLM, OCP model-sim)" "YAML Manifests"
            benchmarkTestBed = container "Benchmark Evaluation Test Bed" "Autoscaling evaluation harness using llm-d-benchmark" "YAML/Jinja2 Specs"
            grafanaDashboard = container "Grafana Dashboard" "Pre-built dashboard for visualizing autoscaling benchmark results" "JSON"
            wvaController = container "WVA Controller (Legacy)" "Deprecated custom autoscaling controller with Kalman filters" "Go Operator" {
                tags "Deprecated"
            }
        }

        keda = softwareSystem "KEDA" "Kubernetes Event-Driven Autoscaling operator" "External"
        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics collection and querying platform" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        gatewayApiInfExt = softwareSystem "Gateway API Inference Extension" "InferencePool CRD provider" "Internal llm-d"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "Manages disaggregated inference workload topology" "Internal llm-d"
        llmdBenchmark = softwareSystem "llm-d-benchmark" "External benchmark harness for evaluation" "Internal llm-d"
        prometheusOperator = softwareSystem "prometheus-operator" "ServiceMonitor CRD for metrics scraping" "External"
        inferenceServers = softwareSystem "vLLM / EPP Inference Servers" "LLM inference workloads being autoscaled" "Internal llm-d"

        sre -> llmdAutoscaling "Configures KEDA blueprints and runs benchmark evaluations"
        datascientist -> inferenceServers "Deploys inference models"

        kedaBlueprints -> keda "Defines ScaledObject triggers" "Kubernetes API"
        clusterOverlays -> kedaBlueprints "Layers backend-specific config"
        benchmarkTestBed -> llmdBenchmark "Drives evaluation scenarios" "Local process"
        benchmarkTestBed -> prometheus "Collects scaling metrics" "HTTPS/TLS 1.2+"
        benchmarkTestBed -> inferenceServers "Generates inference load" "HTTP/HTTPS"
        grafanaDashboard -> prometheus "Queries metrics" "HTTPS"

        keda -> prometheus "Reads Prometheus triggers from ScaledObject specs" "HTTPS/TLS 1.2+"
        keda -> k8sApi "Manages HPA via scale subresource" "HTTPS/6443"
        inferenceServers -> prometheus "Exposes inference metrics" "HTTP/HTTPS"
        k8sApi -> inferenceServers "Scales Deployment/LWS replicas"

        wvaController -> prometheus "Queries inference metrics (deprecated)" "HTTPS/TLS 1.2+"
        wvaController -> k8sApi "Watches InferencePool, HPA, ConfigMap; scales workloads (deprecated)" "HTTPS/6443"
        wvaController -> gatewayApiInfExt "Watches InferencePool CRDs (deprecated)" "Kubernetes API"
        wvaController -> leaderWorkerSet "Scales LWS resources (deprecated)" "Kubernetes API"
        prometheusOperator -> wvaController "Scrapes /metrics endpoint (deprecated)" "HTTPS/8443"
    }

    views {
        systemContext llmdAutoscaling "SystemContext" {
            include *
            autoLayout
        }

        container llmdAutoscaling "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #7ed321
                color #ffffff
            }
            element "Deprecated" {
                background #cccccc
                color #666666
                border dashed
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

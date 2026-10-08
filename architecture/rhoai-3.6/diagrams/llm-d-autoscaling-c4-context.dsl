workspace {
    model {
        sre = person "SRE / Platform Engineer" "Configures autoscaling blueprints and deploys KEDA ScaledObjects"
        mlEngineer = person "ML Engineer" "Deploys inference models and monitors autoscaling behavior"

        llmdAutoscaling = softwareSystem "llm-d-autoscaling" "KEDA autoscaling blueprints and evaluation test bed for llm-d inference deployments" {
            blueprints = container "KEDA Blueprint Scenarios" "Recommended ScaledObject configurations for prefill/decode disaggregation" "YAML"
            testBed = container "Evaluation Test Bed" "Autoscaling evaluation framework for evidence-based blueprint comparison" "Benchmark Harness"
            wvaController = container "WVA Controller (Legacy)" "Deprecated GPU-aware autoscaler with Kalman filter prediction" "Go Operator" "Deprecated"
        }

        keda = softwareSystem "KEDA" "Kubernetes Event-Driven Autoscaling — manages HPAs from external metrics" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and querying for inference workload metrics" "Internal Platform"
        k8sApi = softwareSystem "Kubernetes API" "Cluster control plane for resource management and scaling" "External"
        gatewayApiInfExt = softwareSystem "Gateway API Inference Extension" "InferencePool CRD for pool-based autoscaling configuration" "Internal Platform"
        llmdBenchmark = softwareSystem "llm-d-benchmark" "Load generation and metric capture for autoscaling evaluation" "Internal Platform"
        vllm = softwareSystem "vLLM Model Servers" "LLM inference servers exposing queue depth and KV-cache metrics" "Internal Platform"
        lws = softwareSystem "LeaderWorkerSet" "Multi-worker inference topology management" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "ServiceMonitor CRD management for metrics scraping" "Internal Platform"

        sre -> llmdAutoscaling "Selects and deploys KEDA blueprints"
        mlEngineer -> llmdAutoscaling "Evaluates autoscaling behavior via test bed"

        llmdAutoscaling -> keda "Provides ScaledObject configurations" "YAML manifests"
        llmdAutoscaling -> prometheus "Queries inference metrics" "HTTPS/9090, Bearer token / mTLS"
        llmdAutoscaling -> k8sApi "Watches resources, scales deployments" "HTTPS/6443, ServiceAccount"
        llmdAutoscaling -> llmdBenchmark "Uses for load generation in test bed" "CLI"

        keda -> prometheus "Queries metrics for scaling triggers" "HTTPS/9090, Bearer token"
        keda -> k8sApi "Creates/manages HPAs" "HTTPS/6443, ServiceAccount"

        vllm -> prometheus "Exports inference metrics" "HTTP/8200"

        wvaController -> gatewayApiInfExt "Watches InferencePool resources" "Kubernetes API"
        wvaController -> lws "Watches and scales LeaderWorkerSet" "Kubernetes API"
        wvaController -> prometheusOperator "Manages ServiceMonitors" "Kubernetes API"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Deprecated" {
                background #e74c3c
                color #ffffff
                opacity 50
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

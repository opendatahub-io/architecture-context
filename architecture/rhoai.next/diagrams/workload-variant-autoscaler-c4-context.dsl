workspace {
    model {
        admin = person "Platform Admin" "Configures autoscaling via annotated HPAs, ConfigMaps, and quotas"

        wva = softwareSystem "Workload Variant Autoscaler" "Intelligent autoscaler for LLM inference model servers based on saturation, queueing theory, and throughput analysis" {
            controllerManager = container "WVA Controller Manager" "Main process running reconcilers, engines, and coordinator" "Go (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Collects Prometheus metrics, routes to analyzers, applies optimizer pipeline" "Engine Loop"
            scaleFromZeroEngine = container "Scale-from-Zero Engine" "100ms polling loop detecting zero-replica variants with pending requests" "Engine Loop"
            coordinator = container "Coordinator" "Leader-elected 15s ticker for GPU rebalance across namespaces" "Engine Loop (experimental)"
            satV2Analyzer = container "Saturation V2 Analyzer" "Token-based capacity analysis with k1/k2 constraints" "Analyzer Plugin"
            qmAnalyzer = container "Queueing Model Analyzer" "SLO-driven capacity via Kalman filter parameter learning" "Analyzer Plugin"
            throughputAnalyzer = container "Throughput Analyzer" "ITL(k) model fitting via OLS regression" "Analyzer Plugin"
            costAwareOptimizer = container "CostAware Optimizer" "Scales cheapest capacity per dollar first" "Optimizer"
            greedyOptimizer = container "GreedyByScore Optimizer" "GPU-constrained fair-sharing via iterative mean allocation" "Optimizer"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Time-series monitoring for inference engine metrics" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        hpa = softwareSystem "HPA / KEDA" "Horizontal Pod Autoscaler or KEDA ScaledObjects" "External"
        vllm = softwareSystem "vLLM / SGLang" "LLM inference model servers exposing Prometheus metrics" "Internal"
        epp = softwareSystem "Gateway API EPP" "Endpoint Picker with flow-control queue metrics" "Internal"
        inferencePool = softwareSystem "Gateway API InferencePool" "Inference endpoint pool management CRD" "External"
        kserve = softwareSystem "KServe" "Manifest sync target for RHOAI deployment" "Internal"
        gpuOperator = softwareSystem "GPU Operator" "NVIDIA/AMD/Intel node GPU label provider" "External"
        promOperator = softwareSystem "Prometheus Operator" "ServiceMonitor CRD for metrics scrape config" "External"

        # Relationships
        admin -> wva "Creates annotated HPAs, ConfigMaps" "kubectl / HTTPS 443"
        wva -> prometheus "Queries inference metrics" "HTTPS/443 or HTTP/9090, Bearer Token"
        wva -> k8sAPI "Watches/patches HPAs, Deployments, Nodes, ConfigMaps" "HTTPS/443, SA Token"
        wva -> epp "Scrapes flow-control queue metrics" "HTTP/HTTPS, Bearer Token (optional)"
        hpa -> wva "Reads wva_desired_replicas" "HTTPS/8443, Bearer Token"
        hpa -> k8sAPI "Patches scale subresource" "HTTPS/443, SA Token"
        prometheus -> wva "Scrapes /metrics via ServiceMonitor" "HTTPS/8443, Bearer Token"
        vllm -> prometheus "Exposes KV cache, queue, latency metrics" "Prometheus scrape"
        wva -> inferencePool "Watches InferencePool CRs" "HTTPS/443, SA Token"
        gpuOperator -> k8sAPI "Applies GPU labels to nodes" "HTTPS/443"
        promOperator -> prometheus "Configures scrape targets" "ServiceMonitor CRD"
        wva -> kserve "Syncs kustomize manifests" "GitHub Actions CI"

        # Internal container relationships
        controllerManager -> saturationEngine "Starts"
        controllerManager -> scaleFromZeroEngine "Starts"
        controllerManager -> coordinator "Starts (if enabled)"
        saturationEngine -> satV2Analyzer "Routes metrics"
        saturationEngine -> qmAnalyzer "Routes metrics"
        saturationEngine -> throughputAnalyzer "Routes metrics"
        satV2Analyzer -> costAwareOptimizer "RC/SC output"
        qmAnalyzer -> costAwareOptimizer "RC/SC output"
        satV2Analyzer -> greedyOptimizer "RC/SC output"
    }

    views {
        systemContext wva "SystemContext" {
            include *
            autoLayout
        }

        container wva "Containers" {
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

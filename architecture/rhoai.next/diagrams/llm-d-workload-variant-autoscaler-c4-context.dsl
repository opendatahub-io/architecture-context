workspace {
    model {
        mlEngineer = person "ML Engineer / Platform Admin" "Configures variant autoscaling policies, deploys inference models, manages GPU quotas"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "GPU-aware global autoscaler for LLM inference model servers that optimizes replica counts across multiple hardware variants within a Kubernetes InferencePool" {
            controllerManager = container "WVA Controller Manager" "Discovers managed HPA/ScaledObject/InferencePool resources, synchronizes ConfigMap-driven configuration" "Go Operator (controller-runtime, kubebuilder v4)"
            saturationEngine = container "Saturation Engine" "Multi-path scaling engine (V1/V2/Queueing Model) that analyzes metrics and produces optimal replica count decisions" "Go"
            scaleFromZeroEngine = container "Scale-From-Zero Engine" "Fast-polling engine (100ms) detecting pending requests for zero-replica deployments" "Go"
            metricsCollector = container "Metrics Collector" "Collects per-replica metrics from Prometheus and direct pod scraping with engine-aware query routing" "Go"
            actuator = container "Metrics Actuator" "Emits wva_desired_replicas metric to Prometheus for consumption by HPA/KEDA" "Go"
            directActuator = container "Direct Actuator" "Patches Deployment/LWS replica counts via Kubernetes scale subresource" "Go"
            gpuDiscovery = container "GPU Discovery" "Discovers GPU/accelerator capacity from node labels (NVIDIA, AMD, Intel Gaudi/Xe)" "Go"
            pipelineOptimizer = container "Pipeline Optimizer" "Cost-aware (unlimited) and greedy-by-score (limited) optimizers for replica allocation" "Go"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics collection and query platform; on OpenShift uses Thanos Querier aggregation layer" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        hpaKeda = softwareSystem "HPA / KEDA" "External autoscalers that consume WVA metrics and drive the scale subresource" "External"
        vllm = softwareSystem "vLLM Inference Servers" "LLM inference engine exposing KV cache, queue, throughput metrics" "Internal Platform"
        sglang = softwareSystem "SGLang Inference Servers" "Alternative LLM inference engine with equivalent metrics (sglang: prefix)" "Internal Platform"
        epp = softwareSystem "EPP (Endpoint Picker)" "Gateway API inference scheduler providing dispatch rate and queue metrics" "Internal Platform"
        gpuOperator = softwareSystem "NVIDIA GPU Operator" "Provisions GPU device plugins and labels nodes with GPU product/count/memory" "External"
        inferencePool = softwareSystem "InferencePool CRD" "Maps models to pools for scale-from-zero queue metric routing" "Internal Platform"

        mlEngineer -> wva "Configures via ConfigMaps and HPA/ScaledObject annotations"
        wva -> prometheus "Queries inference metrics (PromQL)" "HTTPS/9090, Bearer Token"
        wva -> kubernetesAPI "Watches resources, patches scale subresource" "HTTPS/443, mTLS"
        prometheus -> wva "Scrapes /metrics endpoint" "HTTPS/8443, Bearer Token"
        hpaKeda -> prometheus "Queries wva_desired_replicas" "HTTPS/9090"
        hpaKeda -> kubernetesAPI "Patches scale subresource" "HTTPS/443"
        vllm -> prometheus "Exposes inference metrics (scraped)" "HTTP"
        sglang -> prometheus "Exposes inference metrics (scraped)" "HTTP"
        epp -> prometheus "Exposes scheduler/queue metrics (scraped)" "HTTP"
        wva -> gpuOperator "Reads GPU labels from nodes" "Kubernetes API"

        metricsCollector -> prometheus "PromQL queries for per-replica metrics" "HTTPS/9090"
        saturationEngine -> pipelineOptimizer "Raw decisions to optimizer pipeline"
        actuator -> prometheus "Exposes wva_desired_replicas" "HTTPS/8443"
        directActuator -> kubernetesAPI "PATCH scale subresource" "HTTPS/443"
        controllerManager -> kubernetesAPI "Watch HPA, ScaledObject, ConfigMap, InferencePool" "HTTPS/443"
        gpuDiscovery -> kubernetesAPI "Read node labels" "HTTPS/443"
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
            element "Internal Platform" {
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

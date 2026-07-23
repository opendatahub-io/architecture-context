workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys LLM inference models with variant configurations"
        platformadmin = person "Platform Admin" "Configures WVA scaling policies, GPU quotas, and monitoring"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "GPU-aware global autoscaler for LLM inference model servers that optimizes replica counts across multiple hardware variants" {
            controllerManager = container "WVA Controller Manager" "Discovers managed HPA/ScaledObject/InferencePool resources, synchronizes configuration, runs optimization engines" "Go Operator (controller-runtime, kubebuilder v4)"
            saturationEngine = container "Saturation Engine" "Multi-path scaling engine: V2 token/capacity analysis, queueing model M/M/1/K with Kalman filter tuning" "Go"
            scaleFromZeroEngine = container "Scale-From-Zero Engine" "Fast-polling (100ms) engine that detects pending requests for zero-replica deployments" "Go"
            metricsCollector = container "Metrics Collector" "Collects per-replica metrics from Prometheus and direct pod scraping with engine-aware query routing" "Go"
            actuator = container "Actuator" "Emits wva_desired_replicas metrics to Prometheus for HPA/KEDA consumption" "Go"
            directActuator = container "Direct Actuator" "Patches Deployment/LWS replica counts via Kubernetes scale subresource for scale-from-zero" "Go"
            gpuDiscovery = container "GPU Discovery" "Discovers GPU/accelerator capacity from node labels (NVIDIA, AMD, Intel Gaudi, Intel Xe)" "Go"
            pipelineOptimizers = container "Pipeline Optimizers" "Cost-aware (unlimited) and greedy-by-score (fair-share limited) optimizers for replica allocation" "Go"
            pipelineLimiters = container "Pipeline Limiters" "Inventory-based (physical GPU) and quota-based (operator-declared) GPU limiters with composite chaining" "Go"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics aggregation and query platform; source of inference engine telemetry" "External"
        k8sapi = softwareSystem "Kubernetes API Server" "Cluster control plane; manages HPA, ScaledObject, Deployment, ConfigMap, Node resources" "External"
        hpaKeda = softwareSystem "HPA / KEDA" "Kubernetes autoscalers that consume wva_desired_replicas and drive the scale subresource" "External"
        epp = softwareSystem "Gateway API Inference Extension (EPP)" "Endpoint Picker providing scheduler dispatch rate and flow control queue metrics" "Internal Platform"
        vllm = softwareSystem "vLLM / SGLang Inference Servers" "LLM model servers providing KV cache, queue, throughput, and latency metrics" "Internal Platform"
        gpuOperator = softwareSystem "NVIDIA GPU Operator" "Provides GPU product, count, and memory labels on Kubernetes nodes" "External"
        inferencePool = softwareSystem "InferencePool (Gateway API)" "Maps models to inference pools for routing and scale-from-zero queue metrics" "Internal Platform"

        # User interactions
        datascientist -> hpaKeda "Creates HPA/ScaledObject with llm-d.ai/managed annotation"
        platformadmin -> wva "Configures scaling via ConfigMaps (saturation-scaling, scale-to-zero, queueing-model)"
        platformadmin -> prometheus "Monitors WVA health via PrometheusRule alerts"

        # WVA internal flows
        controllerManager -> saturationEngine "Triggers optimization loop"
        controllerManager -> scaleFromZeroEngine "Triggers scale-from-zero polling"
        metricsCollector -> saturationEngine "Provides per-variant metrics"
        saturationEngine -> pipelineOptimizers "Produces scaling decisions"
        pipelineOptimizers -> pipelineLimiters "Checks GPU constraints"
        pipelineLimiters -> actuator "Approved scaling decisions"
        scaleFromZeroEngine -> directActuator "Scale-from-zero decisions"
        gpuDiscovery -> pipelineLimiters "GPU capacity data"

        # WVA external interactions
        wva -> prometheus "Queries inference metrics (KV cache, queue, throughput)" "HTTPS/9090, Bearer Token"
        wva -> k8sapi "Watches HPA, ScaledObject, ConfigMap, InferencePool, Node, Pod, Deployment, LWS" "HTTPS/443, mTLS"
        wva -> prometheus "Emits wva_desired_replicas via /metrics endpoint" "HTTPS/8443, Bearer Token"
        wva -> k8sapi "Patches Deployment/LWS scale subresource (scale-from-zero)" "HTTPS/443, mTLS"
        hpaKeda -> prometheus "Queries wva_desired_replicas" "HTTPS/9090"
        hpaKeda -> k8sapi "Patches scale subresource" "HTTPS/443"
        vllm -> prometheus "Exposes inference metrics" "HTTP (scraped)"
        epp -> prometheus "Exposes scheduler and queue metrics" "HTTP (scraped)"
        gpuOperator -> k8sapi "Labels nodes with GPU info"
        metricsCollector -> prometheus "Queries via Prometheus API" "HTTPS/9090"
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys LLM models and configures autoscaling via HPA annotations"
        platformAdmin = person "Platform Admin" "Manages WVA global configuration via ConfigMaps and monitors scaling decisions"

        wva = softwareSystem "Workload Variant Autoscaler" "Intelligent autoscaler for LLM inference model servers using saturation, queueing theory, and throughput analysis across heterogeneous GPU variants" {
            controllerManager = container "Controller Manager" "Reconciles HPAs, ScaledObjects, InferencePools, ConfigMaps; hosts optimization engines" "Go Operator (controller-runtime)"
            saturationEngine = container "Saturation V2 Engine" "Token-based capacity model computing optimal replicas from KV cache and queue saturation" "Go Module"
            queueingModelEngine = container "Queueing Model Engine" "SLO-driven scaling using M/M/1/K model with online Kalman filter parameter learning" "Go Module"
            throughputAnalyzer = container "Throughput Analyzer" "ITL model-based scaling using linear fit of inter-token latency vs KV utilization" "Go Module"
            scaleFromZeroEngine = container "Scale-from-Zero Engine" "Detects pending requests on idle models via EPP flow control queue metrics" "Go Module"
            coordinator = container "Coordinator" "Leader-elected periodic loop dispatching cluster-wide GPU rebalancing plugins" "Go Module (Experimental)"
            metricsCollector = container "Metrics Collector" "Queries Prometheus for vLLM and EPP metrics; supports direct pod scraping fallback" "Go Module"
            optimizationPipeline = container "Optimization Pipeline" "CostAware or GreedyByScore optimizer with scale-to-zero enforcer and GPU limiter" "Go Module"
            metricsEmitter = container "Metrics Emitter" "Publishes wva_desired_replicas as custom Prometheus metrics on 8443/TCP HTTPS" "Go Module"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics backend for vLLM performance data and WVA scaling metrics" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management, leader election, and scaling" "External"
        hpa = softwareSystem "HPA / KEDA" "Horizontal Pod Autoscaler reading WVA custom metrics to drive actual scaling" "External"
        vllm = softwareSystem "vLLM Inference Servers" "LLM inference engine providing KV cache, queue, and throughput metrics" "External"
        epp = softwareSystem "Gateway API Inference Extension (EPP)" "Scheduler dispatch rate and flow control queue metrics for demand estimation" "External"
        gpuOperator = softwareSystem "GPU Operator" "Discovers per-node GPU inventory via vendor-specific labels (NVIDIA/AMD/Intel)" "External"
        inferencePool = softwareSystem "InferencePool (Gateway API)" "Endpoint pool management CRD for pod-to-model mapping" "Internal Platform"
        lws = softwareSystem "LeaderWorkerSet" "Multi-GPU group-based scaling for distributed inference" "External Optional"

        # Relationships
        dataScientist -> hpa "Configures HPA with llm-d.ai/managed=true annotation"
        platformAdmin -> k8sApi "Updates ConfigMaps with scaling thresholds and policies"

        wva -> prometheus "Queries vLLM and EPP metrics via PromQL" "HTTPS/9091"
        wva -> k8sApi "Watches HPAs, ScaledObjects, InferencePools, ConfigMaps; leader election" "HTTPS/6443"
        wva -> vllm "Direct pod metrics scraping fallback" "HTTP/8200"

        prometheus -> wva "Scrapes /metrics endpoint" "HTTPS/8443"
        vllm -> prometheus "Exposes inference metrics" "HTTP/8200"
        epp -> prometheus "Exposes scheduler metrics" "HTTP"

        hpa -> prometheus "Reads wva_desired_replicas external metric" "HTTPS/9091"
        hpa -> k8sApi "Scales Deployments/LWS via scale subresource" "HTTPS/6443"

        gpuOperator -> k8sApi "Populates node GPU labels and allocatable resources"

        # Internal container relationships
        controllerManager -> metricsCollector "Triggers metric collection"
        metricsCollector -> saturationEngine "Feeds KV cache and queue metrics"
        metricsCollector -> queueingModelEngine "Feeds latency histogram metrics"
        metricsCollector -> throughputAnalyzer "Feeds ITL and KV utilization metrics"
        metricsCollector -> scaleFromZeroEngine "Feeds EPP queue metrics"
        saturationEngine -> optimizationPipeline "Produces AnalyzerResult"
        queueingModelEngine -> optimizationPipeline "Produces AnalyzerResult"
        throughputAnalyzer -> optimizationPipeline "Produces AnalyzerResult"
        optimizationPipeline -> metricsEmitter "Final replica decisions"
        scaleFromZeroEngine -> metricsEmitter "Scale-up signals"
        coordinator -> controllerManager "GPU rebalance plugin adjusts HPA targets"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

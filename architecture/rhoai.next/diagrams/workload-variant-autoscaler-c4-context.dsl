workspace {
    model {
        dataScientist = person "Data Scientist" "Creates VariantAutoscaling CRs to configure intelligent autoscaling for LLM model servers"
        platformAdmin = person "Platform Admin" "Configures WVA scaling parameters via ConfigMaps and manages GPU resources"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Kubernetes controller that performs intelligent autoscaling for LLM inference model servers based on saturation metrics and queueing theory" {
            controllerManager = container "WVA Controller Manager" "Reconciles VariantAutoscaling CRs, applies scaling decisions, patches status" "Go Operator (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Periodically collects vLLM metrics, runs V1/V2/queueing model analysis, computes optimal replica targets" "Go optimization loop (30s interval)"
            scaleFromZeroEngine = container "Scale-from-Zero Engine" "Monitors EPP flow control queue for pending requests on scaled-to-zero models, triggers direct scale-up" "Go optimization loop (100ms interval)"
            configMapReconciler = container "ConfigMap Reconciler" "Watches ConfigMaps for saturation, scale-to-zero, and queueing model configuration with namespace-local overrides" "Go controller"
            inferencePoolReconciler = container "InferencePool Reconciler" "Watches InferencePool resources and caches endpoint pool data" "Go controller"
            actuator = container "Actuator" "Emits Prometheus metrics (wva_desired_replicas, wva_desired_ratio) consumed by HPA/KEDA" "Go component"
            directActuator = container "DirectActuator" "Directly scales Deployment/LeaderWorkerSet via scale subresource for scale-from-zero" "Go component"
            metricsCollector = container "Metrics Collector" "Collects per-replica vLLM metrics from Prometheus with pluggable source infrastructure" "Go component"
            decisionCache = container "Decision Cache" "In-memory cache of scaling decisions shared between engines and reconciler" "Go in-memory store"
            gpuDiscovery = container "GPU Discovery" "Discovers cluster GPU inventory from node labels for capacity-aware scaling" "Go component"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Time-series metrics database collecting vLLM inference server metrics" "External"
        vllm = softwareSystem "vLLM Inference Servers" "LLM model servers emitting KV cache, queue depth, and performance metrics" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for managing resources, watching CRs, and scaling workloads" "External"
        epp = softwareSystem "Gateway API Inference Extension (EPP)" "Endpoint Picker providing flow control queue metrics for scale-from-zero" "External"
        hpaKeda = softwareSystem "HPA / KEDA" "Kubernetes horizontal pod autoscalers consuming WVA metrics for actual scaling" "External"
        gpuOperator = softwareSystem "GPU Operator" "NVIDIA/AMD/Intel GPU operator providing node labels for GPU discovery" "External"

        # Person relationships
        dataScientist -> wva "Creates VariantAutoscaling CRs via kubectl"
        platformAdmin -> wva "Configures scaling parameters via ConfigMaps"

        # System-level relationships
        vllm -> prometheus "Emits vLLM metrics (scraped)"
        wva -> prometheus "Queries vLLM metrics via PromQL" "HTTPS/9090"
        wva -> k8sAPI "Watches/updates CRs, Deployments, ConfigMaps, Nodes" "HTTPS/443"
        wva -> epp "Scrapes flow control queue metrics" "HTTPS"
        hpaKeda -> wva "Reads wva_desired_replicas metrics" "HTTPS/8443"
        hpaKeda -> k8sAPI "Scales Deployments/LeaderWorkerSets" "HTTPS/443"
        wva -> gpuOperator "Reads GPU inventory from node labels" "HTTPS/443"

        # Container-level relationships
        saturationEngine -> metricsCollector "Requests vLLM metrics"
        metricsCollector -> prometheus "PromQL queries" "HTTPS/9090 Bearer Token"
        saturationEngine -> decisionCache "Stores scaling decisions"
        scaleFromZeroEngine -> epp "Scrapes flow_control_queue_size" "HTTPS Bearer Token"
        scaleFromZeroEngine -> directActuator "Triggers direct scale-up"
        scaleFromZeroEngine -> decisionCache "Stores scaling decisions"
        directActuator -> k8sAPI "PATCH scale subresource" "HTTPS/443"
        decisionCache -> controllerManager "Channel trigger on new decisions"
        controllerManager -> k8sAPI "Patch VA status, watch resources" "HTTPS/443"
        controllerManager -> actuator "Updates Prometheus metric values"
        configMapReconciler -> k8sAPI "Watch ConfigMaps" "HTTPS/443"
        inferencePoolReconciler -> k8sAPI "Watch InferencePools" "HTTPS/443"
        gpuDiscovery -> k8sAPI "Read node labels" "HTTPS/443"
        gpuDiscovery -> saturationEngine "Provides GPU inventory"
        hpaKeda -> actuator "GET /metrics" "HTTPS/8443 Bearer Token"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

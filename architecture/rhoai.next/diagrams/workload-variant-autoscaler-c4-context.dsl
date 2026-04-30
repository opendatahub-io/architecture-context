workspace {
    model {
        platformEngineer = person "Platform Engineer" "Configures autoscaling policies and variant definitions"
        dataScientist = person "Data Scientist" "Deploys ML models with VariantAutoscaling CRs"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Intelligent autoscaler for LLM inference model servers based on saturation metrics and queueing theory" {
            controllerManager = container "WVA Controller Manager" "Reconciles VariantAutoscaling CRs, resolves scale targets, applies scaling decisions" "Go Operator (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Collects vLLM metrics, runs V1/V2/queueing model analysis, computes optimal replica targets" "Go optimization loop"
            scaleFromZeroEngine = container "Scale-from-Zero Engine" "Monitors EPP flow control queue, triggers direct scale-up for dormant models" "Go optimization loop (100ms polling)"
            actuator = container "Actuator" "Emits Prometheus metrics (wva_desired_replicas, wva_desired_ratio) for HPA/KEDA consumption" "Go component"
            directActuator = container "DirectActuator" "Directly scales Deployment/LeaderWorkerSet via scale subresource for scale-from-zero" "Go component"
            decisionCache = container "Decision Cache" "In-memory cache bridging engine decisions to reconciler" "Go in-memory store"
            configMapReconciler = container "ConfigMap Reconciler" "Watches ConfigMaps for scaling configuration with namespace-local overrides" "Go controller"
            metricsCollector = container "Metrics Collector" "Collects per-replica vLLM metrics from Prometheus with pluggable source infrastructure" "Go component"
            gpuDiscovery = container "GPU Discovery" "Discovers cluster GPU inventory from node labels for capacity-aware scaling" "Go component"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics collection and querying platform" "External"
        vllm = softwareSystem "vLLM Inference Servers" "LLM inference servers emitting saturation metrics" "External"
        hpaKeda = softwareSystem "HPA / KEDA" "Kubernetes autoscalers that perform actual pod scaling" "External"
        istioGateway = softwareSystem "Gateway API Inference Extension" "EPP for flow control and request routing" "Internal Platform"
        k8sApi = softwareSystem "Kubernetes API" "Cluster control plane for resource management" "External"
        gpuOperator = softwareSystem "GPU Operator (NVIDIA/AMD/Intel)" "GPU resource management and node labeling" "External"
        lws = softwareSystem "LeaderWorkerSet" "Multi-pod model serving for tensor parallelism" "External"

        dataScientist -> wva "Creates VariantAutoscaling CR via kubectl"
        platformEngineer -> wva "Configures scaling parameters via ConfigMaps"

        wva -> prometheus "Queries vLLM metrics via PromQL" "HTTPS/9090"
        wva -> k8sApi "Watches/updates CRs, Deployments, Nodes" "HTTPS/443"
        wva -> istioGateway "Scrapes EPP flow control queue metrics" "HTTPS"
        wva -> gpuOperator "Reads GPU inventory from node labels"
        wva -> lws "Optional: scales LeaderWorkerSet for tensor parallelism" "HTTPS/443"

        prometheus -> vllm "Scrapes vLLM metrics"
        hpaKeda -> wva "Scrapes wva_desired_replicas metrics" "HTTPS/8443"
        hpaKeda -> k8sApi "Scales Deployments" "HTTPS/443"

        # Internal container relationships
        metricsCollector -> prometheus "PromQL queries" "HTTPS/9090 Bearer Token"
        metricsCollector -> saturationEngine "Feeds per-replica metrics"
        saturationEngine -> decisionCache "Stores scaling decisions"
        scaleFromZeroEngine -> decisionCache "Stores scale-from-zero decisions"
        scaleFromZeroEngine -> istioGateway "Scrapes flow_control_queue_size" "HTTPS Bearer Token"
        scaleFromZeroEngine -> directActuator "Triggers direct scale-up"
        decisionCache -> controllerManager "Channel trigger for requeue"
        controllerManager -> k8sApi "Patches VA status" "HTTPS/443 ServiceAccount"
        saturationEngine -> actuator "Updates Prometheus gauges"
        directActuator -> k8sApi "PATCH scale subresource" "HTTPS/443 ServiceAccount"
        configMapReconciler -> saturationEngine "Provides scaling parameters"
        gpuDiscovery -> saturationEngine "Provides GPU inventory"
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

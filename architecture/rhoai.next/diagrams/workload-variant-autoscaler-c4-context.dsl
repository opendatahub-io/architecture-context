workspace {
    model {
        user = person "Data Scientist / MLOps" "Creates VariantAutoscaling CRs to define autoscaling for LLM inference model servers"

        wva = softwareSystem "Workload Variant Autoscaler" "Global autoscaler for LLM inference model servers using saturation metrics, cost optimization, and queueing theory" {
            controller = container "WVA Controller Manager" "Reconciles VariantAutoscaling CRs, applies cached scaling decisions to status, emits Prometheus metrics" "Go Operator (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Runs saturation analysis (V1/V2/M/M/1) on vLLM metrics at 30s intervals, produces scaling decisions" "Go Polling Loop"
            scalefromzeroEngine = container "Scale-From-Zero Engine" "Monitors EPP flow control queues at 100ms intervals, directly scales idle variants 0→1" "Go Polling Loop"
            decisionCache = container "Decision Cache" "In-memory cache of scaling decisions shared between engines and reconciler" "Go In-Memory Store"
            actuator = container "Actuator" "Emits wva_desired_replicas, wva_current_replicas, wva_desired_ratio Prometheus metrics" "Go Component"
            collector = container "Collector" "Collects vLLM server metrics from Prometheus via PromQL" "Go Component"
            configmapReconciler = container "ConfigMap Reconciler" "Watches ConfigMaps for dynamic configuration with namespace-scoped overrides" "Go Controller"
            datastore = container "Datastore" "In-memory cache of InferencePool data and EPP metrics sources" "Go In-Memory Store"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Time-series database and query engine for vLLM and cluster metrics" "External"
        vllm = softwareSystem "vLLM Inference Servers" "LLM model serving infrastructure exposing KV cache, queue, and latency metrics" "External"
        hpaKeda = softwareSystem "HPA / KEDA" "Kubernetes autoscaler consuming WVA metrics to perform actual pod scaling" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for CR management, workload scaling, and leader election" "Infrastructure"
        gatewayApiExt = softwareSystem "Gateway API Inference Extension" "Provides InferencePool CRDs and EPP (Endpoint Picker) pods" "External"
        eppPods = softwareSystem "EPP Pods (Endpoint Picker)" "Endpoint picker pods exposing flow control queue metrics" "External"
        lws = softwareSystem "LeaderWorkerSet" "Optional CRD for multi-worker GPU serving topologies" "External"
        promOperator = softwareSystem "Prometheus Operator" "ServiceMonitor CRD for metrics scraping configuration" "External"

        # External relationships
        user -> wva "Creates VariantAutoscaling CRs via kubectl" "HTTPS/443"
        wva -> prometheus "Queries vLLM metrics via PromQL" "HTTPS/9091"
        wva -> eppPods "Scrapes flow control queue metrics" "HTTPS/configurable"
        wva -> k8sApi "CRUD on CRs, scale workloads, leader election" "HTTPS/443"
        prometheus -> wva "Scrapes /metrics endpoint" "HTTPS/8443"
        hpaKeda -> prometheus "Reads wva_desired_ratio metrics" "HTTPS/9091"
        hpaKeda -> k8sApi "Scales Deployment/LWS replicas" "HTTPS/443"
        vllm -> prometheus "Exposes vLLM metrics (scraped)" "HTTPS"
        gatewayApiExt -> k8sApi "Provides InferencePool CRDs" "HTTPS/443"

        # Internal container relationships
        collector -> prometheus "PromQL queries for vLLM metrics" "HTTPS/9091 Bearer Token"
        collector -> saturationEngine "Provides collected metrics"
        saturationEngine -> decisionCache "Stores VariantDecision structs"
        scalefromzeroEngine -> eppPods "Scrapes queue size metrics" "HTTPS Bearer Token"
        scalefromzeroEngine -> decisionCache "Stores scale-from-zero decisions"
        scalefromzeroEngine -> k8sApi "Direct scale 0→1 via /scale subresource" "HTTPS/443"
        decisionCache -> controller "GenericEvent trigger channel"
        controller -> k8sApi "Patch VA status" "HTTPS/443"
        controller -> actuator "Emit scaling decisions"
        actuator -> prometheus "Expose wva_* metrics at /metrics" "HTTPS/8443"
        configmapReconciler -> saturationEngine "Apply config updates"
        datastore -> scalefromzeroEngine "Provide EPP endpoints"
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
                shape person
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
            element "Infrastructure" {
                background #666666
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

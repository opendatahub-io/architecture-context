workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys ML models and configures autoscaling via VariantAutoscaling CRs"
        platformAdmin = person "Platform Admin" "Configures WVA global settings, saturation thresholds, and GPU inventory"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Intelligent autoscaler for LLM inference model servers based on saturation metrics, cost optimization, and queueing theory" {
            controllerManager = container "WVA Controller Manager" "Reconciles VariantAutoscaling CRs, processes optimization engine decisions" "Go Operator (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Runs saturation analysis (V1/V2/queueing model) on vLLM metrics from Prometheus at 30s intervals" "Go Polling Loop"
            scaleFromZeroEngine = container "Scale-From-Zero Engine" "Monitors EPP queue metrics at 100ms intervals for idle variant detection" "Go Polling Loop"
            actuator = container "Actuator" "Emits Prometheus metrics: wva_desired_replicas, wva_desired_ratio, wva_current_replicas" "Go Component"
            collector = container "Collector" "Collects vLLM server metrics (KV cache, queue, tokens, TTFT, ITL) from Prometheus" "Go Component"
            decisionCache = container "Decision Cache" "In-memory cache of optimization decisions shared between engines and reconciler" "Go In-Memory Store"
            datastore = container "Datastore" "In-memory cache of InferencePool data, EPP sources, namespace tracking" "Go In-Memory Store"
            configMapReconciler = container "ConfigMap Reconciler" "Watches ConfigMaps for dynamic configuration with namespace-scoped overrides" "Go Controller"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Cluster monitoring stack providing PromQL API for vLLM and scheduler metrics" "External"
        vllm = softwareSystem "vLLM Inference Servers" "LLM serving runtime exposing KV cache, queue, token, and latency metrics" "External"
        hpaKeda = softwareSystem "HPA / KEDA" "Kubernetes autoscalers consuming WVA metrics to perform actual pod scaling" "External"
        gatewayAPIExt = softwareSystem "Gateway API Inference Extension" "InferencePool CRD and EPP (Endpoint Picker) pods for request routing" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Control plane API for managing workloads, CRDs, RBAC, and leader election" "External"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate provisioning for metrics endpoint" "External"
        lws = softwareSystem "LeaderWorkerSet" "Optional CRD for multi-worker GPU serving topologies" "External"
        promOperator = softwareSystem "Prometheus Operator" "ServiceMonitor CRD for automated metrics scraping configuration" "External"

        # User interactions
        dataScientist -> wva "Creates VariantAutoscaling CRs" "kubectl / YAML"
        platformAdmin -> wva "Configures saturation thresholds, GPU costs, scale-to-zero" "ConfigMaps"

        # WVA external interactions
        wva -> prometheus "Queries vLLM metrics via PromQL" "HTTPS/9091, Bearer Token"
        wva -> gatewayAPIExt "Watches InferencePool CRs; scrapes EPP pod queue metrics" "HTTPS, Bearer Token"
        wva -> k8sAPI "CRUD on VA status, reads Deployments/LWS/ConfigMaps/Nodes, leader election, scale subresource" "HTTPS/443, SA token"
        wva -> hpaKeda "Emits wva_desired_replicas/ratio metrics (indirect via Prometheus)" "Prometheus metrics"

        vllm -> prometheus "Exports vLLM serving metrics" "Prometheus scraping"
        hpaKeda -> prometheus "Reads WVA scaling metrics" "HTTPS/9091"
        hpaKeda -> k8sAPI "Scales Deployment/LWS replicas" "HTTPS/443"
        prometheus -> wva "Scrapes /metrics endpoint" "HTTPS/8443, Bearer Token"

        # Internal container interactions
        saturationEngine -> collector "Requests vLLM metrics collection" ""
        collector -> prometheus "Queries PromQL" "HTTPS/9091"
        saturationEngine -> decisionCache "Writes VariantDecision" "Go channel"
        scaleFromZeroEngine -> datastore "Reads EPP endpoint sources" ""
        scaleFromZeroEngine -> decisionCache "Writes scale-from-zero decisions" "Go channel"
        decisionCache -> controllerManager "Triggers reconciliation" "GenericEvent channel"
        controllerManager -> actuator "Emits scaling metrics" ""
        configMapReconciler -> saturationEngine "Updates thresholds/config" ""
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

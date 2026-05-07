workspace {
    model {
        user = person "Data Scientist" "Creates VariantAutoscaling CRs to define autoscaling for LLM inference model variants"

        platformAdmin = person "Platform Admin" "Configures WVA controller, saturation thresholds, and GPU inventory"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Global autoscaler for LLM inference model servers using saturation metrics, cost optimization, and queueing theory" {
            controllerManager = container "WVA Controller Manager" "Reconciles VariantAutoscaling CRs, orchestrates optimization engines, emits scaling metrics" "Go Operator (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Polls Prometheus for vLLM metrics (KV cache, queue depth), runs V1/V2/Queueing analyzers at 30s intervals" "Go Engine"
            scaleFromZeroEngine = container "Scale-From-Zero Engine" "Scrapes EPP pods at 100ms intervals to detect pending requests for idle variants, directly scales 0→1" "Go Engine"
            queuingModelEngine = container "Queueing Model Engine" "M/M/1 queueing theory analyzer for latency/throughput prediction" "Go Analyzer"
            actuator = container "Actuator" "Emits wva_desired_replicas, wva_desired_ratio, wva_current_replicas Prometheus metrics" "Go Component"
            collector = container "Collector" "Collects vLLM metrics from Prometheus and EPP pod scraping" "Go Component"
            datastore = container "Datastore" "In-memory cache of InferencePool data, EPP metrics sources, namespace tracking" "Go Component"
            decisionCache = container "Decision Cache" "Stores optimization engine scaling decisions for reconciler consumption" "In-Memory Cache"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics aggregation and PromQL query API" "External"
        vllm = softwareSystem "vLLM Inference Servers" "LLM model serving with KV cache, queue, and token metrics" "External"
        hpaKeda = softwareSystem "HPA / KEDA" "Kubernetes autoscalers consuming WVA metrics" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster control plane for CRD management and workload scaling" "External"
        gatewayApi = softwareSystem "Gateway API Inference Extension" "InferencePool CRD and EPP pods for traffic management" "External"
        lws = softwareSystem "LeaderWorkerSet" "Optional multi-worker GPU serving topology" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        promOperator = softwareSystem "Prometheus Operator" "ServiceMonitor CRD for metrics scraping" "External"

        # System-level relationships
        user -> wva "Creates VariantAutoscaling CRs via kubectl"
        platformAdmin -> wva "Configures via ConfigMaps"
        wva -> prometheus "Queries vLLM metrics via PromQL" "HTTPS/9091"
        prometheus -> vllm "Scrapes inference metrics"
        wva -> k8sApi "CRUD on VariantAutoscaling, read workloads, leader election" "HTTPS/443"
        wva -> gatewayApi "Scrapes EPP pods for scale-from-zero" "HTTPS"
        hpaKeda -> prometheus "Reads wva_desired_ratio metric" "HTTPS/9091"
        hpaKeda -> k8sApi "Scales Deployments/LWS" "HTTPS/443"
        prometheus -> wva "Scrapes /metrics endpoint" "HTTPS/8443"
        wva -> lws "Optional: watches and scales LeaderWorkerSets" "HTTPS/443"

        # Container-level relationships
        saturationEngine -> collector "Reads vLLM metrics"
        collector -> prometheus "PromQL queries" "HTTPS/9091"
        scaleFromZeroEngine -> datastore "Reads EPP sources"
        scaleFromZeroEngine -> gatewayApi "Scrapes EPP pod metrics" "HTTPS"
        saturationEngine -> decisionCache "Writes scaling decisions"
        scaleFromZeroEngine -> decisionCache "Writes scaling decisions"
        queuingModelEngine -> decisionCache "Writes scaling decisions"
        decisionCache -> controllerManager "Triggers reconciliation via Go channel"
        controllerManager -> actuator "Updates scaling metrics"
        controllerManager -> k8sApi "Patches VA status, scale subresource" "HTTPS/443"
        scaleFromZeroEngine -> k8sApi "Direct scale 0→1" "HTTPS/443"
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
                shape Person
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

workspace {
    model {
        sre = person "Platform Admin / SRE" "Configures autoscaling for LLM inference model variants"
        datascientist = person "Data Scientist" "Deploys ML models and creates VariantAutoscaling resources"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Intelligent autoscaler for LLM inference model servers based on saturation metrics, cost optimization, and queueing theory" {
            controllerManager = container "Controller Manager" "Reconciles VariantAutoscaling CRs, coordinates scaling decisions" "Go Operator (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Runs optimization loop every 30s, collects Prometheus metrics, produces scaling decisions via V1/V2/queueing-model analyzers" "Go Engine Loop"
            scaleFromZeroEngine = container "Scale-from-Zero Engine" "Polls EPP flow control queue metrics every 100ms, detects pending requests for idle variants" "Go Engine Loop"
            configmapReconciler = container "ConfigMap Reconciler" "Watches ConfigMaps for saturation scaling, scale-to-zero, and queueing model configuration" "Go Controller"
            inferencepoolReconciler = container "InferencePool Reconciler" "Watches Gateway API InferencePool resources and maintains EPP endpoint datastore" "Go Controller"
            actuator = container "Actuator" "Emits Prometheus metrics (wva_desired_replicas, wva_desired_ratio) for HPA/KEDA consumption" "Go Module"
            directActuator = container "Direct Actuator" "Patches scale subresource directly for scale-from-zero operations" "Go Module"
            collector = container "Collector" "Collects replica-level saturation metrics from Prometheus and EPP pod scraping" "Go Module"
            decisionCache = container "Decision Cache" "In-memory cache of scaling decisions shared between engine and controller" "Go in-memory"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics platform providing vLLM saturation metrics via PromQL" "External"
        vllm = softwareSystem "vLLM Inference Servers" "LLM inference servers exposing KV cache utilization, queue depth, request count metrics" "External"
        epp = softwareSystem "Gateway API Inference Extension (EPP)" "Endpoint Picker providing flow control queue metrics for scale-from-zero" "External"
        hpaKeda = softwareSystem "HPA / KEDA" "External autoscaler consuming WVA Prometheus metrics to perform actual replica scaling" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for CRUD on resources, scale subresource operations" "External"
        lws = softwareSystem "LeaderWorkerSet (LWS)" "Optional CRD for scaling LeaderWorkerSet workloads" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for metrics endpoint" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "ServiceMonitor CRD for metrics scraping configuration" "External"

        # Person relationships
        sre -> wva "Configures VariantAutoscaling CRs and scaling parameters"
        datascientist -> wva "Creates VariantAutoscaling resources for model variants"

        # WVA internal relationships
        saturationEngine -> collector "Triggers metric collection"
        collector -> prometheus "PromQL queries for vLLM metrics" "HTTPS/9091, Bearer Token"
        saturationEngine -> decisionCache "Writes scaling decisions"
        saturationEngine -> actuator "Emits scaling metrics"
        controllerManager -> decisionCache "Reads scaling decisions"
        controllerManager -> k8sApi "Updates VariantAutoscaling status" "HTTPS/443"
        scaleFromZeroEngine -> epp "Scrapes flow control queue metrics" "HTTPS, Bearer Token"
        scaleFromZeroEngine -> directActuator "Triggers direct scale operations"
        directActuator -> k8sApi "Patches scale subresource" "HTTPS/443"
        configmapReconciler -> k8sApi "Watches ConfigMaps" "HTTPS/443"
        inferencepoolReconciler -> k8sApi "Watches InferencePool CRs" "HTTPS/443"

        # External relationships
        vllm -> prometheus "Exposes saturation metrics (scraped)"
        prometheus -> actuator "Scrapes WVA /metrics endpoint" "HTTPS/8443, Bearer Token"
        hpaKeda -> prometheus "Queries WVA scaling metrics" "HTTPS/9091"
        hpaKeda -> k8sApi "Scales Deployments/LWS via scale subresource" "HTTPS/443"
        prometheusOperator -> wva "ServiceMonitor for metrics scraping config"
        certManager -> wva "Provisions TLS certificates for metrics endpoint"
    }

    views {
        systemContext wva "SystemContext" {
            include *
            autoLayout
            description "System context showing WVA in the LLM inference serving ecosystem"
        }

        container wva "Containers" {
            include *
            autoLayout
            description "Internal components of the Workload Variant Autoscaler"
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

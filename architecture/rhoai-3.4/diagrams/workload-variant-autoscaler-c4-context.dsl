workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and manages LLM inference model servers on Kubernetes"
        platformengineer = person "Platform Engineer" "Configures autoscaling policies and manages cluster resources"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Intelligent autoscaling for LLM inference model servers based on saturation metrics (KV cache, queue depth, token demand)" {
            controllerManager = container "WVA Controller Manager" "Reconciles VariantAutoscaling CRs, resolves scale targets, applies engine decisions" "Go Operator (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Periodically queries Prometheus, runs saturation analysis, publishes scaling decisions" "Go Engine Loop (60s interval)"
            scaleFromZeroEngine = container "Scale-from-Zero Engine" "Monitors idle models, triggers scale-up on incoming requests" "Go Engine Loop"
            configmapReconciler = container "ConfigMap Reconciler" "Watches and synchronizes ConfigMap-backed configuration" "Go Controller"
            inferencePoolReconciler = container "InferencePool Reconciler" "Watches InferencePool CRs, populates endpoint pool data" "Go Controller"
            actuator = container "Actuator" "Emits custom Prometheus metrics (wva_desired_replicas, wva_desired_ratio)" "Go Library"
            metricsCollector = container "Metrics Collector" "Collects metrics from Prometheus and EPP pods via pluggable source registry" "Go Library"
            datastore = container "Datastore" "Caches InferencePool data, tracks namespace-to-resource mappings" "Go In-Memory Store"
            decisionCache = container "Decision Cache" "Stores scaling decisions, triggers reconciliation via Channel" "Go In-Memory Cache"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Cluster monitoring, stores vLLM inference metrics, serves PromQL queries" "External"
        vllm = softwareSystem "vLLM Inference Servers" "LLM model serving runtime producing inference metrics" "External"
        hpaKeda = softwareSystem "HPA / KEDA" "Kubernetes autoscalers that execute scaling decisions based on WVA metrics" "External"
        prometheusAdapter = softwareSystem "Prometheus Adapter" "Bridges Prometheus metrics to Kubernetes custom metrics API for HPA" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for watching/updating resources" "External"
        inferencePool = softwareSystem "InferencePool (Gateway API Inference Extension)" "Discovers inference serving endpoint pools and EPP metadata" "Internal Platform"
        lws = softwareSystem "LeaderWorkerSet" "Optional multi-worker inference topology scale target" "Internal Platform"
        epp = softwareSystem "EPP (Endpoint Picker) Pods" "Inference scheduler pods exposing flow control metrics" "Internal Platform"

        # User interactions
        datascientist -> wva "Creates VariantAutoscaling CR via kubectl"
        platformengineer -> wva "Configures scaling policies via ConfigMaps"

        # WVA to external systems
        wva -> prometheus "Queries vLLM metrics via PromQL" "HTTPS/9091, Bearer Token + optional mTLS"
        wva -> k8sAPI "Watches/updates VAs, Deployments, ConfigMaps, InferencePools, Nodes" "HTTPS/443, Bearer Token"
        wva -> epp "Scrapes flow control metrics from EPP pods" "HTTPS, Bearer Token (epp-metrics-token)"

        # External systems to WVA
        prometheus -> wva "Scrapes /metrics endpoint" "HTTPS/8443, Bearer Token"

        # Downstream scaling chain
        prometheus -> vllm "Scrapes vLLM inference metrics"
        hpaKeda -> prometheus "Reads wva_desired_replicas metric" "HTTPS/9091"
        prometheusAdapter -> prometheus "Bridges WVA metrics to custom metrics API"
        hpaKeda -> k8sAPI "Scales Deployments/StatefulSets/LWS" "HTTPS/443"

        # Internal container relationships
        saturationEngine -> metricsCollector "Requests metrics"
        metricsCollector -> datastore "Reads endpoint pool data"
        saturationEngine -> decisionCache "Publishes scaling decisions"
        decisionCache -> controllerManager "Triggers reconcile via Channel"
        controllerManager -> actuator "Emits scaling metrics"
        configmapReconciler -> saturationEngine "Provides configuration updates"
        inferencePoolReconciler -> datastore "Populates pool data"
        scaleFromZeroEngine -> decisionCache "Publishes scale-from-zero decisions"
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
                background #4a90e2
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

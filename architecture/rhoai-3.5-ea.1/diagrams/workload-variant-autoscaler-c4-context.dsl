workspace {
    model {
        admin = person "Platform Admin / SRE" "Configures autoscaling policies via VariantAutoscaling CRs and ConfigMaps"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Intelligent autoscaler for LLM inference model servers using saturation metrics, KV cache utilization, and queueing theory" {
            controllerManager = container "WVA Controller Manager" "Manages VariantAutoscaling CRs, orchestrates optimization engines" "Go Operator (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Collects Prometheus metrics, computes optimal replicas using SaturationV2Analyzer" "Go optimization loop (60s interval)"
            scaleFromZeroEngine = container "Scale-from-Zero Engine" "Monitors InferencePool pending requests, scales deployments from 0" "Go optimization loop"
            prometheusCollector = container "Prometheus Collector" "Queries Prometheus for vLLM metrics with multi-tier caching (TTL, freshness, staleness)" "Go metrics collector"
            directActuator = container "Direct Actuator" "Patches replica counts, emits optimization metrics to Prometheus" "Go actuator"
            gpuDiscovery = container "GPU Capacity Discovery" "Discovers GPU capacity via GFD labels (NVIDIA, AMD, Intel)" "Go discovery module"
            configMapReconciler = container "ConfigMap Reconciler" "Watches labeled ConfigMaps for dynamic threshold updates" "Go controller"
            inferencePoolReconciler = container "InferencePool Reconciler" "Watches InferencePool CRs for pool endpoint tracking" "Go controller"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics source for vLLM server metrics; target for WVA optimization metrics" "External"
        hpa = softwareSystem "HPA (Kubernetes)" "Standard Kubernetes autoscaler reading WVA custom metrics" "External"
        keda = softwareSystem "KEDA" "External autoscaler reading WVA Prometheus metrics via ScaledObject" "External"
        prometheusAdapter = softwareSystem "Prometheus Adapter" "Bridges WVA Prometheus metrics to Kubernetes custom metrics API" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        gfd = softwareSystem "GPU Feature Discovery (GFD)" "Provides GPU product/memory labels on cluster nodes" "External"
        lws = softwareSystem "LeaderWorkerSet (LWS)" "Optional scale target for multi-worker inference setups" "External"
        inferencePool = softwareSystem "Gateway API Inference Extension" "InferencePool CRs for model serving pool tracking" "Internal Platform"
        modelServers = softwareSystem "vLLM / Inference Model Servers" "LLM model servers emitting KV cache, queue depth, throughput metrics" "Internal Platform"

        # Relationships - External
        admin -> wva "Creates VariantAutoscaling CRs and ConfigMaps via kubectl"
        wva -> prometheus "Queries vLLM metrics (PromQL over HTTPS)" "HTTPS/9090-9091"
        prometheus -> wva "Scrapes /metrics endpoint via ServiceMonitor" "HTTPS/8443"
        wva -> k8sAPI "Watches/patches CRs, Deployments, LWS, Nodes, ConfigMaps" "HTTPS/443"
        prometheus -> prometheusAdapter "Provides WVA metrics"
        prometheusAdapter -> hpa "Exposes custom metrics API"
        prometheus -> keda "Provides metrics via ScaledObject query"
        hpa -> k8sAPI "Scales deployments via scale subresource" "HTTPS/443"
        keda -> k8sAPI "Scales deployments via scale subresource" "HTTPS/443"
        modelServers -> prometheus "Emits vLLM metrics (KV cache, queue depth)"

        # Relationships - Internal
        controllerManager -> saturationEngine "Starts optimization loop"
        controllerManager -> scaleFromZeroEngine "Starts scale-from-zero loop"
        controllerManager -> configMapReconciler "Registers ConfigMap watcher"
        controllerManager -> inferencePoolReconciler "Registers InferencePool watcher"
        saturationEngine -> prometheusCollector "Queries cached metrics"
        saturationEngine -> gpuDiscovery "Gets GPU capacity"
        saturationEngine -> directActuator "Stores decisions, emits metrics"
        scaleFromZeroEngine -> directActuator "Triggers direct scale"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

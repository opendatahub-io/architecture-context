workspace {
    model {
        admin = person "Platform Admin" "Configures autoscaling policies and GPU quotas for LLM inference workloads"

        wva = softwareSystem "Workload Variant Autoscaler" "GPU-aware autoscaler controller that optimizes replica counts across hardware variants using saturation analysis, queueing models, and cost-based scaling decisions" {
            controllerManager = container "Controller Manager" "Main controller binary hosting all reconcilers and optimization engines" "Go (controller-runtime)" {
                configmapCtrl = component "ConfigMap Controller" "Reconciles saturation-scaling, scale-to-zero, and queueing-model ConfigMaps" "Reconciler"
                hpaCtrl = component "HPA Controller" "Watches HPAs with llm-d.ai/managed annotation for namespace discovery" "Reconciler"
                inferencePoolCtrl = component "InferencePool Controller" "Watches InferencePool resources (v1 and v1alpha2)" "Reconciler"
                scaledObjectCtrl = component "ScaledObject Controller" "Watches KEDA ScaledObjects (conditional on CRD)" "Reconciler"
                saturationEngine = component "Saturation Engine" "Collects metrics, runs pluggable analyzers, emits scaling decisions" "Engine"
                scaleFromZero = component "Scale-from-Zero Engine" "Handles scale-to-zero lifecycle with retention periods" "Engine"
                coordinator = component "Coordinator" "Leader-elected GPU quota rebalancing loop (experimental)" "Engine"
                gpuRebalance = component "GPU Rebalance Plugin" "Proportionally allocates GPU quota via queue depth metrics" "Plugin"
                podScraper = component "Pod Scraping Source" "HTTP scraper for /metrics on inference pods" "Collector"
                gpuDiscovery = component "GPU Discovery" "Discovers NVIDIA, AMD, Intel GPU capacity across nodes" "Discovery"
            }
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring system for per-replica inference metrics" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages ServiceMonitor and PrometheusRule CRDs" "External"
        gatewayApiExt = softwareSystem "Gateway API Inference Extension" "Provides InferencePool CRD types for pool-based autoscaling" "Internal Platform"
        keda = softwareSystem "KEDA" "Event-driven autoscaler providing ScaledObject CRDs" "External"
        lws = softwareSystem "LeaderWorkerSet" "Manages disaggregated inference topologies" "External"
        hpaAdapter = softwareSystem "HPA / Prometheus Adapter" "Reads external metrics for Kubernetes HPA scaling" "External"
        eppPods = softwareSystem "EPP / Inference Pods" "Endpoint Picker and inference engine pods serving LLM requests" "Internal Platform"

        # Relationships
        admin -> wva "Configures autoscaling via ConfigMaps and HPA annotations"
        wva -> k8sApi "Watches/patches HPAs, ScaledObjects, Deployments, LWS, ConfigMaps, Nodes" "HTTPS/6443, TLS 1.2+, SA token"
        wva -> prometheus "Queries per-replica metrics (KV cache, queue, throughput)" "HTTPS/9090, Bearer token"
        wva -> eppPods "Scrapes pod /metrics endpoints" "HTTP(S), Optional Bearer"
        prometheus -> wva "Scrapes wva_desired_replicas metric via ServiceMonitor" "HTTPS/8443, TLS"
        prometheusOperator -> wva "Manages ServiceMonitor and PrometheusRule" "Kubernetes API"
        wva -> gatewayApiExt "Watches InferencePool resources (v1, v1alpha2)" "Kubernetes API"
        wva -> keda "Watches ScaledObjects (conditional on CRD presence)" "Kubernetes API"
        wva -> lws "Watches LeaderWorkerSets for disaggregated inference" "Kubernetes API"
        hpaAdapter -> prometheus "Reads wva_desired_replicas metric"
        hpaAdapter -> k8sApi "Scales target Deployments/LWS via scale subresource" "HTTPS/6443"
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

        component controllerManager "Components" {
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

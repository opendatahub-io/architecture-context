workspace {
    model {
        sre = person "SRE / Platform Admin" "Configures autoscaling thresholds and deploys WVA"
        datascientist = person "Data Scientist" "Deploys ML models that WVA autoscales"

        wva = softwareSystem "Workload-Variant-Autoscaler" "Kubernetes controller that autoscales LLM inference model servers based on saturation metrics (KV cache utilization, queue depth)" {
            saturationEngine = container "Saturation Engine" "Runs optimization loop: queries Prometheus metrics, analyzes saturation per model variant, actuates replica scale changes" "Go (leader-elected runnable)"
            scaleFromZeroEngine = container "Scale-from-Zero Engine" "Handles cold-start scaling for models at zero replicas using dynamic client" "Go (leader-elected runnable)"
            coordinator = container "Coordinator" "Experimental: dispatches cluster-wide GPU rebalancing across models" "Go (leader-elected runnable)"
            reconcilers = container "Discovery Reconcilers" "Watches HPAs, InferencePools, ScaledObjects, ConfigMaps to discover and configure autoscaling targets" "Go (controller-runtime)"
            datastore = container "In-Memory Datastore" "Holds discovered model entries, configuration, and metrics state keyed by model_id + namespace" "Go in-process"
            metricsEndpoint = container "Metrics Endpoint" "Serves controller metrics on :8443/metrics with TLS and TokenReview/SAR auth" "Go (controller-runtime)"
            crdWatcher = container "CRD Watcher" "Monitors API server for late-installed optional CRDs and triggers controller restart" "Go runnable"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        prometheus = softwareSystem "Prometheus / Thanos Querier" "Metrics collection and query platform for inference metrics" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Manages ServiceMonitor CRDs for metrics scraping configuration" "External"
        gaie = softwareSystem "Gateway API Inference Extension" "Provides InferencePool CRDs for pool-based autoscaling targets" "Internal Platform"
        keda = softwareSystem "KEDA" "Optional: provides ScaledObject CRDs for annotation-based model discovery" "External"
        lws = softwareSystem "LeaderWorkerSet" "Optional: enables multi-worker (tensor-parallel) deployment scaling" "External"

        # Relationships
        sre -> wva "Configures via ConfigMaps and deployment parameters"
        datascientist -> k8sApi "Deploys ML models with HPAs/InferencePools"

        wva -> k8sApi "Watch/list/patch Deployments, HPAs, InferencePools, ScaledObjects, ConfigMaps, Nodes, Pods" "HTTPS/6443 TLS 1.2+"
        wva -> prometheus "Query inference metrics (KV cache, queue depth, throughput)" "HTTPS/9090-9091 TLS 1.2+"
        wva -> gaie "Watch InferencePool CRDs; import API types" "Kubernetes API"
        wva -> keda "Optional: watch ScaledObject CRDs" "Kubernetes API"
        wva -> lws "Optional: scale LeaderWorkerSet workloads" "Kubernetes API"
        prometheusOperator -> wva "ServiceMonitor scrapes metrics" "HTTPS/8443 TLS"

        # Internal relationships
        reconcilers -> datastore "Registers models and config"
        saturationEngine -> datastore "Reads models and config"
        saturationEngine -> prometheus "Queries metrics" "HTTPS"
        saturationEngine -> k8sApi "Patches scale subresources" "HTTPS"
        scaleFromZeroEngine -> datastore "Reads zero-replica models"
        scaleFromZeroEngine -> k8sApi "Patches scale subresources" "HTTPS"
        coordinator -> datastore "Reads GPU state"
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

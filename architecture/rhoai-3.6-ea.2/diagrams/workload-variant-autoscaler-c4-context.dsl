workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and manages LLM inference workloads"
        platformadmin = person "Platform Admin" "Configures autoscaling policies via ConfigMaps"

        wva = softwareSystem "Workload-Variant-Autoscaler" "Saturation-aware autoscaler for LLM inference model servers deployed via llm-d" {
            saturationEngine = container "Saturation Engine" "Collects Prometheus metrics, runs Kalman filter + saturation analysis, computes target replicas" "Go optimization loop"
            scaleFromZero = container "Scale-from-Zero Engine" "Handles scaling idle inference deployments from zero replicas" "Go optimization loop"
            configMapReconciler = container "ConfigMapReconciler" "Watches labeled ConfigMaps for live configuration updates" "controller-runtime Reconciler"
            hpaReconciler = container "HPAReconciler" "Discovers workloads via HorizontalPodAutoscaler annotations" "controller-runtime Reconciler"
            inferencePoolReconciler = container "InferencePoolReconciler" "Watches InferencePool resources for pool-based autoscaling" "controller-runtime Reconciler"
            scaledObjectReconciler = container "ScaledObjectReconciler" "Watches KEDA ScaledObjects for target discovery (conditional)" "controller-runtime Reconciler"
            coordinator = container "Coordinator" "Cluster-wide GPU rebalancing loop (experimental)" "Go optimization loop"
            directActuator = container "DirectActuator" "Scales Deployments and LeaderWorkerSets via Scale subresource" "Go actuator"
        }

        k8sapi = softwareSystem "Kubernetes API" "Kubernetes control plane API server" "External"
        prometheus = softwareSystem "Prometheus / Thanos Querier" "Time-series metrics database for inference workload metrics" "Internal Platform"
        gatewayAPIExt = softwareSystem "Gateway API Inference Extension" "InferencePool CRD provider for pool-based autoscaling" "Internal Platform"
        keda = softwareSystem "KEDA" "Event-driven autoscaler providing ScaledObject CRD" "Internal Platform"
        lws = softwareSystem "LeaderWorkerSet" "Multi-pod inference deployment controller" "Internal Platform"
        promOperator = softwareSystem "prometheus-operator" "Manages ServiceMonitor CRDs for Prometheus scraping" "Internal Platform"
        gpuOperator = softwareSystem "NVIDIA GPU Operator" "Exposes GPU capacity via Node labels/status" "Internal Platform"
        epp = softwareSystem "Endpoint Picker (EPP)" "Publishes routing-aware metrics consumed via Prometheus" "Internal Platform"

        datascientist -> wva "Deploys inference workloads (indirectly via HPAs/InferencePools)"
        platformadmin -> wva "Configures autoscaling policies via ConfigMaps"

        wva -> k8sapi "Watch HPAs, ScaledObjects, InferencePools, ConfigMaps; scale Deployments/LWS" "HTTPS/6443"
        wva -> prometheus "Query KV-cache saturation, queue depth, throughput metrics" "HTTPS/9091"
        wva -> gatewayAPIExt "Watch InferencePool resources" "Kubernetes API"
        wva -> keda "Watch ScaledObjects (conditional)" "Kubernetes API"
        wva -> lws "Scale LeaderWorkerSets (conditional)" "Kubernetes API"
        wva -> gpuOperator "Read Node GPU capacity (inventory mode)" "Kubernetes API"

        prometheus -> wva "Scrape controller metrics via ServiceMonitor" "HTTPS/8443"
        promOperator -> wva "Discovers metrics endpoint via ServiceMonitor CRD"

        saturationEngine -> directActuator "Computed replica counts"
        scaleFromZero -> directActuator "Scale-from-zero decisions"
        coordinator -> directActuator "GPU rebalance commands"
        configMapReconciler -> saturationEngine "Configuration updates"
        hpaReconciler -> saturationEngine "Workload discovery"
        inferencePoolReconciler -> saturationEngine "Pool configuration"
        scaledObjectReconciler -> saturationEngine "ScaledObject discovery"
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
                color #000000
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

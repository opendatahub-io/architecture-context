workspace {
    model {
        admin = person "Platform Admin" "Configures autoscaling via annotated HPAs/ScaledObjects and ConfigMaps"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Intelligent autoscaler for LLM inference model servers based on saturation, queueing theory, and throughput analysis" {
            controllerManager = container "WVA Controller Manager" "Main process running reconcilers, engines, and optional coordinator" "Go Controller (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Collects Prometheus metrics, routes to analyzers, applies optimizer pipeline, emits scaling decisions" "Engine Loop"
            scaleFromZeroEngine = container "Scale-from-Zero Engine" "100ms polling loop detecting zero-replica variants with pending requests" "Engine Loop"
            coordinator = container "Coordinator" "Leader-elected 15s ticker dispatching HPAs/ScaledObjects to plugins for GPU rebalance" "Engine Loop (experimental)"
            hpaReconciler = container "HPA Reconciler" "Tracks namespaces with annotated HPAs" "Reconciler"
            scaledObjectReconciler = container "ScaledObject Reconciler" "Tracks namespaces with annotated ScaledObjects" "Reconciler"
            inferencePoolReconciler = container "InferencePool Reconciler" "Watches Gateway API InferencePool CRs" "Reconciler"
            configMapReconciler = container "ConfigMap Reconciler" "Watches labeled ConfigMaps for dynamic configuration" "Reconciler"
        }

        prometheus = softwareSystem "Prometheus / Thanos Querier" "Time-series metrics database for inference engine metrics" "External"
        gatewayAPIExt = softwareSystem "Gateway API Inference Extension" "InferencePool CRDs for endpoint pool management" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling via ScaledObjects" "External Optional"
        lws = softwareSystem "LeaderWorkerSet" "Distributed inference scale target" "External Optional"
        gpuOperator = softwareSystem "GPU Operator" "Node GPU labels for capacity discovery (NVIDIA/AMD/Intel)" "External Optional"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster control plane for watches, patches, and scale operations" "Infrastructure"
        inferenceServers = softwareSystem "vLLM / SGLang Inference Servers" "LLM model servers exporting performance metrics" "Internal"
        epp = softwareSystem "Gateway API EPP" "Endpoint Picker providing flow-control queue metrics" "Internal"
        kserve = softwareSystem "KServe" "Inference serving platform (manifest sync target)" "Internal"
        hpa = softwareSystem "HorizontalPodAutoscaler" "Kubernetes native horizontal pod autoscaler reading wva_desired_replicas" "Infrastructure"

        admin -> wva "Configures via annotated HPAs/ScaledObjects and labeled ConfigMaps"
        wva -> prometheus "Queries inference metrics (KV cache, queue depth, TTFT, ITL)" "HTTPS/443 or 9090, Bearer Token"
        wva -> k8sAPI "Watches/patches HPAs, ScaledObjects, Deployments, ConfigMaps, Nodes" "HTTPS/443, SA Token"
        wva -> epp "Scrapes flow-control queue metrics for scale-from-zero" "HTTP(S)/Pod port"
        wva -> gatewayAPIExt "Watches InferencePool CRs" "K8s API"
        wva -> kserve "Syncs kustomize manifests (CI workflow)" "GitHub Actions"
        inferenceServers -> prometheus "Exports KV cache, queue, latency, token metrics" "Prometheus scrape"
        hpa -> wva "Reads wva_desired_replicas external metric" "HTTPS/8443, Bearer Token"
        hpa -> k8sAPI "Patches scale subresource" "HTTPS/443"

        controllerManager -> saturationEngine "Runs"
        controllerManager -> scaleFromZeroEngine "Runs"
        controllerManager -> coordinator "Runs (optional)"
        controllerManager -> hpaReconciler "Runs"
        controllerManager -> scaledObjectReconciler "Runs"
        controllerManager -> inferencePoolReconciler "Runs"
        controllerManager -> configMapReconciler "Runs"
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
            element "External Optional" {
                background #cccccc
                color #333333
                border dashed
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
        }
    }
}

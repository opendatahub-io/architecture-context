workspace {
    model {
        admin = person "Platform Admin" "Creates VariantAutoscaling resources defining scaling parameters for LLM model variants"

        wva = softwareSystem "Workload Variant Autoscaler (WVA)" "Kubernetes operator that computes optimal replica counts for LLM inference workloads using saturation metrics, KV cache analysis, and queueing theory" {
            controllerManager = container "Controller Manager" "Reconciles VariantAutoscaling CRs, manages lifecycle, patches status with scaling decisions" "Go Operator (controller-runtime)"
            saturationEngine = container "Saturation Engine" "Polls Prometheus every 30s, runs V1/V2/QM analyzers, computes desired replicas per variant" "Go (goroutine)"
            scaleFromZeroEngine = container "Scale-From-Zero Engine" "Polls EPP pods every 100ms for pending requests on inactive variants, triggers immediate scale-up" "Go (goroutine)"
            decisionCache = container "Decision Cache" "In-memory shared state between engines and controller for fast decision propagation" "Go (in-memory)"
            datastore = container "Datastore" "Tracks InferencePool state and namespace-to-resource mappings" "Go (in-memory)"
        }

        prometheus = softwareSystem "Prometheus (Thanos Querier)" "Time-series metrics database providing vLLM inference server metrics via PromQL" "External"
        vllm = softwareSystem "vLLM Inference Servers" "Model serving instances emitting saturation metrics (KV cache, queue depth, token rates)" "External"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for watching/updating CRs, Deployments, ConfigMaps" "External"
        hpa = softwareSystem "HPA / KEDA" "External autoscaler that consumes WVA metrics to perform actual scaling" "External"
        inferencePool = softwareSystem "InferencePool (Gateway API IE)" "CRD for workload pool configuration and EPP discovery" "Internal Platform"
        eppPods = softwareSystem "EPP (Endpoint Picker) Pods" "Endpoint picker pods providing flow control queue metrics for scale-from-zero" "Internal Platform"
        gpuOperator = softwareSystem "GPU Operator" "Provides GPU node labels for cost-aware GPU resource allocation" "External"
        lwsController = softwareSystem "LeaderWorkerSet Controller" "Manages multi-node inference workloads (conditional scale target)" "External"

        admin -> wva "Creates VariantAutoscaling CRs via kubectl"
        wva -> prometheus "Queries vLLM metrics via PromQL" "HTTPS/9091"
        vllm -> prometheus "Emits inference metrics" "Scraped by Prometheus"
        wva -> k8sApi "Watch/CRUD VariantAutoscaling, Deployment, ConfigMap, InferencePool" "HTTPS/6443"
        wva -> eppPods "Scrape flow_control_queue_size" "HTTP/configurable"
        wva -> hpa "Emits wva_desired_replicas, wva_current_replicas, wva_desired_ratio" "HTTPS/8443"
        hpa -> k8sApi "Scales Deployments based on WVA metrics" "HTTPS/6443"
        wva -> gpuOperator "Reads GPU node labels for limited mode" "HTTPS/6443 (via API)"
        wva -> lwsController "Scales LeaderWorkerSet for multi-node inference" "HTTPS/6443 (via API)"
        inferencePool -> wva "Watched by controller for EPP config discovery" "HTTPS/6443 (via API)"

        saturationEngine -> prometheus "PromQL: kv_cache_usage_perc, num_requests_waiting" "HTTPS/9091"
        saturationEngine -> decisionCache "Writes scaling decisions"
        scaleFromZeroEngine -> eppPods "Reads queue size" "HTTP"
        scaleFromZeroEngine -> decisionCache "Writes scale-up decisions"
        scaleFromZeroEngine -> k8sApi "Direct /scale subresource PATCH" "HTTPS/6443"
        decisionCache -> controllerManager "DecisionTrigger channel"
        controllerManager -> k8sApi "Patches VA status" "HTTPS/6443"
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
                background #6ba5e7
                color #ffffff
            }
        }
    }
}

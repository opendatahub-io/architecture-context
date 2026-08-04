workspace {
    model {
        sre = person "SRE / Platform Admin" "Configures autoscaling policies and monitors GPU utilization"
        dataScientist = person "Data Scientist" "Deploys inference workloads that WVA scales"

        wva = softwareSystem "Workload Variant Autoscaler" "GPU-aware saturation-based autoscaling controller for LLM inference model servers" {
            controllerManager = container "Controller Manager" "Runs four reconciliation controllers and scaling engine" "Go controller-runtime Operator"
            configMapCtrl = container "ConfigMap Controller" "Reconciles dynamic configuration from ConfigMap" "controller-runtime Reconciler"
            hpaCtrl = container "HPA Controller" "Monitors existing HorizontalPodAutoscaler state" "controller-runtime Reconciler"
            inferencePoolCtrl = container "InferencePool Controller" "Watches InferencePool resources (GA + experimental API groups)" "controller-runtime Reconciler"
            scaledObjectCtrl = container "ScaledObject Controller" "Optional KEDA ScaledObject integration" "controller-runtime Reconciler"
            coordinator = container "Coordinator" "Orchestrates scaling engines and plugins" "Go"
            directActuator = container "Direct Actuator" "Applies scale via autoscaling/v1/Scale subresource" "Go"
            gpuPlugin = container "GPU Rebalancing Plugin" "Inspects ResourceQuotas for GPU-aware decisions" "Go"
            metricsEndpoint = container "Metrics Endpoint" "Secured metrics on :8443 with TLS + TokenReview/SAR" "HTTPS"
        }

        prometheus = softwareSystem "Prometheus" "Time-series metrics database for inference workload saturation metrics" "External"
        kubeAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management and scale actuation" "Infrastructure"
        keda = softwareSystem "KEDA" "Kubernetes Event-Driven Autoscaler (optional integration)" "External"
        gatewayAPIExt = softwareSystem "Gateway API Inference Extension" "Provides InferencePool CRDs for pool-based autoscaling" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages Prometheus monitoring resources via ServiceMonitor CRDs" "Internal RHOAI"

        sre -> wva "Configures scaling via ConfigMap"
        dataScientist -> kubeAPI "Deploys InferenceService / InferencePool"

        wva -> prometheus "Queries saturation metrics" "HTTPS TLS 1.2+ / Bearer token or mTLS"
        wva -> kubeAPI "Watches resources, actuates scale changes" "HTTPS/WSS :6443 TLS 1.2+"
        wva -> keda "Watches ScaledObject resources (optional)" "Kubernetes API"
        wva -> gatewayAPIExt "Watches InferencePool resources" "Kubernetes API"
        wva -> prometheusOperator "Creates ServiceMonitor" "Kubernetes API"

        controllerManager -> configMapCtrl "Runs"
        controllerManager -> hpaCtrl "Runs"
        controllerManager -> inferencePoolCtrl "Runs"
        controllerManager -> scaledObjectCtrl "Runs"
        controllerManager -> coordinator "Delegates scaling decisions"
        coordinator -> directActuator "Actuates scale"
        coordinator -> gpuPlugin "GPU-aware scheduling"
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
            element "Infrastructure" {
                background #6c8ebf
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

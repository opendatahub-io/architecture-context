workspace {
    model {
        platformEngineer = person "Platform Engineer" "Configures autoscaling policies via ConfigMaps and monitors inference workload scaling"

        wva = softwareSystem "Workload Variant Autoscaler" "Kubernetes controller that performs intelligent autoscaling for inference model servers based on saturation metrics, with Kalman filter prediction" {
            configmapController = container "ConfigMap Controller" "Reconciles ConfigMap resources, bootstraps initial configuration, propagates runtime changes" "Go controller-runtime"
            hpaController = container "HPA Controller" "Reconciles HorizontalPodAutoscaler resources to discover autoscaling targets" "Go controller-runtime"
            inferencePoolController = container "InferencePool Controller" "Reconciles InferencePool resources for pool-based autoscaling (gateway-api-inference-extension)" "Go controller-runtime"
            scaledObjectController = container "ScaledObject Controller" "Reconciles KEDA ScaledObject resources (conditional, requires KEDA CRDs)" "Go controller-runtime"
            optimizationEngine = container "Optimization Engine" "Kalman filter-based prediction engine that computes scaling decisions from saturation metrics" "Go"
            directActuator = container "Direct Actuator" "Updates Scale subresources on Deployments and LeaderWorkerSets" "Go"
            gpuRebalancePlugin = container "GPU Rebalance Plugin" "Inspects ResourceQuotas and discovers GPU-equipped nodes for topology-aware scaling" "Go"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics on :8443 with TokenReview/SAR authentication and TLS" "controller-runtime :8443"
            healthEndpoint = container "Health Endpoint" "Unauthenticated health/readiness probes on :8081" "HTTP :8081"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and query system; provides saturation metrics for scaling decisions" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaler providing ScaledObject CRDs (optional dependency)" "External"
        gatewayAPIExt = softwareSystem "Gateway API Inference Extension" "Provides InferencePool CRDs for pool-based inference autoscaling (optional)" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages ServiceMonitor resources for monitoring configuration" "Internal RHOAI"

        platformEngineer -> wva "Configures autoscaling via ConfigMaps and HPAs"
        wva -> k8sAPI "Watches resources, applies scaling actions" "HTTPS/6443 TLS 1.2+ SA Token"
        wva -> prometheus "Queries saturation metrics" "HTTP/HTTPS TLS 1.2+ Bearer/mTLS"
        wva -> keda "Watches ScaledObject resources (conditional)" "Kubernetes API"
        wva -> gatewayAPIExt "Watches InferencePool resources" "Kubernetes API"
        wva -> prometheusOperator "Watches ServiceMonitor resources" "Kubernetes API"

        configmapController -> optimizationEngine "Provides runtime configuration"
        hpaController -> optimizationEngine "Registers HPA scaling targets"
        inferencePoolController -> optimizationEngine "Registers pool scaling targets"
        scaledObjectController -> optimizationEngine "Registers KEDA scaling targets"
        optimizationEngine -> directActuator "Issues scaling decisions"
        gpuRebalancePlugin -> optimizationEngine "Provides GPU topology data"
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
            element "Internal RHOAI" {
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

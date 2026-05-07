workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or ODH Dashboard"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes-native operator for managing distributed training jobs across PyTorch, TensorFlow, XGBoost, MPI, JAX, PaddlePaddle" {
            controller = container "Training Operator Controller" "Reconciles 6 training job CRDs, manages pod/service lifecycle, gang scheduling integration" "Go (controller-runtime)"
            webhook = container "Webhook Server" "Validates CREATE/UPDATE of training job CRDs (PyTorch, TF, XGBoost, JAX, Paddle)" "Go (9443/TCP TLS)"
            certController = container "OPA Cert Controller" "Manages self-signed TLS certificates for webhook endpoint" "Go Library"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics for pod/service/job counters" "HTTP 8080/TCP"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, admission control, and watch events" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling via PodGroup CRD (scheduling.volcano.sh)" "External Optional"
        schedulerPlugins = softwareSystem "Scheduler-Plugins" "Gang scheduling via PodGroup CRD (scheduling.x-k8s.io)" "External Optional"
        prometheus = softwareSystem "OpenShift Monitoring" "Prometheus metrics collection via PodMonitor" "Internal RHOAI"
        kubeDNS = softwareSystem "Kubernetes DNS" "Pod FQDN resolution for distributed training coordination" "External"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys training-operator via Kustomize overlay" "Internal RHOAI"
        kueue = softwareSystem "Kueue (MultiKueue)" "Job queuing and multi-cluster scheduling via managedBy field" "External Optional"

        # User interactions
        user -> trainingOperator "Creates PyTorchJob, TFJob, XGBoostJob, MPIJob, JAXJob, PaddleJob CRs" "kubectl / Dashboard"

        # Operator interactions
        trainingOperator -> k8sAPI "CRUD for Pods, Services, ConfigMaps, HPAs, NetworkPolicies, Events, RBAC" "HTTPS/443 SA token"
        k8sAPI -> trainingOperator "Admission webhooks for training job validation" "HTTPS/9443 TLS"
        trainingOperator -> volcano "Creates/manages PodGroup for gang scheduling" "via K8s API"
        trainingOperator -> schedulerPlugins "Creates/manages PodGroup for gang scheduling" "via K8s API"
        trainingOperator -> kubeDNS "Worker init containers resolve master pod FQDN" "DNS/53 UDP"
        prometheus -> trainingOperator "Scrapes operator metrics via PodMonitor" "HTTP/8080"
        rhodsOperator -> trainingOperator "Deploys operator via manifests/rhoai Kustomize overlay" "Kustomize"
        kueue -> trainingOperator "Delegates job reconciliation via managedBy field" "CRD field"

        # Internal container interactions
        controller -> webhook "Routes admission requests" "Internal"
        certController -> webhook "Provides TLS certificates" "Self-signed CA"
        controller -> metricsEndpoint "Exposes metrics" "Internal"
    }

    views {
        systemContext trainingOperator "SystemContext" {
            include *
            autoLayout
        }

        container trainingOperator "Containers" {
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
            element "External Optional" {
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

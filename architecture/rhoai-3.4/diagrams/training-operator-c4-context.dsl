workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages distributed training jobs"
        platformOp = person "Platform Operator" "Deploys and manages the RHOAI platform"

        trainingOperator = softwareSystem "Kubeflow Training Operator (KFTO)" "Kubernetes-native operator for managing distributed AI/ML training jobs across PyTorch, TensorFlow, XGBoost, JAX, MPI, PaddlePaddle" {
            controller = container "training-operator Controller" "Reconciles training job CRDs, creates pods and services for distributed training" "Go (controller-runtime)" "operator"
            webhook = container "Validating Webhook" "Validates training job CRDs on CREATE/UPDATE (PyTorchJob, TFJob, XGBoostJob, JAXJob, PaddleJob)" "Go (admission webhook)" "webhook"
            certController = container "OPA cert-controller" "Auto-rotates TLS certificates for webhook server" "Go Library" "library"
            metricsExporter = container "Prometheus Metrics" "Exposes job lifecycle counters (created, deleted, successful, failed, restarted)" "HTTP /metrics" "metrics"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.31+)" "External"
        volcano = softwareSystem "Volcano" "Gang scheduling via PodGroup CRD (scheduling.volcano.sh)" "External,Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduling via PodGroup CRD (scheduling.x-k8s.io)" "External,Optional"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection via PodMonitor" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys KFTO via kustomize overlays" "Internal RHOAI"

        # Relationships - External
        user -> trainingOperator "Creates PyTorchJob/TFJob/XGBoostJob/JAXJob/MPIJob/PaddleJob via kubectl" "HTTPS/443"
        platformOp -> rhodsOperator "Installs and configures RHOAI platform"

        # Relationships - Internal
        controller -> kubernetes "CRUD on Pods, Services, CRDs, ConfigMaps, Events, RBAC, NetworkPolicies, HPA, PodGroups" "HTTPS/443 TLS 1.2+"
        controller -> volcano "Creates PodGroup CRs for coordinated scheduling" "HTTPS/443 TLS 1.2+"
        controller -> schedulerPlugins "Creates PodGroup CRs (alternative gang scheduling)" "HTTPS/443 TLS 1.2+"
        certController -> webhook "Generates and rotates TLS certs" "In-process"
        kubernetes -> webhook "Sends admission reviews for training job CRDs" "HTTPS/9443 TLS"
        prometheus -> metricsExporter "Scrapes job lifecycle metrics via PodMonitor" "HTTP/8080"
        rhodsOperator -> trainingOperator "Deploys via kustomize manifests/rhoai/ overlay" "Kustomize"

        # Container relationships
        controller -> metricsExporter "Registers and updates counters"
        controller -> webhook "Co-located, shares pod"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External,Optional" {
                background #bbbbbb
                color #ffffff
                border dashed
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "operator" {
                background #4a90e2
                color #ffffff
            }
            element "webhook" {
                background #4a90e2
                color #ffffff
            }
            element "library" {
                background #50e3c2
                color #333333
            }
            element "metrics" {
                background #9013fe
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

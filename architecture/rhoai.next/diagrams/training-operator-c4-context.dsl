workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or platform UI"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes operator managing distributed ML training jobs across 6 frameworks (PyTorch, TF, XGBoost, MPI, JAX, Paddle)" {
            controller = container "Training Operator Controller" "Reconciles 6 training job CRD types, creates pods/services/PodGroups" "Go Operator (controller-runtime)"
            webhookServer = container "Validating Webhook Server" "Validates CREATE/UPDATE on training job CRDs (PyTorch, TF, XGBoost, JAX, Paddle)" "HTTPS/9443 TLS"
            certManager = container "Certificate Manager" "Self-managed webhook TLS certificate rotation" "OPA cert-controller"
            metricsExporter = container "Prometheus Metrics" "Exposes job lifecycle counters (created, deleted, succeeded, failed, restarted)" "HTTP/8080"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource CRUD, admission webhooks, and informer watches" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection via PodMonitor" "External"
        volcano = softwareSystem "Volcano Scheduler" "Optional gang scheduling via PodGroup CRDs (scheduling.volcano.sh/v1beta1)" "External"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler-Plugins" "Optional gang scheduling via PodGroup CRDs (scheduling.x-k8s.io/v1alpha1)" "External"
        kueue = softwareSystem "Kueue" "Queue-based job scheduling; manages training jobs via managedBy field and external webhooks" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys training-operator via kustomize manifests" "Internal RHOAI"
        trainingPods = softwareSystem "Training Pods" "Distributed training workload pods created by operator with framework-specific configuration" "Created Resource"

        user -> trainingOperator "Creates training jobs (PyTorchJob, TFJob, etc.) via kubectl" "HTTPS/6443"
        trainingOperator -> k8sAPI "CRUD for Pods, Services, ConfigMaps, PodGroups, RBAC, CRDs" "HTTPS/6443 SA Token"
        k8sAPI -> trainingOperator "Admission webhook calls for validation" "HTTPS/9443 TLS"
        trainingOperator -> trainingPods "Creates pods with framework env vars (TF_CONFIG, MASTER_ADDR, WORLD_SIZE, RANK)" "via K8s API"
        prometheus -> trainingOperator "Scrapes job lifecycle metrics" "HTTP/8080"
        trainingOperator -> volcano "Creates PodGroup CRs for gang scheduling" "HTTPS/6443 via K8s API"
        trainingOperator -> schedulerPlugins "Creates PodGroup CRs for gang scheduling" "HTTPS/6443 via K8s API"
        rhodsOperator -> trainingOperator "Deploys via manifests/rhoai/ kustomization" "Kustomize"
        kueue -> trainingOperator "Intercepts training job CRDs via mutating/validating webhooks" "Admission Webhooks"

        controller -> webhookServer "Serves webhook endpoints"
        certManager -> webhookServer "Provisions and rotates TLS certificates"
        controller -> metricsExporter "Exposes metrics"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Created Resource" {
                background #f5a623
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

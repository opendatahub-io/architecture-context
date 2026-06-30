workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or ODH Dashboard"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes operator managing distributed training jobs across PyTorch, TensorFlow, XGBoost, MPI, PaddlePaddle, and JAX frameworks" {
            controller = container "Training Operator Controller" "Reconciles training job CRDs, manages pod/service lifecycle, gang scheduling, and status tracking" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates PyTorchJob, TFJob, XGBoostJob, PaddleJob, JAXJob resources on create/update" "Go (controller-runtime webhook)" "9443/TCP HTTPS"
            certRotator = container "cert-controller" "Manages webhook TLS certificate rotation" "OPA cert-controller library"
            commonFramework = container "Common Controller Framework" "Shared reconciliation logic for pod lifecycle, service management, gang scheduling, status tracking" "Go (pkg/controller.v1/common)"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform and API server" "External" {
            apiServer = container "API Server" "Kubernetes API for resource CRUD, CRD watch, admission webhooks" "Kubernetes" "443/TCP HTTPS"
        }

        volcano = softwareSystem "Volcano" "Gang scheduling system for co-scheduling distributed training pods" "External, Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduling backend via PodGroup CRD" "External, Optional"
        kueue = softwareSystem "Kueue" "Job queuing and MultiKueue delegation for training workloads" "Internal ODH, Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor" "Internal Platform"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys training-operator from kustomize manifests" "Internal Platform"
        certManager = softwareSystem "cert-controller (OPA)" "Embedded library for webhook certificate management" "External"

        # Relationships
        user -> trainingOperator "Creates PyTorchJob, TFJob, XGBoostJob, MPIJob, PaddleJob, JAXJob via kubectl" "HTTPS/443"
        trainingOperator -> kubernetes "Watches CRDs, creates Pods/Services/ConfigMaps, manages RBAC, updates webhook config" "HTTPS/443, SA token"
        kubernetes -> trainingOperator "Sends admission webhook requests for training job validation" "HTTPS/9443, API server cert"
        trainingOperator -> volcano "Creates/syncs PodGroups for gang scheduling (optional)" "HTTPS/443, SA token"
        trainingOperator -> schedulerPlugins "Creates/syncs PodGroups for gang scheduling (optional)" "HTTPS/443, SA token"
        kueue -> trainingOperator "Intercepts training CRDs via mutating/validating webhooks; delegates via MultiKueue" "Webhook"
        prometheus -> trainingOperator "Scrapes operator metrics" "HTTP/8080"
        rhodsOperator -> trainingOperator "Deploys via kustomize manifests (manifests/rhoai)" "Kustomize"

        # Internal container relationships
        controller -> commonFramework "Uses shared reconciliation logic"
        controller -> webhookServer "Registers validation handlers"
        certRotator -> webhookServer "Rotates TLS certificates"
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
            element "External, Optional" {
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "Internal ODH, Optional" {
                background #7ed321
                color #ffffff
                shape RoundedBox
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

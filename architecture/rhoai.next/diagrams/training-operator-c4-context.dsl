workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or ODH Dashboard"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes operator managing distributed training jobs across 6 ML frameworks (PyTorch, TensorFlow, MPI, JAX, XGBoost, PaddlePaddle)" {
            controller = container "Training Operator Controller" "Reconciles 6 CRD types, creates Pods/Services/RBAC per framework, manages job lifecycle" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates PyTorchJob, TFJob, JAXJob, XGBoostJob, PaddleJob at admission time" "HTTPS 9443/TCP"
            certController = container "cert-controller" "Generates and rotates webhook TLS certificates" "Embedded library (open-policy-agent/cert-controller)"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing API server, scheduler, and DNS" "External" {
            apiServer = container "API Server" "REST API for cluster resource management" "HTTPS 443/TCP"
            dns = container "CoreDNS" "Cluster DNS for headless service resolution" "UDP 53"
            scheduler = container "Default Scheduler" "Pod scheduling" "Internal"
        }

        volcano = softwareSystem "Volcano" "Optional gang scheduler for coordinated pod scheduling via PodGroup CRD" "External Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Optional alternative gang scheduler via PodGroup CRD" "External Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via PodMonitor" "External Optional"
        certManager = softwareSystem "cert-controller Library" "Webhook certificate generation and rotation" "External"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys training-operator via Kustomize manifests" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Optional job queueing system (ManagedBy field integration)" "External Optional"

        # User interactions
        dataScientist -> trainingOperator "Creates PyTorchJob/TFJob/MPIJob/JAXJob/XGBoostJob/PaddleJob" "kubectl / HTTPS 443"

        # Operator interactions
        trainingOperator -> kubernetes "CRD reconciliation, Pod/Service/ConfigMap/RBAC CRUD" "HTTPS/443, SA Token"
        trainingOperator -> volcano "Creates PodGroup CRs for gang scheduling" "HTTPS/443, SA Token"
        trainingOperator -> schedulerPlugins "Creates PodGroup CRs for gang scheduling" "HTTPS/443, SA Token"

        # Monitoring
        prometheus -> trainingOperator "Scrapes operator metrics (jobs created/deleted/succeeded/failed)" "HTTP/8080"

        # Deployment
        rhodsOperator -> trainingOperator "Deploys via manifests/rhoai Kustomize overlay" "Kustomize"

        # Container-level interactions
        controller -> apiServer "Watch CRDs, create Pods/Services/ConfigMaps" "HTTPS/443, TLS 1.2+, SA Token"
        apiServer -> webhookServer "Admission validation requests" "HTTPS/9443, TLS (self-signed), API server client cert"
        certController -> webhookServer "Provides TLS certificates" "Secret mount"
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
            element "External Optional" {
                background #cccccc
                color #333333
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
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

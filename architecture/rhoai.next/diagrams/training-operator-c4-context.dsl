workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or notebooks"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Manages lifecycle of distributed training jobs across 6 ML frameworks (PyTorch, TF, MPI, JAX, XGBoost, Paddle)" {
            controller = container "Training Operator Controller" "Reconciles 6 training CRDs, creates Pods/Services/RBAC per framework" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates training job specs at admission time" "HTTPS 9443, TLS (cert-controller)"
            certController = container "cert-controller" "Generates and rotates webhook TLS certificates" "Go Library (open-policy-agent/cert-controller)"
            kubectlDelivery = container "kubectl-delivery" "Init container delivering kubectl binary to MPI launcher pods" "Container Image"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        volcano = softwareSystem "Volcano" "Gang scheduler for coordinated pod scheduling" "External Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduler via PodGroup CRD" "External Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        rhodsOperator = softwareSystem "RHODS/ODH Operator" "Platform operator that deploys training-operator" "Internal ODH"

        dataScientist -> trainingOperator "Creates PyTorchJob/TFJob/MPIJob/JAXJob/XGBoostJob/PaddleJob via kubectl" "HTTPS/443"
        trainingOperator -> kubernetes "CRUD for Pods, Services, ConfigMaps, RBAC resources" "HTTPS/443"
        trainingOperator -> volcano "Creates PodGroup CRs for gang scheduling" "HTTPS/443"
        trainingOperator -> schedulerPlugins "Creates PodGroup CRs for alternative gang scheduling" "HTTPS/443"
        prometheus -> trainingOperator "Scrapes operator metrics via PodMonitor" "HTTP/8080"
        rhodsOperator -> trainingOperator "Deploys via Kustomize manifests (rhoai overlay)" "Kustomize"
        kubernetes -> trainingOperator "Sends webhook validation requests" "HTTPS/9443"

        controller -> webhookServer "Runs webhook handlers within same process" ""
        certController -> webhookServer "Provisions TLS certificate" ""
        kubectlDelivery -> controller "Delivers kubectl binary to MPI launcher pods" "Init container volume"
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
                background #bbbbbb
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
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

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or ODH Dashboard"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes operator managing distributed training jobs across PyTorch, TensorFlow, MPI, JAX, XGBoost, and PaddlePaddle frameworks" {
            controller = container "Training Operator Controller" "Manages lifecycle of 6 distributed training CRDs, creating Pods, Services, and auxiliary resources per framework" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates training job resources on admission (5 validating webhooks)" "Go HTTPS Server (port 9443)"
            pytorchCtrl = container "PyTorch Controller" "Handles PyTorchJob reconciliation with elastic training and C10d/etcd rendezvous" "Go Controller"
            tfCtrl = container "TensorFlow Controller" "Handles TFJob reconciliation with Chief/PS/Worker/Evaluator topology" "Go Controller"
            mpiCtrl = container "MPI Controller" "Handles MPIJob reconciliation with launcher/worker pattern and kubectl-based communication" "Go Controller"
            jaxCtrl = container "JAX Controller" "Handles JAXJob reconciliation with flat worker topology" "Go Controller"
            xgboostCtrl = container "XGBoost Controller" "Handles XGBoostJob reconciliation with Rabit tracker master/worker topology" "Go Controller"
            paddleCtrl = container "PaddlePaddle Controller" "Handles PaddleJob reconciliation in collective or parameter server mode" "Go Controller"
            kubectlDelivery = container "kubectl-delivery" "Init container that delivers kubectl binary to MPI launcher pods" "Container Image"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "API Server" "Kubernetes API for CRD reconciliation and resource management" "HTTPS/443"
            dns = container "CoreDNS" "Cluster DNS for pod-to-pod service discovery" "UDP/53"
        }

        volcano = softwareSystem "Volcano" "Gang scheduler for coordinated pod scheduling via PodGroup CRDs" "External Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduler via PodGroup CRDs" "External Optional"
        certController = softwareSystem "cert-controller" "Generates and rotates webhook TLS certificates" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor" "External Optional"
        kueue = softwareSystem "Kueue" "Job queue management with webhooks intercepting training CRDs" "External Optional"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys training-operator via Kustomize manifests" "Internal RHOAI"

        dataScientist -> trainingOperator "Creates training jobs (PyTorchJob, TFJob, MPIJob, etc.) via kubectl" "HTTPS/443"
        trainingOperator -> kubernetes "CRD reconciliation, Pod/Service/RBAC CRUD" "HTTPS/443"
        trainingOperator -> volcano "Creates PodGroup CRs for gang scheduling" "HTTPS/443"
        trainingOperator -> schedulerPlugins "Creates PodGroup CRs for alternative gang scheduling" "HTTPS/443"
        trainingOperator -> certController "Webhook certificate generation and rotation" "Library integration"
        prometheus -> trainingOperator "Scrapes operator metrics" "HTTP/8080"
        kueue -> trainingOperator "Intercepts training CRDs via webhooks" "CRD labels"
        rhodsOperator -> trainingOperator "Deploys via manifests/rhoai overlay" "Kustomize"

        controller -> webhookServer "Shares process" ""
        controller -> pytorchCtrl "Delegates PyTorchJob reconciliation" ""
        controller -> tfCtrl "Delegates TFJob reconciliation" ""
        controller -> mpiCtrl "Delegates MPIJob reconciliation" ""
        controller -> jaxCtrl "Delegates JAXJob reconciliation" ""
        controller -> xgboostCtrl "Delegates XGBoostJob reconciliation" ""
        controller -> paddleCtrl "Delegates PaddleJob reconciliation" ""
        mpiCtrl -> kubectlDelivery "Injects as init container in launcher pods" ""
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

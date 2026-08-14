workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed training jobs on OpenShift"

        trainingOperator = softwareSystem "Training Operator" "Kubernetes operator managing distributed training job lifecycle (PyTorchJob, TFJob, JAXJob, MPIJob, PaddleJob, XGBoostJob)" {
            controllerManager = container "Controller Manager" "Multi-reconciler controller-runtime operator with six CRD reconcilers" "Go, controller-runtime 0.19.1"
            webhookServer = container "Webhook Server" "Validates training job CRs on CREATE/UPDATE with Fail policy" "Go, port 9443/TCP TLS"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics with TLS encryption" "Go, port 8080/TCP HTTPS"
            certController = container "Cert Controller" "Self-signed CA and serving cert rotation via OPA cert-controller" "Go library"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource CRUD operations" "External" {
            tags "External"
        }

        openShiftAPI = softwareSystem "OpenShift APIServer" "Cluster-wide TLS profile configuration (config.openshift.io/v1)" "External" {
            tags "External"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform" {
            tags "Internal Platform"
        }

        volcano = softwareSystem "Volcano Scheduler" "Gang-scheduling support via PodGroups" "Optional External" {
            tags "External"
        }

        schedulerPlugins = softwareSystem "Scheduler Plugins" "Alternative gang-scheduling via PodGroups" "Optional External" {
            tags "External"
        }

        # Relationships
        user -> trainingOperator "Creates training job CRs (PyTorchJob, TFJob, etc.) via kubectl" "HTTPS/6443"
        trainingOperator -> kubernetesAPI "CRUD on Pods, Services, ConfigMaps, CRDs, RBAC resources" "HTTPS/6443, SA token"
        trainingOperator -> openShiftAPI "Reads TLS profile at startup" "HTTPS/6443, SA token"
        prometheus -> trainingOperator "Scrapes metrics endpoint" "HTTPS/8080"
        trainingOperator -> volcano "Creates PodGroups for gang-scheduling" "via Kubernetes API"
        trainingOperator -> schedulerPlugins "Creates PodGroups for gang-scheduling" "via Kubernetes API"
        kubernetesAPI -> trainingOperator "Routes admission webhooks" "HTTPS/9443, TLS"

        # Internal relationships
        controllerManager -> webhookServer "Serves admission webhooks"
        controllerManager -> metricsServer "Serves Prometheus metrics"
        certController -> webhookServer "Provides TLS certificates"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or SDKs"

        trainingOperator = softwareSystem "Training Operator" "Kubernetes operator managing distributed ML training jobs across PyTorch, TensorFlow, XGBoost, MPI, PaddlePaddle, and JAX frameworks" {
            controller = container "Framework Controllers" "Six reconcilers (PyTorch, TF, MPI, XGBoost, Paddle, JAX) sharing a common JobController base for Pod/Service lifecycle" "Go controller-runtime"
            webhook = container "Webhook Server" "Validates CREATE/UPDATE for all six training job CRDs" "Go Admission Webhook, 9443/TCP"
            metricsServer = container "Metrics Server" "Exposes controller-runtime Prometheus metrics" "Go HTTP Server, 8080/TCP"
            certManager = container "OPA Cert Controller" "Auto-generates and rotates TLS certificates for webhook server" "Go Library"
            tlsProfileReader = container "TLS Profile Reader" "Reads OpenShift APIServer resource to configure cipher suites dynamically" "Go"
        }

        kubeAPI = softwareSystem "Kubernetes API" "Cluster API server for resource CRUD and admission webhooks" "External"
        openShiftAPI = softwareSystem "OpenShift APIServer" "Cluster-wide TLS security profile configuration" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection via PodMonitor" "Internal Platform"
        volcano = softwareSystem "Volcano" "Gang-scheduling via PodGroup CRDs (optional)" "External"
        schedulerPlugins = softwareSystem "Scheduler Plugins" "Alternative gang-scheduling via PodGroup CRDs (optional)" "External"

        user -> trainingOperator "Creates PyTorchJob, TFJob, MPIJob, XGBoostJob, PaddleJob, JAXJob via kubectl/SDK"
        trainingOperator -> kubeAPI "CRUD Pods, Services, NetworkPolicies, PodGroups, RBAC; status updates; leader election" "HTTPS/6443"
        trainingOperator -> openShiftAPI "Reads cluster TLS security profile" "HTTPS/6443"
        kubeAPI -> trainingOperator "Sends admission review requests" "HTTPS/9443"
        prometheus -> trainingOperator "Scrapes metrics" "HTTP/8080 TLS"
        trainingOperator -> volcano "Creates PodGroups for gang-scheduling (optional)" "HTTPS/6443"
        trainingOperator -> schedulerPlugins "Creates PodGroups for gang-scheduling (optional)" "HTTPS/6443"
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
            element "Internal Platform" {
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
                background #5b9bd5
                color #ffffff
            }
        }
    }
}

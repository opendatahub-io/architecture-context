workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages distributed training jobs via kubectl or SDK"
        platformadmin = person "Platform Admin" "Deploys and configures the training operator on OpenShift"

        trainingOperator = softwareSystem "Training Operator" "Kubernetes operator managing distributed training jobs across PyTorch, TensorFlow, XGBoost, MPI, PaddlePaddle, and JAX" {
            manager = container "Manager" "controller-runtime manager orchestrating reconcilers, webhooks, cert rotation, metrics, and health probes" "Go"
            pytorchController = container "PyTorchJob Controller" "Reconciles PyTorchJob CRs: creates pods, services, NetworkPolicies, HPAs for distributed PyTorch training" "Go"
            tfController = container "TFJob Controller" "Reconciles TFJob CRs: manages PS/worker topology for distributed TensorFlow training" "Go"
            mpiController = container "MPIJob Controller" "Reconciles MPIJob CRs: manages launcher/worker pattern with kubectl-delivery init container" "Go"
            xgboostController = container "XGBoostJob Controller" "Reconciles XGBoostJob CRs for distributed XGBoost training" "Go"
            paddleController = container "PaddleJob Controller" "Reconciles PaddleJob CRs for distributed PaddlePaddle training" "Go"
            jaxController = container "JAXJob Controller" "Reconciles JAXJob CRs for distributed JAX training" "Go"
            webhookServer = container "Webhook Server" "Validates PyTorchJob, TFJob, XGBoostJob, PaddleJob, JAXJob specs via admission webhooks" "Go, 9443/TCP TLS"
            certRotator = container "Cert Rotator" "Manages webhook TLS certificates using OPA cert-controller; patches ValidatingWebhookConfiguration caBundle" "Go"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics at :8080 with TLS using cluster security profile" "Go, 8080/TCP"
        }

        kubeApiServer = softwareSystem "Kubernetes API Server" "Cluster API server for resource management, admission control, and RBAC" "External"
        openshiftConfig = softwareSystem "OpenShift APIServer Config" "Cluster-wide TLS security profile configuration" "External"
        prometheus = softwareSystem "Prometheus" "OpenShift Monitoring stack for metrics collection via PodMonitor" "Internal Platform"
        volcano = softwareSystem "Volcano" "Gang scheduler for co-scheduling all replicas of a training job (optional)" "External Optional"
        schedulerPlugins = softwareSystem "Scheduler-Plugins" "Alternative gang scheduler using PodGroup CRDs (optional)" "External Optional"

        datascientist -> trainingOperator "Creates PyTorchJob/TFJob/MPIJob/XGBoostJob/PaddleJob/JAXJob" "kubectl / SDK"
        platformadmin -> trainingOperator "Deploys and configures operator" "Kustomize / OLM"

        trainingOperator -> kubeApiServer "Watches CRDs, CRUD pods/services/RBAC/NetworkPolicies" "HTTPS/6443, ServiceAccount token"
        trainingOperator -> openshiftConfig "Reads cluster TLS security profile" "HTTPS/6443"
        prometheus -> trainingOperator "Scrapes metrics" "HTTP/8080, TLS (cluster profile)"
        trainingOperator -> volcano "Creates PodGroup for gang scheduling" "HTTPS/6443, optional"
        trainingOperator -> schedulerPlugins "Creates PodGroup for gang scheduling" "HTTPS/6443, optional"

        manager -> pytorchController "Starts reconciler"
        manager -> tfController "Starts reconciler"
        manager -> mpiController "Starts reconciler"
        manager -> xgboostController "Starts reconciler"
        manager -> paddleController "Starts reconciler"
        manager -> jaxController "Starts reconciler"
        manager -> webhookServer "Starts webhook server"
        manager -> certRotator "Starts cert rotation"
        manager -> metricsServer "Starts metrics server"
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
        }
    }
}

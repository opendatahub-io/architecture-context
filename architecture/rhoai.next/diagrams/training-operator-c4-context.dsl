workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or platform UI"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes operator for orchestrating distributed ML training jobs across PyTorch, TensorFlow, XGBoost, JAX, MPI, and PaddlePaddle frameworks" {
            pytorchController = container "PyTorchJob Controller" "Reconciles PyTorchJob CRs — creates pods, headless services, NetworkPolicy, HPA for elastic training" "Go Controller"
            tfController = container "TFJob Controller" "Reconciles TFJob CRs — creates pods and headless services with TF_CONFIG cluster specification" "Go Controller"
            xgboostController = container "XGBoostJob Controller" "Reconciles XGBoostJob CRs — creates pods and headless services with Rabit/LightGBM coordination" "Go Controller"
            jaxController = container "JAXJob Controller" "Reconciles JAXJob CRs — creates pods and headless services with coordinator-based discovery" "Go Controller"
            mpiController = container "MPIJob Controller" "Reconciles MPIJob CRs — creates pods, ConfigMaps, ServiceAccounts, Roles for SSH-based MPI execution" "Go Controller"
            paddleController = container "PaddleJob Controller" "Reconciles PaddleJob CRs — creates pods and headless services for collective/PS training" "Go Controller"
            jobController = container "JobController Base" "Shared reconciliation logic for pod/service lifecycle, status tracking, gang scheduling" "Go Library"
            webhookServer = container "Webhook Server" "Validates training job CRDs on CREATE/UPDATE for 5 framework types" "Go HTTPS Server" "9443/TCP"
            certManager = container "Cert Controller" "Automatic TLS certificate generation and rotation for webhook server" "Go Library"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus counters for training job lifecycle events" "Go HTTP Server" "8080/TCP"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource CRUD and webhook admission" "External"
        prometheus = softwareSystem "OpenShift Monitoring (Prometheus)" "Metrics collection and alerting via PodMonitor" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling via PodGroup CRDs for coordinated pod placement" "External Optional"
        schedulerPlugins = softwareSystem "Scheduler-Plugins" "Alternative gang scheduling via scheduler-plugins PodGroup CRDs" "External Optional"
        kueue = softwareSystem "Kueue" "Job queuing and quota management — provides mutating/validating webhooks for training jobs" "Internal ODH Optional"

        # Relationships
        user -> trainingOperator "Creates training jobs (PyTorchJob, TFJob, etc.) via kubectl" "HTTPS/443"
        user -> k8sAPI "kubectl apply -f trainingjob.yaml" "HTTPS/443"

        k8sAPI -> webhookServer "Admission validation for training CRDs" "HTTPS/9443"
        trainingOperator -> k8sAPI "CRUD for Pods, Services, ConfigMaps, NetworkPolicies, RBAC, PodGroups, HPA" "HTTPS/443"

        pytorchController -> jobController "Extends shared reconciliation logic"
        tfController -> jobController "Extends shared reconciliation logic"
        xgboostController -> jobController "Extends shared reconciliation logic"
        jaxController -> jobController "Extends shared reconciliation logic"
        mpiController -> jobController "Extends shared reconciliation logic"
        paddleController -> jobController "Extends shared reconciliation logic"

        certManager -> webhookServer "Provisions and rotates TLS certificates"

        prometheus -> trainingOperator "Scrapes training_operator_jobs_* metrics" "HTTP/8080"
        trainingOperator -> volcano "Creates PodGroup CRs for gang scheduling" "HTTPS/443"
        trainingOperator -> schedulerPlugins "Creates PodGroup CRs for gang scheduling" "HTTPS/443"
        kueue -> k8sAPI "Mutating/validating webhooks for training job CRDs" "HTTPS"
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
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal ODH Optional" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

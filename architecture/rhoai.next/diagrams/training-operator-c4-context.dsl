workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages distributed training jobs via kubectl or Python SDK"

        trainingOperator = softwareSystem "Training Operator (KFTO)" "Kubernetes operator managing distributed ML training jobs for PyTorch, TensorFlow, XGBoost, MPI, PaddlePaddle, and JAX" {
            controller = container "Training Operator Controller" "Reconciles 6 training job CRDs, manages pod/service lifecycle, gang scheduling, elastic scaling" "Go (controller-runtime)" "Component"
            webhooks = container "Validating Webhooks" "5 admission webhooks validating job specs: DNS names, replica structure, container requirements" "Go (9443/TCP HTTPS)" "Component"
            certRotator = container "Certificate Rotator" "Manages TLS certificates for webhook server with automatic rotation" "cert-controller" "Component"
            baseJobController = container "Base JobController" "Shared reconciliation loop: pod lifecycle, headless services, status tracking, expectations" "Go" "Component"
            pytorchController = container "PyTorch Controller" "PyTorch-specific logic: elastic training, HPA, NetworkPolicy, rendezvous" "Go" "Component"
            tfController = container "TensorFlow Controller" "TF-specific logic: PS/Worker/Chief/Evaluator topology, TF_CONFIG injection" "Go" "Component"
            xgboostController = container "XGBoost Controller" "XGBoost/LightGBM: master/worker topology" "Go" "Component"
            mpiController = container "MPI Controller" "MPI-specific: launcher/worker split, kubexec, dynamic RBAC per job" "Go" "Component"
            paddleController = container "PaddlePaddle Controller" "PaddlePaddle: collective/PS modes, elastic scaling" "Go" "Component"
            jaxController = container "JAX Controller" "JAX: coordinator-based worker topology" "Go" "Component"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        openShiftAPI = softwareSystem "OpenShift APIServer" "Provides cluster TLS security profile configuration" "External"
        openShiftMonitoring = softwareSystem "OpenShift Monitoring" "Prometheus-based metrics collection via PodMonitor" "Internal Platform"
        volcano = softwareSystem "Volcano Scheduler" "Optional gang scheduler for all-or-nothing pod scheduling" "External Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Alternative gang scheduling backend using Kubernetes scheduler-plugins" "External Optional"
        multiKueue = softwareSystem "MultiKueueController" "Optional external controller for job delegation" "External Optional"
        k8sDNS = softwareSystem "Kubernetes DNS" "Service DNS resolution for inter-replica discovery" "External"

        pythonSDK = softwareSystem "Python SDK" "Client library for programmatic training job management" "Client Library"

        # Relationships
        user -> trainingOperator "Creates training jobs (PyTorchJob, TFJob, etc.) via kubectl/SDK" "HTTPS/443"
        user -> pythonSDK "Uses to create/manage jobs programmatically"
        pythonSDK -> k8sAPI "Creates CRs via Kubernetes API" "HTTPS/443"

        trainingOperator -> k8sAPI "CRUD on Pods, Services, ConfigMaps, CRDs, PodGroups, RBAC resources" "HTTPS/443 TLS 1.2+"
        trainingOperator -> openShiftAPI "Reads cluster TLS security profile" "HTTPS/443 TLS 1.2+"
        trainingOperator -> volcano "Creates PodGroup CRs for gang scheduling" "K8s API"
        trainingOperator -> schedulerPlugins "Creates PodGroup CRs for gang scheduling" "K8s API"
        openShiftMonitoring -> trainingOperator "Scrapes Prometheus metrics via PodMonitor" "HTTPS/8080 TLS 1.2+"

        k8sAPI -> webhooks "Forwards admission requests for job CRDs" "HTTPS/9443 mTLS"

        # Internal container relationships
        controller -> baseJobController "Delegates reconciliation"
        pytorchController -> baseJobController "Extends shared logic"
        tfController -> baseJobController "Extends shared logic"
        xgboostController -> baseJobController "Extends shared logic"
        mpiController -> baseJobController "Extends shared logic"
        paddleController -> baseJobController "Extends shared logic"
        jaxController -> baseJobController "Extends shared logic"
        certRotator -> webhooks "Provides TLS certificates"
    }

    views {
        systemContext trainingOperator "SystemContext" {
            include *
            autoLayout
            description "Training Operator in the context of RHOAI platform and Kubernetes ecosystem"
        }

        container trainingOperator "Containers" {
            include *
            autoLayout
            description "Internal structure of the Training Operator showing framework controllers and shared base"
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
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Client Library" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Component" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates distributed training jobs across ML frameworks"
        mlEngineer = person "ML Engineer" "Manages training infrastructure and job configurations"

        trainingOperator = softwareSystem "Kubeflow Training Operator (KFTO)" "Kubernetes operator managing distributed training jobs across 6 ML frameworks" {
            jobController = container "JobController Base" "Shared controller for pod lifecycle, service management, status tracking, gang scheduling" "Go (controller-runtime)"
            pytorchController = container "PyTorchJob Controller" "Reconciles PyTorchJob CRs with elastic training, HPA, init containers, NetworkPolicy" "Go Controller"
            tfController = container "TFJob Controller" "Reconciles TFJob CRs with PS/AllReduce topologies and dynamic workers" "Go Controller"
            mpiController = container "MPIJob Controller" "Reconciles MPIJob CRs with launcher/worker pattern, ConfigMap hostfiles, RBAC" "Go Controller"
            xgboostController = container "XGBoostJob Controller" "Reconciles XGBoostJob CRs with master/worker topology" "Go Controller"
            paddleController = container "PaddleJob Controller" "Reconciles PaddleJob CRs with collective/PS modes" "Go Controller"
            jaxController = container "JAXJob Controller" "Reconciles JAXJob CRs with coordinator pattern" "Go Controller"
            webhookServer = container "Webhook Server" "Validates CREATE/UPDATE on 5 job types (all except MPIJob)" "Go HTTPS Server" "9443/TCP"
            certController = container "OPA Cert Controller" "Manages TLS certificate rotation for webhook server" "Go Library"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "API Server" "Kubernetes API for resource management" "HTTPS/443"
        }

        volcanoScheduler = softwareSystem "Volcano Scheduler" "Optional gang scheduling via PodGroups (scheduling.volcano.sh)" "External"
        schedulerPlugins = softwareSystem "Scheduler Plugins" "Optional gang scheduling via PodGroups (scheduling.x-k8s.io)" "External"
        kueue = softwareSystem "Kueue (MultiKueue)" "Job queue management; jobs with managedBy field are skipped by training-operator" "Internal RHOAI"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Prometheus metrics scraping via PodMonitor" "Internal RHOAI"

        # User interactions
        dataScientist -> trainingOperator "Creates PyTorchJob, TFJob, MPIJob, XGBoostJob, PaddleJob, JAXJob via kubectl"
        mlEngineer -> trainingOperator "Manages training operator configuration and monitoring"

        # Internal container relationships
        pytorchController -> jobController "Inherits shared lifecycle logic"
        tfController -> jobController "Inherits shared lifecycle logic"
        mpiController -> jobController "Inherits shared lifecycle logic"
        xgboostController -> jobController "Inherits shared lifecycle logic"
        paddleController -> jobController "Inherits shared lifecycle logic"
        jaxController -> jobController "Inherits shared lifecycle logic"
        certController -> webhookServer "Provides auto-rotated TLS certificates"

        # External interactions
        trainingOperator -> kubernetes "CRUD for Pods, Services, ConfigMaps, CRDs, HPA, RBAC, NetworkPolicies" "HTTPS/443, SA token"
        kubernetes -> trainingOperator "Webhook validation callbacks on job CREATE/UPDATE" "HTTPS/9443, TLS self-signed"
        trainingOperator -> volcanoScheduler "Create/update/delete PodGroups for gang scheduling" "HTTPS/443, SA token"
        trainingOperator -> schedulerPlugins "Create/update/delete PodGroups for gang scheduling" "HTTPS/443, SA token"
        kueue -> trainingOperator "Jobs with managedBy field are skipped" "CRD field"
        openshiftMonitoring -> trainingOperator "Scrapes /metrics endpoint" "HTTP/8080, PodMonitor"
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
            element "Internal RHOAI" {
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

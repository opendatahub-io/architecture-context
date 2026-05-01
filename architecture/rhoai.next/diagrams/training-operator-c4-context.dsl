workspace {
    model {
        dataScientist = person "Data Scientist" "Creates distributed training jobs across ML frameworks"
        mlEngineer = person "ML Engineer" "Manages training infrastructure and job configurations"

        trainingOperator = softwareSystem "Kubeflow Training Operator (KFTO)" "Kubernetes operator managing distributed training jobs across 6 ML frameworks (PyTorch, TensorFlow, MPI, XGBoost, PaddlePaddle, JAX)" {
            jobController = container "JobController Base" "Shared controller logic: pod lifecycle, service management, status tracking, gang scheduling, expectation-based consistency" "Go (controller-runtime)"
            pytorchController = container "PyTorchJob Controller" "Reconciles PyTorchJob CRs; elastic training, HPA, init containers, NetworkPolicy creation" "Go Controller"
            tfController = container "TFJob Controller" "Reconciles TFJob CRs; supports PS and all-reduce topologies, dynamic workers" "Go Controller"
            mpiController = container "MPIJob Controller" "Reconciles MPIJob CRs; asymmetric launcher/worker pattern, ConfigMaps, per-job RBAC" "Go Controller"
            xgboostController = container "XGBoostJob Controller" "Reconciles XGBoostJob CRs; master/worker topology, LightGBM compatible" "Go Controller"
            paddleController = container "PaddleJob Controller" "Reconciles PaddleJob CRs; collective and parameter-server modes" "Go Controller"
            jaxController = container "JAXJob Controller" "Reconciles JAXJob CRs; coordinator pattern, all-to-all communication" "Go Controller"
            webhookServer = container "Validating Webhook Server" "Validates CREATE/UPDATE for 5 job types (all except MPIJob)" "Go HTTPS Server" "9443/TCP"
            certController = container "OPA Cert Controller" "Manages TLS certificate rotation for webhook server" "Library"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics for training job counters" "HTTP Server" "8080/TCP"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource CRUD and webhook callbacks" "External"
        volcanoScheduler = softwareSystem "Volcano Scheduler" "Optional gang scheduling via PodGroups (scheduling.volcano.sh)" "External"
        schedulerPlugins = softwareSystem "Scheduler Plugins" "Optional gang scheduling via PodGroups (scheduling.x-k8s.io)" "External"
        kueue = softwareSystem "Kueue / MultiKueue" "Job queuing; jobs with managedBy field are skipped by training-operator" "External"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Prometheus metrics scraping via PodMonitor" "Internal RHOAI"

        # User interactions
        dataScientist -> trainingOperator "Creates PyTorchJob, TFJob, MPIJob, etc. via kubectl" "HTTPS/443"
        mlEngineer -> trainingOperator "Manages training configurations and monitors jobs" "HTTPS/443"

        # Internal component relationships
        jobController -> pytorchController "Base class inherited by"
        jobController -> tfController "Base class inherited by"
        jobController -> mpiController "Base class inherited by"
        jobController -> xgboostController "Base class inherited by"
        jobController -> paddleController "Base class inherited by"
        jobController -> jaxController "Base class inherited by"
        certController -> webhookServer "Rotates TLS certificates for"

        # External interactions
        trainingOperator -> kubernetesAPI "CRUD: Pods, Services, ConfigMaps, CRDs, HPA, RBAC, NetworkPolicies" "HTTPS/443"
        kubernetesAPI -> webhookServer "Webhook validation callbacks for job CREATE/UPDATE" "HTTPS/9443"
        trainingOperator -> volcanoScheduler "Creates/manages PodGroups for gang scheduling" "HTTPS/443 via K8s API"
        trainingOperator -> schedulerPlugins "Creates/manages PodGroups for gang scheduling" "HTTPS/443 via K8s API"
        kueue -> trainingOperator "Sets managedBy field; operator skips managed jobs"
        openshiftMonitoring -> metricsEndpoint "Scrapes /metrics via PodMonitor" "HTTP/8080"
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
                background #4a90e2
                color #ffffff
                shape person
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

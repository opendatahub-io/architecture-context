workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML training jobs via kubectl or platform UI"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Kubernetes operator managing lifecycle of distributed ML training jobs across 6 frameworks (PyTorch, TensorFlow, XGBoost, MPI, PaddlePaddle, JAX)" {
            commonController = container "Common JobController" "Shared reconciliation engine for pod/service lifecycle, expectation tracking, gang scheduling, status management" "Go (controller-runtime)"
            pytorchController = container "PyTorchJob Controller" "Reconciles PyTorchJob CRs, creates master/worker pods with torch.distributed env vars, supports elastic training via HPA" "Go"
            tfController = container "TFJob Controller" "Reconciles TFJob CRs, creates PS/Worker/Chief/Evaluator pods with TF_CONFIG cluster spec" "Go"
            xgboostController = container "XGBoostJob Controller" "Reconciles XGBoostJob CRs, creates master/worker pods with Rabit tracker configuration" "Go"
            mpiController = container "MPIJob Controller" "Reconciles MPIJob CRs, creates launcher/worker pods with SSH-less kubectl-exec MPI bootstrap" "Go"
            paddleController = container "PaddleJob Controller" "Reconciles PaddleJob CRs, creates master/worker pods for collective or PS-mode training" "Go"
            jaxController = container "JAXJob Controller" "Reconciles JAXJob CRs, creates worker pods with coordinator-based distributed JAX config" "Go"
            webhookServer = container "Validating Webhooks" "Validates job specs on CREATE/UPDATE for all 6 job types (DNS name, replica specs, container requirements)" "Go Webhook Server"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics for training job lifecycle" "HTTP Server"
            certController = container "Cert Controller" "In-process certificate management for webhook TLS using open-policy-agent/cert-controller" "Go Library"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Kubernetes control plane API server" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring system in openshift-monitoring namespace" "RHOAI Platform"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling system for atomic co-scheduling of training job replicas" "Optional External"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler-Plugins" "Alternative gang scheduling via PodGroup CRs" "Optional External"
        kueue = softwareSystem "Kueue MultiKueue" "Federated job dispatch controller" "Optional External"
        rhodsOperator = softwareSystem "RHODS Operator" "Platform operator that deploys training-operator via kustomize manifests" "RHOAI Platform"

        # Relationships
        user -> trainingOperator "Creates training job CRs (PyTorchJob, TFJob, etc.) via kubectl" "HTTPS/443"
        trainingOperator -> k8sApiServer "CRUD operations on Pods, Services, ConfigMaps, CRD status, PodGroups, RBAC resources" "HTTPS/443 TLS 1.2+"
        k8sApiServer -> trainingOperator "Admission webhook callbacks on job CREATE/UPDATE" "HTTPS/9443 TLS (self-signed)"
        prometheus -> trainingOperator "Scrapes metrics via PodMonitor" "HTTP/8080"
        trainingOperator -> volcano "Creates PodGroup CRs for gang scheduling" "HTTPS/443 via K8s API"
        trainingOperator -> schedulerPlugins "Creates PodGroup CRs for gang scheduling (alternative)" "HTTPS/443 via K8s API"
        kueue -> trainingOperator "Delegates job dispatch via managedBy annotation" "HTTPS/443 via K8s API"
        rhodsOperator -> trainingOperator "Deploys and manages operator lifecycle via kustomize" "Kustomize"

        # Container relationships
        pytorchController -> commonController "Uses shared reconciliation logic"
        tfController -> commonController "Uses shared reconciliation logic"
        xgboostController -> commonController "Uses shared reconciliation logic"
        mpiController -> commonController "Uses shared reconciliation logic"
        paddleController -> commonController "Uses shared reconciliation logic"
        jaxController -> commonController "Uses shared reconciliation logic"
        commonController -> k8sApiServer "Creates/manages Pods, Services, PodGroups" "HTTPS/443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "RHOAI Platform" {
                background #7ed321
                color #ffffff
            }
            element "Optional External" {
                background #cccccc
                color #333333
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

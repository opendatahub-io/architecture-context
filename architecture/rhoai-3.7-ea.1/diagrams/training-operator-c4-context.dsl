workspace "training-operator" "Kubeflow Training Operator (v1 API) in RHOAI 3.7-ea.1" {
    model {
        user = person "Data Scientist" "Submits distributed training jobs from workbenches via the Kubeflow Training SDK or oc"

        trainingOperator = softwareSystem "Kubeflow Training Operator" "Reconciles kubeflow.org/v1 PyTorchJob, TFJob, MPIJob, XGBoostJob, PaddleJob and JAXJob into Pods, headless Services and supporting resources" {
            manager = container "Manager (/manager)" "controller-runtime manager hosting all reconcilers, metrics and probes; 1 replica in opendatahub" "Go Operator"
            reconcilers = container "Job Reconcilers" "Six framework reconcilers on a shared Common JobController (pods, services, status, run-policy, gang scheduling)" "Go Controllers"
            webhook = container "Validating Webhook Server" "Validates PyTorchJob, TFJob, XGBoostJob, PaddleJob, JAXJob on CREATE/UPDATE (9443/TCP HTTPS, failurePolicy Fail)" "Go Service"
            certRotator = container "Cert Rotator" "Generates self-signed CA and serving cert, injects caBundle into VWC" "open-policy-agent/cert-controller"
            metrics = container "Metrics Endpoint" "Prometheus metrics on 8080/TCP, plain HTTP, no auth" "controller-runtime"
        }

        kubeApi = softwareSystem "Kubernetes API Server" "Cluster control plane; RBAC and admission" "External"
        openshiftConfig = softwareSystem "OpenShift Config API" "APIServer/cluster tlsSecurityProfile" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Deploys manifests/rhoai kustomize overlay" "Internal RHOAI"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus scraping via PodMonitor" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Quota and admission for kubeflow.org jobs via runPolicy.suspend" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches / Kubeflow Training SDK" "Notebook environments where users author and submit jobs" "Internal RHOAI"
        gangSchedulers = softwareSystem "Volcano / scheduler-plugins" "Optional gang scheduling via PodGroups (not configured in RHOAI)" "External"
        trainingPods = softwareSystem "Training Job Pods" "Replica Pods and headless Services in user namespaces" "Workload"
        ghcr = softwareSystem "ghcr.io kubectl-delivery image" "MPI launcher init image (mutable :latest)" "External"

        user -> workbenches "Authors training code"
        workbenches -> kubeApi "Creates job CRs" "HTTPS/6443, Bearer token"
        user -> kubeApi "Creates job CRs via oc" "HTTPS/6443, Bearer token"
        kubeApi -> webhook "AdmissionReview" "HTTPS/443->9443, TLS cluster profile"
        reconcilers -> kubeApi "Watches CRs; creates Pods, Services, HPA, NetworkPolicy, MPI RBAC, PodGroups; updates status" "HTTPS/6443, SA token"
        certRotator -> kubeApi "Updates webhook Secret, patches VWC caBundle" "HTTPS/6443, SA token"
        manager -> openshiftConfig "Reads TLS profile at startup" "HTTPS/6443, SA token"
        manager -> reconcilers "Starts after certsReady"
        manager -> webhook "Hosts"
        manager -> metrics "Hosts"
        monitoring -> metrics "Scrapes /metrics" "HTTP/8080, no auth"
        rhoaiOperator -> trainingOperator "Deploys and manages" "kustomize"
        kueue -> kubeApi "Suspends / admits kubeflow.org jobs"
        reconcilers -> gangSchedulers "Creates PodGroups (optional)" "HTTPS/6443"
        kubeApi -> trainingPods "Schedules job pods"
        trainingPods -> ghcr "Pulls kubectl-delivery init image (MPI)"
        trainingPods -> kubeApi "MPI launcher pods/exec" "HTTPS/WSS 6443, launcher SA token"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Workload" {
                background #f5a623
                color #000000
            }
        }
    }
}

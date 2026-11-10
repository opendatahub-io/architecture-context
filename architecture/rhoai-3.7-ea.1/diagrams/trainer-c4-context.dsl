workspace "Trainer (RHOAI 3.7-ea.1)" "Kubeflow Trainer v2 for RHOAI - C4 context and containers" {
    model {
        user = person "Data Scientist / ML Engineer" "Submits TrainJobs via kubectl, Kubeflow SDK or Dashboard"
        platformAdmin = person "Platform Admin" "Enables Trainer through the RHOAI DataScienceCluster"

        trainer = softwareSystem "Trainer" "Kubeflow Trainer v2: TrainJob / TrainingRuntime APIs for distributed training and fine-tuning, plus RHOAI module operator" {
            operator = container "trainer-operator" "Reconciles Trainer CR; gates on JobSet Operator; renders and SSA-applies operand manifests, curated ClusterTrainingRuntimes, ImageStreams; propagates TLS profile" "Go, controller-runtime, odh-platform-utilities"
            controller = container "kubeflow-trainer-controller-manager" "Reconciles TrainJob, TrainingRuntime, ClusterTrainingRuntime into JobSets, Secrets, Services, PodGroups, NetworkPolicies; RHAI progression tracking" "Go, controller-runtime"
            webhook = container "Admission Webhooks" "Mutate/validate TrainJob, TrainingRuntime, ClusterTrainingRuntime, OptimizationJob (9443/TCP)" "Go, in controller-manager"
            certController = container "cert-controller rotator" "Self-signed CA and serving cert in kubeflow-trainer-webhook-cert" "Go"
            statusServer = container "Status Server" "Receives TrainJob status from training pods (10443/TCP, gated TrainJobStatus, off)" "Go HTTPS"
            optJob = container "OptimizationJob controller" "Hyperparameter tuning over trial TrainJobs (gated, off)" "Go"
            runtimes = container "Curated ClusterTrainingRuntimes" "torch-distributed (CUDA/ROCm/CPU), training-hub, openmpi, speculator-model-opt, vllm-extract" "Kustomize"
            imagestreams = container "Training-hub ImageStreams" "Universal training workbench images" "OpenShift ImageStream"
        }

        k8s = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        rhods = softwareSystem "rhods-operator" "RHOAI platform operator" "Internal RHOAI"
        jobsetOperator = softwareSystem "OpenShift JobSet Operator" "Supplies jobset.x-k8s.io CRDs and controller" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Quota and queueing of JobSet workloads" "Internal RHOAI"
        scheduler = softwareSystem "CoScheduling / Volcano" "Optional gang scheduling via PodGroups" "External"
        prometheus = softwareSystem "OpenShift Monitoring" "Prometheus scraping" "External"
        trainingPods = softwareSystem "Training Pods" "Distributed training workloads in tenant namespaces" "Workload"
        optuna = softwareSystem "Optuna Suggestion Service" "Deployed per OptimizationJob (gated)" "Workload"
        sdk = softwareSystem "Kubeflow SDK / Dashboard" "Client tooling for TrainJobs and workbench images" "Internal RHOAI"
        trainingImages = softwareSystem "Universal Training Images" "training-hub CUDA/ROCm/CPU images" "Internal RHOAI"

        platformAdmin -> rhods "Enables Trainer component"
        rhods -> operator "Creates Trainer CR default-trainer and odh-trainer-config; injects APPLICATIONS_NAMESPACE, RELATED_IMAGE_*" "Kubernetes API"
        user -> sdk "Uses"
        sdk -> k8s "Creates TrainJobs" "HTTPS/6443"
        user -> k8s "Creates TrainJobs / TrainingRuntimes" "HTTPS/6443"

        operator -> k8s "SSA-applies CRDs, RBAC, Deployment, webhooks, runtimes, ImageStreams" "HTTPS/6443"
        operator -> jobsetOperator "Checks OLM subscription, JobSetOperator/cluster health, JobSet CRD" "Kubernetes API"
        operator -> controller "Deploys and configures (TLS profile)"
        operator -> runtimes "Applies"
        operator -> imagestreams "Applies (OpenShift only)"

        k8s -> webhook "Admission review" "HTTPS 443 to 9443"
        certController -> webhook "Provides serving cert"
        controller -> k8s "Creates JobSets, Secrets, Services, PodGroups, NetworkPolicies" "HTTPS/6443"
        controller -> trainingPods "Polls /metrics for progression" "HTTP/28080 (plaintext)"
        trainingPods -> statusServer "POST status (gated)" "HTTPS/10443"
        optJob -> optuna "GetSuggestions (gated)" "gRPC/6789 (insecure)"
        jobsetOperator -> trainingPods "Creates Jobs/Pods from JobSet"
        kueue -> trainingPods "Admits workloads"
        controller -> scheduler "Creates PodGroups (optional)" "Kubernetes API"
        prometheus -> controller "Scrapes /metrics" "HTTPS/8443"
        prometheus -> operator "Scrapes /metrics" "HTTPS/8443"
        runtimes -> trainingImages "References images"
        imagestreams -> trainingImages "References images"
    }

    views {
        systemContext trainer "SystemContext" {
            include *
            autoLayout
        }

        container trainer "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6aa8ec
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

workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits distributed training jobs via kubectl, SDK, or ODH Dashboard"

        trainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native operator for orchestrating distributed ML training jobs across PyTorch, MPI, DeepSpeed, and TorchTune" {
            controller = container "trainer-controller-manager" "Manages TrainJob, TrainingRuntime, and ClusterTrainingRuntime CRDs; reconciles into JobSets, PodGroups, Secrets, ConfigMaps, NetworkPolicies" "Go Operator (controller-runtime)"
            torchPlugin = container "Torch Plugin" "Configures PyTorch torchrun/torchtune distributed env vars, rendezvous, container ports" "Runtime Plugin"
            mpiPlugin = container "MPI Plugin" "Manages SSH key generation, hostfile generation, OpenMPI environment" "Runtime Plugin"
            coschedulingPlugin = container "Coscheduling Plugin" "Creates PodGroup CRs for gang-scheduling via scheduler-plugins" "Runtime Plugin"
            volcanoPlugin = container "Volcano Plugin" "Creates PodGroup CRs for gang-scheduling via Volcano" "Runtime Plugin"
            jobsetPlugin = container "JobSet Plugin" "Builds and reconciles JobSet resources, tracks status back to TrainJob" "Runtime Plugin"
            webhookServer = container "Webhook Server" "Validates TrainJob, TrainingRuntime, ClusterTrainingRuntime on create/update" "Validating Webhooks (9443/TCP)"
            rhaiProgression = container "RHAI Progression Tracking" "Polls training pod metrics via HTTP, stores progress in TrainJob annotations" "RHOAI Feature Module"
            rhaiNetPolicy = container "RHAI NetworkPolicy" "Creates per-TrainJob NetworkPolicies for pod isolation and metrics security" "RHOAI Feature Module"
        }

        # External Dependencies
        jobset = softwareSystem "JobSet Controller" "Orchestrates training pods as replicated jobs (sigs.k8s.io/jobset v0.10.1)" "External Dependency"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Co-scheduling via PodGroup CRs (v0.34.1-devel)" "External Dependency"
        volcano = softwareSystem "Volcano" "Alternative gang-scheduling backend (v1.13.1)" "External Dependency"
        certController = softwareSystem "cert-controller" "Manages webhook TLS certificates - self-signed CA, auto-rotation (OPA v0.14.0)" "External Dependency"
        k8sApi = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane" "Infrastructure"

        # Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys Trainer manifests from manifests/rhoai/" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection via PodMonitor scraping controller :8443/metrics" "Internal RHOAI"
        imageStreamAPI = softwareSystem "OpenShift ImageStream API" "RHOAI overlay creates ImageStreams for training hub workbench images" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "MultiKueue delegation for managed training jobs" "Internal RHOAI"

        # Relationships - User
        user -> trainer "Creates TrainJob CRs via kubectl/SDK" "HTTPS/443"

        # Relationships - Controller outbound
        trainer -> k8sApi "CRUD on CRDs, JobSets, PodGroups, Secrets, ConfigMaps, NetworkPolicies, Events" "HTTPS/443 TLS 1.2+ SA Token"
        trainer -> jobset "Creates JobSet CRs for workload orchestration" "via K8s API HTTPS/443"
        trainer -> schedulerPlugins "Creates PodGroup CRs for co-scheduling" "via K8s API HTTPS/443"
        trainer -> volcano "Creates PodGroup CRs for gang-scheduling" "via K8s API HTTPS/443"

        # Relationships - Internal integrations
        certController -> trainer "Manages webhook TLS certificate lifecycle" "Library integration"
        rhodsOperator -> trainer "Deploys manifests via kustomize" "Manifest consumption"
        prometheus -> trainer "Scrapes controller metrics" "HTTPS/8443 TLS"
        trainer -> imageStreamAPI "Creates ImageStreams for training hub images" "via K8s API HTTPS/443"
        kueue -> trainer "Delegates TrainJobs with managedBy annotation" "CRD field delegation"

        # Relationships - Internal container
        controller -> webhookServer "Validates CRs" "HTTPS/9443 TLS"
        controller -> torchPlugin "Configures PyTorch distributed training" "In-process"
        controller -> mpiPlugin "Configures MPI training" "In-process"
        controller -> coschedulingPlugin "Creates PodGroups" "In-process"
        controller -> volcanoPlugin "Creates Volcano PodGroups" "In-process"
        controller -> jobsetPlugin "Creates and reconciles JobSets" "In-process"
        controller -> rhaiProgression "Polls training pod metrics" "HTTP/28080 plaintext"
        controller -> rhaiNetPolicy "Creates per-TrainJob NetworkPolicies" "In-process"
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
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime Plugin" {
                background #6bb5e0
                color #ffffff
            }
            element "RHOAI Feature Module" {
                background #e8a838
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}

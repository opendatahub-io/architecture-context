workspace {
    model {
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform deployment and configuration"
        dataScienceUser = person "Data Science User" "Uses RHOAI components for ML/AI workloads"

        rhoaiOperator = softwareSystem "RHOAI Operator" "Primary operator for Red Hat OpenShift AI that manages lifecycle of data science platform components" {
            dscController = container "DataScienceCluster Controller" "Reconciles DataScienceCluster CRD to deploy and manage AI/ML components" "Go Controller"
            dsciController = container "DSCInitialization Controller" "Initializes platform infrastructure (namespaces, service mesh, monitoring)" "Go Controller"
            secretGenController = container "SecretGenerator Controller" "Generates OAuth secrets and credentials for component authentication" "Go Controller"
            metricsService = container "Metrics Service" "Exposes Prometheus metrics for operator health" "HTTP Service"
            healthProbes = container "Health Probes" "Kubernetes liveness and readiness probes" "HTTP Endpoints"
        }

        kubernetes = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform with Routes, OAuth, ImageStreams" "External"
        prometheus = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "External"
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Service mesh for component networking (Istio-based)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning (optional)" "External"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for data science project and workbench management" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Single-model serving infrastructure with service mesh integration" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving infrastructure for high-scale inference" "Internal RHOAI"
        pipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflow orchestration" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare" "Distributed computing stack for Ray workloads" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed Python computing framework" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments with multiple image options" "Internal RHOAI"

        gitRepo = softwareSystem "Git Repository" "Optional custom manifests repository" "External"
        containerRegistry = softwareSystem "Container Registries" "Image storage (quay.io, registry.redhat.io)" "External"

        // Relationships
        platformAdmin -> rhoaiOperator "Creates DataScienceCluster and DSCInitialization CRDs via kubectl"
        dataScienceUser -> dashboard "Accesses data science workspace UI"
        dataScienceUser -> workbenches "Uses Jupyter notebooks"
        dataScienceUser -> kserve "Deploys inference services"
        dataScienceUser -> pipelines "Runs ML workflows"

        rhoaiOperator -> kubernetes "Manages resources via Kubernetes API" "HTTPS/6443"
        rhoaiOperator -> dashboard "Deploys and manages" "Manifest deployment"
        rhoaiOperator -> kserve "Deploys and manages" "Manifest deployment"
        rhoaiOperator -> modelMesh "Deploys and manages" "Manifest deployment"
        rhoaiOperator -> pipelines "Deploys and manages" "Manifest deployment"
        rhoaiOperator -> codeflare "Deploys and manages" "Manifest deployment"
        rhoaiOperator -> ray "Deploys and manages" "Manifest deployment"
        rhoaiOperator -> workbenches "Deploys and manages" "Manifest deployment"

        dscController -> kubernetes "Creates component resources" "HTTPS/6443"
        dsciController -> kubernetes "Creates namespaces and infrastructure" "HTTPS/6443"
        secretGenController -> kubernetes "Generates secrets and OAuth clients" "HTTPS/6443"

        rhoaiOperator -> prometheus "Exposes metrics" "HTTPS/8443"
        rhoaiOperator -> serviceMesh "Configures service mesh for KServe" "API/6443"
        rhoaiOperator -> certManager "Uses for TLS certificates (optional)" "API/6443"
        rhoaiOperator -> gitRepo "Fetches custom manifests (optional)" "HTTPS/443"
        rhoaiOperator -> containerRegistry "Pulls component images" "HTTPS/443"

        prometheus -> metricsService "Scrapes metrics" "HTTPS/8443"
        kubernetes -> healthProbes "Health checks" "HTTP/8081"
    }

    views {
        systemContext rhoaiOperator "SystemContext" {
            include *
            autoLayout
        }

        container rhoaiOperator "Containers" {
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
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

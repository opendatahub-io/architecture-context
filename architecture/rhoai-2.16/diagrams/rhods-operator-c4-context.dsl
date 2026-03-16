workspace {
    model {
        user = person "Platform Administrator" "Manages RHOAI platform and components"
        datascientist = person "Data Scientist" "Uses RHOAI components for ML workloads"

        rhodsOperator = softwareSystem "RHODS Operator" "Primary operator for RHOAI that manages the lifecycle of data science components through DataScienceCluster and DSCInitialization custom resources" {
            dscController = container "DataScienceCluster Controller" "Reconciles DataScienceCluster CRs to deploy and manage data science components" "Go Operator"
            dsciController = container "DSCInitialization Controller" "Initializes platform resources including service mesh, monitoring, and trusted CA bundles" "Go Operator"
            webhookServer = container "Webhook Server" "Validates and mutates DataScienceCluster and DSCInitialization resources" "Go Service"
            componentReconcilers = container "Component Reconcilers" "Individual reconcilers for Dashboard, Workbenches, Pipelines, KServe, ModelMesh, etc." "Go"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Container orchestration platform API" "External"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Service mesh for traffic management and mTLS" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"
        authorino = softwareSystem "Authorino" "Authorization service for model serving" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External (Optional)"
        olm = softwareSystem "Operator Lifecycle Manager" "Operator installation and lifecycle management" "External"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for data science platform" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches (Notebooks)" "Jupyter notebook environments" "Internal RHOAI"
        pipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflows" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare" "Distributed workload orchestration" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "Model explainability and bias detection" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and versioning" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing system" "Internal RHOAI"
        trainingOperator = softwareSystem "Training Operator" "Distributed training frameworks (TFJob, PyTorchJob)" "Internal RHOAI"

        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "Internal RHOAI"
        gitRepos = softwareSystem "Component Git Repositories" "Source repositories for component manifests" "External"
        containerRegistries = softwareSystem "Container Registries" "quay.io, registry.redhat.io" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "Authentication service" "External"

        user -> rhodsOperator "Creates and manages DataScienceCluster and DSCInitialization CRs via kubectl/console"
        datascientist -> dashboard "Uses web UI for ML workflows"
        datascientist -> workbenches "Creates and manages notebook environments"
        datascientist -> kserve "Deploys and serves ML models"

        rhodsOperator -> k8sAPI "Manages cluster resources (CRD reconciliation, resource creation)" "HTTPS/6443, TLS 1.2+, Bearer Token"
        rhodsOperator -> serviceMesh "Configures service mesh for KServe" "HTTPS/6443, TLS 1.2+, Bearer Token"
        rhodsOperator -> knative "Configures serverless infrastructure" "HTTPS/6443, TLS 1.2+, Bearer Token"
        rhodsOperator -> authorino "Configures authentication for model serving" "HTTPS/6443, TLS 1.2+, Bearer Token"
        rhodsOperator -> olm "Installed and managed by OLM" "HTTPS/6443, TLS 1.2+, Bearer Token"

        rhodsOperator -> dashboard "Deploys and manages" "CRD-driven deployment"
        rhodsOperator -> workbenches "Deploys and manages" "CRD-driven deployment"
        rhodsOperator -> pipelines "Deploys and manages" "CRD-driven deployment"
        rhodsOperator -> kserve "Deploys and manages" "CRD-driven deployment"
        rhodsOperator -> modelmesh "Deploys and manages" "CRD-driven deployment"
        rhodsOperator -> codeflare "Deploys and manages" "CRD-driven deployment"
        rhodsOperator -> ray "Deploys and manages" "CRD-driven deployment"
        rhodsOperator -> trustyai "Deploys and manages" "CRD-driven deployment"
        rhodsOperator -> modelRegistry "Deploys and manages" "CRD-driven deployment"
        rhodsOperator -> kueue "Deploys and manages" "CRD-driven deployment"
        rhodsOperator -> trainingOperator "Deploys and manages" "CRD-driven deployment"
        rhodsOperator -> prometheus "Deploys and configures monitoring" "CRD-driven deployment"

        rhodsOperator -> gitRepos "Fetches component manifests (optional via devFlags)" "HTTPS/443, TLS 1.2+"
        rhodsOperator -> containerRegistries "Pulls container images" "HTTPS/443, TLS 1.2+, Pull Secret"
        prometheus -> rhodsOperator "Scrapes operator metrics" "HTTPS/8443, TLS 1.2+, Bearer Token"
        prometheus -> oauthServer "Authenticates users for Prometheus UI" "HTTPS/443, OAuth2"

        kserve -> serviceMesh "Uses for traffic routing and mTLS" "Integration"
        kserve -> knative "Uses for autoscaling" "Integration"
        kserve -> authorino "Uses for authentication" "Integration"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout
        }

        container rhodsOperator "Containers" {
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
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}

workspace {
    model {
        # People
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform deployment and configuration"
        dataScientist = person "Data Scientist" "Uses RHOAI components for ML workflows"

        # Software Systems
        rhodsOperator = softwareSystem "RHODS Operator" "Primary operator for Red Hat OpenShift AI that manages data science component lifecycle" {
            dscController = container "DataScienceCluster Controller" "Reconciles DataScienceCluster CR to deploy components" "Go Controller"
            dsciController = container "DSCInitialization Controller" "Initializes platform infrastructure" "Go Controller"
            secretGenerator = container "SecretGenerator Controller" "Generates component secrets" "Go Controller"
            certGenerator = container "CertConfigmapGenerator Controller" "Generates certificate ConfigMaps" "Go Controller"
            upgradeManager = container "Upgrade Manager" "Handles legacy KfDef migration" "Go Module"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "OpenShift/Kubernetes control plane" "External"
        serviceMesh = softwareSystem "Service Mesh Operator" "Istio/Maistra service mesh for component networking" "External"
        knative = softwareSystem "Serverless Operator" "Knative Serving for serverless workloads" "External"
        authorino = softwareSystem "Authorino Operator" "API authorization for KServe" "External"
        prometheus = softwareSystem "Prometheus" "Cluster monitoring and metrics collection" "External"

        # Internal ODH Components
        dashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI" "Internal ODH"
        workbenches = softwareSystem "Workbenches" "Jupyter notebooks and IDEs" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (Tekton/Argo)" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving with Knative" "Internal ODH"
        modelmesh = softwareSystem "ModelMesh Serving" "Alternative model serving (Seldon)" "Internal ODH"
        codeflare = softwareSystem "CodeFlare" "Distributed workload management" "Internal ODH"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal ODH"
        kueue = softwareSystem "Kueue" "Job queueing system" "Internal ODH"

        # External services
        gitRepos = softwareSystem "Component Git Repositories" "Upstream manifest repositories" "External"
        containerRegistries = softwareSystem "Container Registries" "Image storage (registry.redhat.io, quay.io)" "External"

        # Relationships - User interactions
        platformAdmin -> rhodsOperator "Creates/updates DataScienceCluster and DSCInitialization CRs via kubectl"
        dataScientist -> dashboard "Accesses ML workbench UI"
        dataScientist -> workbenches "Develops models in notebooks"
        dataScientist -> kserve "Deploys inference services"

        # Relationships - Operator dependencies
        rhodsOperator -> k8sAPI "CRUD operations on cluster resources" "HTTPS/6443, ServiceAccount Token"
        rhodsOperator -> serviceMesh "Creates ServiceMeshMember resources" "Kubernetes API"
        rhodsOperator -> prometheus "Exposes metrics" "HTTP/8080"

        # Relationships - Operator to components (deployment)
        dscController -> dashboard "Deploys manifests" "Kubernetes API"
        dscController -> workbenches "Deploys manifests" "Kubernetes API"
        dscController -> pipelines "Deploys manifests" "Kubernetes API"
        dscController -> kserve "Deploys manifests" "Kubernetes API"
        dscController -> modelmesh "Deploys manifests" "Kubernetes API"
        dscController -> codeflare "Deploys manifests" "Kubernetes API"
        dscController -> ray "Deploys manifests" "Kubernetes API"
        dscController -> kueue "Deploys manifests" "Kubernetes API"

        # Relationships - Infrastructure setup
        dsciController -> serviceMesh "Configures service mesh integration" "Kubernetes API"
        dsciController -> knative "Integrates serverless platform" "Kubernetes API"
        dsciController -> authorino "Integrates authorization" "Kubernetes API"
        dsciController -> prometheus "Configures monitoring" "Kubernetes API"

        # Relationships - External services
        rhodsOperator -> gitRepos "Fetches component manifests at build time" "HTTPS/443"
        rhodsOperator -> containerRegistries "Pulls component images" "HTTPS/443, Pull Secrets"

        # Component dependencies
        kserve -> serviceMesh "Requires for traffic routing" "mTLS"
        kserve -> knative "Requires for autoscaling" "Kubernetes API"
        kserve -> authorino "Requires for authorization" "gRPC"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
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
    }
}

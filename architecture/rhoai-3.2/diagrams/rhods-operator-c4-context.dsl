workspace {
    model {
        # Actors
        dataScientist = person "Data Scientist" "Uses RHOAI platform for ML/AI workloads"
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform deployment and configuration"
        sre = person "SRE/Operations" "Monitors and maintains platform health"

        # Main System
        rhodsOperator = softwareSystem "RHOAI Operator" "Platform operator that manages the lifecycle of Red Hat OpenShift AI components and infrastructure" {
            dscController = container "DSC Controller" "Reconciles DataScienceCluster resources and manages component lifecycle" "Go Operator Controller"
            dsciController = container "DSCI Controller" "Initializes platform infrastructure (monitoring, service mesh, trusted CA)" "Go Operator Controller"
            webhookServer = container "Webhook Server" "Validates and mutates DSC and DSCI resources" "HTTPS/TLS 1.2+"
            manifestDeployer = container "Manifest Deployer" "Applies kustomize manifests from /opt/manifests to cluster" "Kustomize Engine"
            componentControllers = container "Component Controllers" "Individual controllers for dashboard, kserve, workbenches, pipelines, model registry, etc." "Go Reconcilers"
            serviceControllers = container "Service Controllers" "Manage auth, monitoring, and gateway services" "Go Reconcilers"
            monitoringStack = container "Monitoring Stack" "Prometheus, Alertmanager, and metrics collection" "Prometheus Operator"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform (1.28+ / 4.14+)" "External Platform"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager for dependency management" "External"
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Istio-based service mesh for model serving (optional)" "External Optional"
        serverless = softwareSystem "OpenShift Serverless" "Knative serving for KServe autoscaling (optional)" "External Optional"
        certManager = softwareSystem "cert-manager" "Certificate management (optional, uses service-ca by default)" "External Optional"
        imageRegistry = softwareSystem "Image Registries" "Container image storage (registry.redhat.io, quay.io)" "External"

        # Internal ODH/RHOAI Components (deployed by operator)
        odhDashboard = softwareSystem "ODH Dashboard" "Web console and UI for data science platform" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving infrastructure with serverless autoscaling" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "Kubeflow/Tekton-based pipeline orchestration" "Internal ODH"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments for data scientists" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model versioning and metadata management" "Internal ODH"
        ray = softwareSystem "Ray" "Distributed computing for ML workloads" "Internal ODH"
        trainingOperator = softwareSystem "Training Operator" "Distributed training (TFJob, PyTorchJob, etc.)" "Internal ODH"
        trustyai = softwareSystem "TrustyAI" "Model explainability and fairness" "Internal ODH"

        # Interactions - Users
        platformAdmin -> rhodsOperator "Deploys and configures via DataScienceCluster CR" "kubectl/GitOps"
        dataScientist -> odhDashboard "Creates workbenches and deploys models" "HTTPS/UI"
        sre -> monitoringStack "Views metrics and alerts" "HTTPS/Prometheus UI"

        # Interactions - Operator to Core Platform
        rhodsOperator -> kubernetes "Manages resources (Deployments, Services, CRDs, RBAC)" "HTTPS/6443 API calls"
        rhodsOperator -> olm "Manages component subscriptions and CSVs" "HTTPS/443"
        rhodsOperator -> imageRegistry "Pulls container images for components" "HTTPS/443"

        # Interactions - Operator to Optional Dependencies
        rhodsOperator -> serviceMesh "Enrolls components in service mesh" "ServiceMeshMember CRD"
        rhodsOperator -> serverless "Configures serverless for KServe" "KnativeServing CRD"
        rhodsOperator -> certManager "Provisions certificates (if enabled)" "Certificate CRD"

        # Interactions - Operator to Deployed Components
        dscController -> componentControllers "Creates component CRs" "Internal"
        componentControllers -> manifestDeployer "Loads and applies manifests" "Internal"
        manifestDeployer -> kubernetes "Applies kustomize manifests" "HTTPS/6443"
        dsciController -> serviceControllers "Initializes platform services" "Internal"

        # Deployed components
        rhodsOperator -> odhDashboard "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> kserve "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> pipelines "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> workbenches "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> modelRegistry "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> ray "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> trainingOperator "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> trustyai "Deploys and manages" "Kustomize manifests"

        # Component dependencies
        kserve -> serviceMesh "Uses for traffic routing and mTLS" "Service mesh sidecar"
        kserve -> serverless "Uses for autoscaling" "Knative integration"
        odhDashboard -> kubernetes "Manages user workspaces" "K8s API"
        pipelines -> workbenches "Integrates with notebooks" "API calls"

        # Monitoring
        monitoringStack -> rhodsOperator "Scrapes metrics" "HTTPS/8443 ServiceMonitor"
        monitoringStack -> odhDashboard "Scrapes metrics" "ServiceMonitor"
        monitoringStack -> kserve "Scrapes metrics" "ServiceMonitor"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout lr
            title "RHOAI Operator - System Context"
            description "System context showing RHOAI Operator and its relationships with users, external dependencies, and deployed components"
        }

        container rhodsOperator "Containers" {
            include *
            autoLayout tb
            title "RHOAI Operator - Container View"
            description "Internal container structure of RHOAI Operator showing controllers and services"
        }

        dynamic rhodsOperator "DeploymentFlow" "Platform administrator deploys DataScienceCluster" {
            platformAdmin -> rhodsOperator "1. Creates DataScienceCluster CR"
            rhodsOperator -> kubernetes "2. Validates via webhook"
            dscController -> componentControllers "3. Creates component CRs"
            componentControllers -> manifestDeployer "4. Loads manifests"
            manifestDeployer -> kubernetes "5. Applies manifests"
            kubernetes -> odhDashboard "6. Creates Dashboard deployment"
            kubernetes -> kserve "7. Creates KServe deployment"
            kubernetes -> workbenches "8. Creates Workbenches deployment"
            autoLayout lr
            title "DataScienceCluster Deployment Flow"
        }

        styles {
            element "Software System" {
                background #1168bd
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
            element "External Platform" {
                background #999999
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

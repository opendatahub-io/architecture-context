workspace {
    model {
        admin = person "Admin/Platform Engineer" "Manages RHOAI platform and components"
        dataScientist = person "Data Scientist" "Uses RHOAI components for ML workloads"

        rhodsOperator = softwareSystem "RHODS Operator" "Primary operator for Red Hat OpenShift AI that manages data science platform components and infrastructure" {
            mainController = container "Main Controller" "Manages DataScienceCluster and DSCInitialization resources" "Go Operator" {
                dscController = component "DSC Controller" "Reconciles DataScienceCluster CR" "Go Controller"
                dsciController = component "DSCI Controller" "Reconciles DSCInitialization CR" "Go Controller"
                webhookServer = component "Webhook Server" "Validates and mutates DSC/DSCI resources" "Go HTTP Server"
            }

            componentControllers = container "Component Controllers" "Manages individual data science components (12 controllers)" "Go Operators" {
                dashboardCtrl = component "Dashboard Controller" "Deploys ODH Dashboard" "Go Controller"
                kserveCtrl = component "KServe Controller" "Deploys KServe operator" "Go Controller"
                modelmeshCtrl = component "ModelMesh Controller" "Deploys ModelMesh serving" "Go Controller"
                dspCtrl = component "DSP Controller" "Deploys Data Science Pipelines" "Go Controller"
            }

            serviceControllers = container "Service Controllers" "Manages platform services (Auth, Monitoring)" "Go Operators" {
                authCtrl = component "Auth Controller" "Configures authentication" "Go Controller"
                monitoringCtrl = component "Monitoring Controller" "Deploys monitoring stack" "Go Controller"
            }

            utilityControllers = container "Utility Controllers" "Secret generation and setup tasks" "Go Operators"
        }

        k8s = softwareSystem "Kubernetes API Server" "Container orchestration platform API" "Platform"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes distribution" "Platform"

        serviceMesh = softwareSystem "Service Mesh Operator (Istio)" "Service mesh for traffic management and mTLS" "External Dependency"
        serverless = softwareSystem "Serverless Operator (Knative)" "Serverless autoscaling platform" "External Dependency"
        authorino = softwareSystem "Authorino Operator" "Authorization service for KServe" "External Dependency"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI platform" "Internal Component"
        kserve = softwareSystem "KServe" "Model serving platform" "Internal Component"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving infrastructure" "Internal Component"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal Component"
        workbenches = softwareSystem "Jupyter Workbenches" "Interactive notebook environment" "Internal Component"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal Component"
        codeflare = softwareSystem "CodeFlare" "Distributed workload management" "Internal Component"
        trustyai = softwareSystem "TrustyAI" "Model explainability and fairness" "Internal Component"
        trainingOperator = softwareSystem "Training Operator" "Distributed model training" "Internal Component"
        kueue = softwareSystem "Kueue" "Job queueing and resource management" "Internal Component"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and versioning" "Internal Component"

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Monitoring"
        alertmanager = softwareSystem "Alertmanager" "Alert routing and management" "Monitoring"

        github = softwareSystem "GitHub API" "Component manifest source repository" "External Service"

        # Relationships - Admin interactions
        admin -> rhodsOperator "Creates DataScienceCluster and DSCInitialization CRs via kubectl"
        admin -> prometheus "Views platform metrics and health"
        admin -> alertmanager "Manages alerts"

        # Relationships - Data Scientist interactions
        dataScientist -> dashboard "Accesses RHOAI UI"
        dataScientist -> workbenches "Creates and uses notebooks"
        dataScientist -> kserve "Deploys inference services"
        dataScientist -> dsp "Runs ML pipelines"

        # Relationships - RHODS Operator core
        rhodsOperator -> k8s "Manages cluster resources (CRUD operations)" "HTTPS/6443"
        rhodsOperator -> openshift "Deploys routes and uses OpenShift features" "HTTPS/6443"
        k8s -> rhodsOperator "Calls webhooks for validation/mutation" "HTTPS/9443"

        # Relationships - Component deployment
        rhodsOperator -> dashboard "Deploys and configures" "Kubernetes API"
        rhodsOperator -> kserve "Deploys and configures" "Kubernetes API"
        rhodsOperator -> modelMesh "Deploys and configures" "Kubernetes API"
        rhodsOperator -> dsp "Deploys and configures" "Kubernetes API"
        rhodsOperator -> workbenches "Deploys and configures" "Kubernetes API"
        rhodsOperator -> ray "Deploys and configures" "Kubernetes API"
        rhodsOperator -> codeflare "Deploys and configures" "Kubernetes API"
        rhodsOperator -> trustyai "Deploys and configures" "Kubernetes API"
        rhodsOperator -> trainingOperator "Deploys and configures" "Kubernetes API"
        rhodsOperator -> kueue "Deploys and configures" "Kubernetes API"
        rhodsOperator -> modelRegistry "Deploys and configures" "Kubernetes API"

        # Relationships - Monitoring
        rhodsOperator -> prometheus "Deploys and configures" "Kubernetes API"
        rhodsOperator -> alertmanager "Deploys and configures" "Kubernetes API"
        prometheus -> rhodsOperator "Scrapes metrics" "HTTP/8080"
        prometheus -> dashboard "Scrapes metrics" "Various"
        prometheus -> kserve "Scrapes metrics" "Various"

        # Relationships - External dependencies
        rhodsOperator -> serviceMesh "Requires for KServe and auth" "Kubernetes API"
        rhodsOperator -> serverless "Requires for KServe" "Kubernetes API"
        rhodsOperator -> authorino "Requires for KServe auth" "Kubernetes API"
        rhodsOperator -> github "Fetches component manifests (devFlags)" "HTTPS/443"

        kserve -> serviceMesh "Uses for traffic routing"
        kserve -> serverless "Uses for autoscaling"

        # Component interactions
        dashboard -> kserve "Manages via UI"
        dashboard -> dsp "Manages via UI"
        dashboard -> workbenches "Manages via UI"
        dsp -> kserve "Deploys models from pipelines"
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

        component mainController "MainControllerComponents" {
            include *
            autoLayout
        }

        component componentControllers "ComponentControllers" {
            include *
            autoLayout
        }

        styles {
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "External Dependency" {
                background #e0e0e0
                color #000000
            }
            element "Internal Component" {
                background #7ed321
                color #000000
            }
            element "Monitoring" {
                background #f5a623
                color #000000
            }
            element "External Service" {
                background #cccccc
                color #000000
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
            element "Component" {
                shape Component
            }
        }

        theme default
    }
}

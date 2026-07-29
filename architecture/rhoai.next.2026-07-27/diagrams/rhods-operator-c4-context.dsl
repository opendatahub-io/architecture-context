workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Manages the RHOAI platform via DataScienceCluster and DSCInitialization CRs"
        dataScienceUser = person "Data Scientist" "Uses AI/ML workloads managed by RHOAI platform components"

        rhodsOperator = softwareSystem "rhods-operator" "Central lifecycle-management operator for Red Hat OpenShift AI (RHOAI), orchestrating 16 component CRDs, 3 service CRDs, 3 cloud-manager CRDs, and platform-level resources" {
            controller = container "rhods-operator Controller" "Manages DataScienceCluster, DSCInitialization, component CRDs, service CRDs, and cloud manager CRDs" "Go Operator (controller-runtime 0.24.1)"
            webhookServer = container "Webhook Server" "12 admission webhooks (validating, mutating, conversion) for resource integrity" "Go Service, Port 9443/TLS"
            metricsService = container "Metrics Service" "Exposes operator metrics" "Port 8443"
            cloudManagerCLI = container "v2 CLI" "Cobra CLI for cloud manager operations (AWS, Azure, CoreWeave)" "Go CLI"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for traffic routing" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Manages Prometheus monitoring resources" "External"
        openshiftConfig = softwareSystem "OpenShift Cluster Configuration" "Cluster-wide API server, authentication, infrastructure config" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OAuth client management" "External"
        serviceCaOperator = softwareSystem "OpenShift service-ca Operator" "Provisions and rotates TLS certificates for services" "External"

        // Managed RHOAI Components (downstream)
        dashboard = softwareSystem "Dashboard" "RHOAI web UI" "RHOAI Component"
        dsPipelines = softwareSystem "DataSciencePipelines" "ML pipeline orchestration" "RHOAI Component"
        feastOperator = softwareSystem "FeastOperator" "Feature store management" "RHOAI Component"
        kserve = softwareSystem "Kserve" "Model serving platform" "RHOAI Component"
        kueue = softwareSystem "Kueue" "Job queuing and scheduling" "RHOAI Component"
        modelRegistry = softwareSystem "ModelRegistry" "ML model metadata registry" "RHOAI Component"
        ray = softwareSystem "Ray" "Distributed computing framework" "RHOAI Component"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook workspaces" "RHOAI Component"
        trustyAI = softwareSystem "TrustyAI" "AI explainability and fairness" "RHOAI Component"
        maas = softwareSystem "ModelsAsService" "Models-as-a-Service management" "RHOAI Component"

        // Relationships
        clusterAdmin -> rhodsOperator "Creates/updates DSC and DSCI CRs via kubectl"
        dataScienceUser -> dashboard "Accesses RHOAI web UI"
        dataScienceUser -> workbenches "Uses Jupyter notebooks"
        dataScienceUser -> kserve "Deploys inference services"

        controller -> kubernetesAPI "Watches/manages resources" "HTTPS/6443, TLS 1.2+, SA Token"
        controller -> webhookServer "Delegates admission requests"
        kubernetesAPI -> webhookServer "Sends admission webhooks" "HTTPS/443→9443, TLS (service-ca)"

        controller -> gatewayAPI "Watches Gateway and HTTPRoute resources" "Kubernetes API"
        controller -> prometheusOperator "Manages monitoring resources" "Kubernetes API"
        controller -> openshiftConfig "Reads cluster configuration" "Kubernetes API"
        controller -> openshiftOAuth "Manages OAuthClient resources" "Kubernetes API"
        serviceCaOperator -> webhookServer "Provisions TLS certificate"

        // Component lifecycle management
        rhodsOperator -> dashboard "Manages lifecycle via Dashboard CR"
        rhodsOperator -> dsPipelines "Manages lifecycle via DataSciencePipelines CR"
        rhodsOperator -> feastOperator "Manages lifecycle via FeastOperator CR"
        rhodsOperator -> kserve "Manages lifecycle via Kserve CR"
        rhodsOperator -> kueue "Manages lifecycle via Kueue CR"
        rhodsOperator -> modelRegistry "Manages lifecycle via ModelRegistry CR"
        rhodsOperator -> ray "Manages lifecycle via Ray CR"
        rhodsOperator -> workbenches "Manages lifecycle via Workbenches CR"
        rhodsOperator -> trustyAI "Manages lifecycle via TrustyAI CR"
        rhodsOperator -> maas "Manages lifecycle via ModelsAsService CR"
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
            element "RHOAI Component" {
                background #7ed321
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

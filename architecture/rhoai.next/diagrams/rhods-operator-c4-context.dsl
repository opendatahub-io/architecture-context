workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, notebooks, and inference services"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration and components"

        rhodsOperator = softwareSystem "rhods-operator" "Central platform operator managing full lifecycle of RHOAI components, services, and infrastructure" {
            manager = container "Manager" "Primary operator binary managing DSC, DSCI, component CRs, service CRs, and module CRs via DAG-based provisioning" "Go Operator (controller-runtime)"
            cloudmanager = container "Cloud Manager" "Cloud cluster lifecycle management for AWS, Azure, CoreWeave" "Go CLI"
            webhookServer = container "Webhook Server" "Validates and defaults DSC, DSCI, HardwareProfile, AcceleratorProfile, Serving, Notebook CRs" "Admission Webhook"
            dsciController = container "DSCI Controller" "Platform initialization: namespaces, monitoring, auth, gateway, hardware profiles, CA bundles" "Controller"
            dscController = container "DSC Controller" "Component lifecycle management via DAG with runlevels" "Controller"
            gatewayController = container "Gateway Service Controller" "Full ingress stack: Gateway API, Envoy, kube-auth-proxy, dashboard redirects" "Controller"
            authController = container "Auth Service Controller" "RBAC management: admin/user group role bindings" "Controller"
            monitoringController = container "Monitoring Service Controller" "Prometheus, Tempo, OpenTelemetry, Perses deployment" "Controller"
            moduleController = container "Module Controller" "Helm/Kustomize deployment of out-of-tree operators" "Controller"
        }

        # Internal RHOAI Components (managed by rhods-operator)
        dashboard = softwareSystem "Dashboard" "Web UI for RHOAI platform" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model inference serving" "Internal RHOAI"
        modelController = softwareSystem "Model Controller" "NIM/WVA model serving integration" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata registry" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (Argo-based)" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Jupyter/VS Code notebook environments" "Internal RHOAI"
        trustyAI = softwareSystem "TrustyAI" "AI explainability and fairness" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal RHOAI"
        trainingOperator = softwareSystem "Training Operator" "Distributed training jobs" "Internal RHOAI"
        feastOperator = softwareSystem "Feast Operator" "Feature store" "Internal RHOAI"
        aiGateway = softwareSystem "AIGateway" "AI Gateway / Models as a Service" "Internal RHOAI Module"
        mlflow = softwareSystem "MLflow Operator" "Experiment tracking" "Internal RHOAI Module"

        # External Dependencies
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"
        istio = softwareSystem "Istio / Service Mesh" "EnvoyFilter, DestinationRule for ingress auth and TLS" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway, GatewayClass, HTTPRoute CRDs" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management (xKS)" "External"
        kueueOperator = softwareSystem "Kueue Operator" "External job queue management" "External"
        clusterObservability = softwareSystem "Cluster Observability Operator" "MonitoringStack, PrometheusRule CRDs" "External"
        tempoOperator = softwareSystem "Tempo Operator" "Trace storage backend" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Telemetry collection" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Integrated OAuth2 authentication" "External"
        openshiftIngress = softwareSystem "OpenShift Ingress" "Default ingress certificate propagation" "External"

        # Cloud providers
        aws = softwareSystem "AWS" "Managed Kubernetes (EKS)" "Cloud Provider"
        azure = softwareSystem "Azure" "Managed Kubernetes (AKS)" "Cloud Provider"
        coreweave = softwareSystem "CoreWeave" "GPU cloud provider" "Cloud Provider"

        # Relationships
        platformAdmin -> rhodsOperator "Configures platform via DSC/DSCI CRs" "kubectl/oc"
        dataScientist -> dashboard "Accesses ML platform" "HTTPS/443"
        dataScientist -> workbenches "Creates notebooks" "HTTPS/443"
        dataScientist -> kserve "Deploys inference services" "kubectl/oc"

        rhodsOperator -> k8sAPI "CRD watches, resource management" "HTTPS/6443"
        rhodsOperator -> istio "Creates EnvoyFilter, DestinationRule" "HTTPS/6443"
        rhodsOperator -> gatewayAPI "Creates Gateway, GatewayClass, HTTPRoute" "HTTPS/6443"
        rhodsOperator -> certManager "TLS certificates (xKS)" "HTTPS/6443"
        rhodsOperator -> kueueOperator "Monitors external operator, creates default queues" "HTTPS/6443"
        rhodsOperator -> clusterObservability "MonitoringStack, PrometheusRule CRDs" "HTTPS/6443"
        rhodsOperator -> tempoOperator "Trace storage backend" "HTTPS/6443"
        rhodsOperator -> otelOperator "Telemetry collection" "HTTPS/6443"
        rhodsOperator -> olm "Detects installed operators" "HTTPS/6443"
        rhodsOperator -> openshiftOAuth "Registers OAuthClient for auth" "HTTPS/443"
        rhodsOperator -> openshiftIngress "Propagates default ingress cert" "HTTPS/443"

        # Component lifecycle
        rhodsOperator -> dashboard "Manages lifecycle" "Component CR"
        rhodsOperator -> kserve "Manages lifecycle" "Component CR"
        rhodsOperator -> modelController "Manages lifecycle" "Component CR"
        rhodsOperator -> modelRegistry "Manages lifecycle" "Component CR"
        rhodsOperator -> dsPipelines "Manages lifecycle" "Component CR"
        rhodsOperator -> workbenches "Manages lifecycle" "Component CR"
        rhodsOperator -> trustyAI "Manages lifecycle" "Component CR"
        rhodsOperator -> ray "Manages lifecycle" "Component CR"
        rhodsOperator -> trainingOperator "Manages lifecycle" "Component CR"
        rhodsOperator -> feastOperator "Manages lifecycle" "Component CR"
        rhodsOperator -> aiGateway "Manages lifecycle" "Module CR (Helm)"
        rhodsOperator -> mlflow "Manages lifecycle" "Module CR (Kustomize)"

        # Cloud management
        cloudmanager -> aws "Manages EKS clusters" "AWS API"
        cloudmanager -> azure "Manages AKS clusters" "Azure API"
        cloudmanager -> coreweave "Manages GPU clusters" "CoreWeave API"
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
                color #ffffff
            }
            element "Internal RHOAI Module" {
                background #50a000
                color #ffffff
            }
            element "Cloud Provider" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

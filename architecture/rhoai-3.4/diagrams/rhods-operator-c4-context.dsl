workspace {
    model {
        admin = person "Platform Admin" "Configures RHOAI platform via DSC/DSCI CRs"
        datascientist = person "Data Scientist" "Uses RHOAI platform components (notebooks, model serving, pipelines)"

        rhodsOperator = softwareSystem "rhods-operator" "Central control plane for Red Hat OpenShift AI — orchestrates deployment, configuration, and lifecycle of all RHOAI components" {
            manager = container "manager" "Main operator binary — DSCI, DSC, 16 component controllers, 5 service controllers, webhooks" "Go Operator (controller-runtime)"
            cloudmanager = container "cloudmanager" "Cloud manager for Azure AKS and CoreWeave — deploys operator dependencies via Helm" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "14 webhooks: 7 mutating, 6 validating, 1 conversion — validates DSC/DSCI, injects connections, hardware profiles" "HTTPS/9443"
            gatewayController = container "Gateway Controller" "Deploys platform ingress: Gateway API, Envoy, EnvoyFilter, kube-auth-proxy, OpenShift Routes" "Go Controller"
            authController = container "Auth Controller" "Manages RBAC ClusterRoles, Roles, RoleBindings for admin/allowed groups" "Go Controller"
            monitoringController = container "Monitoring Controller" "Deploys observability stack: MonitoringStack, Tempo, OTel, Perses, PrometheusRules" "Go Controller"
        }

        // Internal RHOAI Components (deployed by operator)
        dashboard = softwareSystem "Dashboard" "Web UI for RHOAI" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving infrastructure" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Notebook controllers and images" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "Pipeline execution infrastructure" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model artifact registry" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI explainability and bias detection" "Internal RHOAI"
        ray = softwareSystem "KubeRay" "Ray cluster management" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload scheduling" "Internal RHOAI"
        trainingOperator = softwareSystem "Training Operator" "Distributed training jobs" "Internal RHOAI"
        trainer = softwareSystem "Trainer" "Training API (JobSet-based)" "Internal RHOAI"
        feast = softwareSystem "Feast Operator" "Feature store" "Internal RHOAI"
        llamastack = softwareSystem "LlamaStack Operator" "LlamaStack deployment" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "Experiment tracking" "Internal RHOAI"
        spark = softwareSystem "Spark Operator" "Apache Spark on Kubernetes" "Internal RHOAI"
        modelController = softwareSystem "Model Controller" "odh-model-controller" "Internal RHOAI"
        maas = softwareSystem "Models-as-a-Service" "MaaS controller" "Internal RHOAI"

        // External Platform Dependencies
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD management and SSA" "External Platform"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager" "External Platform"
        istio = softwareSystem "Istio / Sail Operator" "Service mesh for gateway and mTLS" "External Platform"
        certManager = softwareSystem "cert-manager" "Certificate management (XKS)" "External Platform"
        gatewayAPICRDs = softwareSystem "Gateway API CRDs" "Kubernetes Gateway API" "External Platform"

        // External Services
        openshiftOAuth = softwareSystem "OpenShift OAuth" "User authentication via OAuth2" "External Service"
        oidcProvider = softwareSystem "External OIDC Provider" "User authentication via OIDC" "External Service"
        serviceCA = softwareSystem "OpenShift Service CA" "Auto-generated TLS certificates" "External Service"

        // Observability Dependencies
        coo = softwareSystem "Cluster Observability Operator" "MonitoringStack, Perses, ThanosQuerier CRDs" "External Platform"
        tempoOperator = softwareSystem "Tempo Operator" "TempoMonolithic, TempoStack CRDs" "External Platform"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Instrumentation, OTelCollector CRDs" "External Platform"
        prometheusOperator = softwareSystem "Prometheus Operator" "PrometheusRule, ServiceMonitor CRDs" "External Platform"

        // Relationships
        admin -> rhodsOperator "Creates DSC/DSCI CRs via kubectl" "HTTPS/443"
        datascientist -> dashboard "Uses web UI" "HTTPS/443"
        datascientist -> kserve "Deploys inference services" "HTTPS/443"
        datascientist -> workbenches "Uses Jupyter notebooks" "HTTPS/443"

        // Operator → Component deployments
        rhodsOperator -> dashboard "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> kserve "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> workbenches "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> dsp "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> modelRegistry "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> trustyai "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> ray "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> kueue "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> trainingOperator "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> trainer "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> feast "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> llamastack "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> mlflow "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> spark "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> modelController "Deploys via kustomize manifests" "K8s API SSA"
        rhodsOperator -> maas "Deploys via kustomize manifests" "K8s API SSA"

        // Operator → External Platform
        rhodsOperator -> k8sAPI "CRD watches, resource management, SSA" "HTTPS/443"
        rhodsOperator -> olm "Subscription watches, dependency detection" "K8s API"
        rhodsOperator -> istio "EnvoyFilter, DestinationRule for gateway" "K8s API"
        rhodsOperator -> gatewayAPICRDs "Gateway, GatewayClass, HTTPRoute" "K8s API"

        // Cloud Manager → Dependencies (XKS only)
        cloudmanager -> certManager "Helm deploy (XKS)" "K8s API"
        cloudmanager -> istio "Helm deploy Sail (XKS)" "K8s API"

        // Operator → External Services
        rhodsOperator -> openshiftOAuth "Register OAuthClient, user auth" "HTTPS/443"
        rhodsOperator -> oidcProvider "OIDC client auth" "HTTPS/443"
        rhodsOperator -> serviceCA "Auto-generate TLS certs" "Internal"

        // Operator → Observability
        rhodsOperator -> coo "CRD Watch: MonitoringStack, Perses" "K8s API"
        rhodsOperator -> tempoOperator "CRD Watch: TempoMonolithic" "K8s API"
        rhodsOperator -> otelOperator "CRD Watch: OTelCollector, Instrumentation" "K8s API"
        rhodsOperator -> prometheusOperator "CRD Watch: PrometheusRule, ServiceMonitor" "K8s API"
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
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #d4a574
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures RHOAI platform via DSC/DSCI CRs"
        dataScienceUser = person "Data Scientist" "Uses AI/ML platform services"

        rhodsOperator = softwareSystem "rhods-operator" "Central platform operator orchestrating the entire RHOAI stack, managing component lifecycle, ingress, auth, monitoring" {
            manager = container "Manager (Operator)" "Primary operator binary hosting all controllers and webhooks" "Go (controller-runtime)" {
                dscController = component "DSC Controller" "Orchestrates component provisioning via registry pattern" "Controller"
                dsciController = component "DSCI Controller" "Platform initialization: namespaces, networking, monitoring, auth" "Controller"
                gatewayController = component "Gateway Controller" "Multi-layer ingress: Gateway API, kube-auth-proxy, EnvoyFilter" "Controller"
                authController = component "Auth Controller" "RBAC for admin/allowed user groups" "Controller"
                monitoringController = component "Monitoring Controller" "Deploys MonitoringStack, OTEL, Tempo, Perses, ThanosQuerier" "Controller"
                certConfigMapGen = component "CertConfigMapGenerator" "Distributes CA bundle ConfigMaps across namespaces" "Controller"
                componentRegistry = component "Component Registry" "Registry of 16 component handlers (Dashboard, KServe, Kueue, etc.)" "Go Interface"
                webhookServer = component "Webhook Server" "12 admission webhooks: singleton enforcement, HW profile injection, connections" "Go HTTP/TLS"
            }
            cloudmanager = container "cloudmanager" "Cloud-specific controller for Azure AKS and CoreWeave Kubernetes" "Go CLI"
        }

        # Internal RHOAI Components (managed by operator)
        dashboard = softwareSystem "Dashboard" "Web UI for RHOAI platform" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving infrastructure" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing system" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Notebook controllers and images" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata registry" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "Pipeline operator with Argo Workflows" "Internal RHOAI"
        modelController = softwareSystem "Model Controller" "Model serving orchestration" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI trustworthiness tooling" "Internal RHOAI"
        ray = softwareSystem "Ray (KubeRay)" "Distributed computing" "Internal RHOAI"
        trainer = softwareSystem "Trainer" "Training job runtime" "Internal RHOAI"
        trainingOperator = softwareSystem "Training Operator" "Kubeflow training" "Internal RHOAI"
        feast = softwareSystem "Feast" "Feature store" "Internal RHOAI"
        llamaStack = softwareSystem "LlamaStack" "LlamaStack operator" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking" "Internal RHOAI"
        spark = softwareSystem "Spark" "Spark on Kubernetes" "Internal RHOAI"
        maas = softwareSystem "Models-as-a-Service" "Multi-tenant model serving" "Internal RHOAI"

        # External Dependencies
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager" "External"
        istio = softwareSystem "Istio / Sail Operator" "Service mesh and EnvoyFilter management" "External"
        certManager = softwareSystem "cert-manager" "Certificate management" "External"
        gatewayApi = softwareSystem "Gateway API (Envoy)" "Kubernetes Gateway API with Envoy data plane" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OAuth2 identity provider" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Route-based ingress" "External"
        obsOperator = softwareSystem "Observability Stack Operator" "MonitoringStack, ThanosQuerier CRDs" "External"
        otelOperator = softwareSystem "OpenTelemetry Operator" "OTEL Collector CRDs" "External"
        tempoOperator = softwareSystem "Tempo Operator" "Distributed tracing" "External"
        persesOperator = softwareSystem "Perses Operator" "Visualization dashboards" "External"
        segment = softwareSystem "Segment.io" "Usage analytics" "External"

        # Relationships - Users
        platformAdmin -> rhodsOperator "Creates DSC/DSCI CRs via kubectl" "HTTPS/6443"
        dataScienceUser -> gatewayApi "Accesses AI/ML services" "HTTPS/443"

        # Relationships - Operator to K8s
        rhodsOperator -> k8sApi "Manages all platform resources" "HTTPS/6443"
        olm -> rhodsOperator "Installs and upgrades operator"

        # Relationships - Operator to External
        rhodsOperator -> istio "Creates EnvoyFilter, DestinationRule" "HTTPS/443"
        rhodsOperator -> certManager "Manages certificates for webhooks and KServe"
        rhodsOperator -> gatewayApi "Creates Gateway, GatewayClass, HTTPRoute" "HTTPS/443"
        rhodsOperator -> openshiftOAuth "Creates OAuthClient for gateway auth" "HTTPS/443"
        rhodsOperator -> openshiftRouter "Creates Routes for legacy redirects, Prometheus" "HTTPS/443"
        rhodsOperator -> obsOperator "Creates MonitoringStack, ThanosQuerier CRs"
        rhodsOperator -> otelOperator "Creates OpenTelemetryCollector CR"
        rhodsOperator -> tempoOperator "Creates TempoMonolithic/TempoStack CR"
        rhodsOperator -> persesOperator "Creates Perses, PersesDatasource CRs"
        rhodsOperator -> segment "Sends usage analytics (RHOAI only)" "HTTPS/443"

        # Relationships - Operator to Components
        rhodsOperator -> dashboard "Deploys via CRD + kustomize"
        rhodsOperator -> kserve "Deploys via CRD + kustomize"
        rhodsOperator -> kueue "Deploys via CRD + kustomize + config conversion"
        rhodsOperator -> workbenches "Deploys via CRD + kustomize"
        rhodsOperator -> modelRegistry "Deploys via CRD + kustomize"
        rhodsOperator -> dsp "Deploys via CRD + kustomize"
        rhodsOperator -> modelController "Deploys via CRD + kustomize"
        rhodsOperator -> trustyai "Deploys via CRD + kustomize"
        rhodsOperator -> ray "Deploys via CRD + kustomize"
        rhodsOperator -> trainer "Deploys via CRD + kustomize"
        rhodsOperator -> trainingOperator "Deploys via CRD + kustomize"
        rhodsOperator -> feast "Deploys via CRD + kustomize"
        rhodsOperator -> llamaStack "Deploys via CRD + kustomize"
        rhodsOperator -> mlflow "Deploys via CRD + kustomize"
        rhodsOperator -> spark "Deploys via CRD + kustomize"
        rhodsOperator -> maas "Deploys via CRD + kustomize"

        # Cloud manager
        cloudmanager -> k8sApi "Deploys prerequisite Helm charts" "HTTPS/6443"
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

        component manager "Components" {
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        // Users
        platformAdmin = person "Platform Admin" "Configures and manages the RHOAI platform via DSC/DSCI CRs"
        dataScientist = person "Data Scientist" "Uses AI/ML platform services (notebooks, model serving, pipelines)"
        securityTeam = person "Security Team" "Reviews platform security posture, RBAC, and network policies"

        // Primary System
        rhodsOperator = softwareSystem "rhods-operator" "Central platform operator that deploys, configures, and manages the entire RHOAI AI/ML platform" {
            manager = container "manager" "Primary operator binary running all platform controllers, service controllers, component controllers, and webhooks" "Go Operator (controller-runtime)" "Primary"
            cloudmanager = container "cloudmanager" "Cloud-specific controller managing dependency operators on non-OpenShift Kubernetes (AWS, Azure, CoreWeave)" "Go Controller" "Secondary"

            dscController = component "DSC Controller" "Orchestrates all AI/ML component lifecycle based on DataScienceCluster CR" "Controller" {
                tags "Controller"
            }
            dsciController = component "DSCI Controller" "Initializes platform infrastructure: namespaces, networking, auth, monitoring, gateway" "Controller" {
                tags "Controller"
            }
            gatewayController = component "Gateway Controller" "Deploys Gateway API ingress stack: Gateway, Envoy, EnvoyFilter, kube-auth-proxy" "Controller" {
                tags "Controller"
            }
            authController = component "Auth Controller" "Manages RBAC groups, roles, and role bindings" "Controller" {
                tags "Controller"
            }
            monitoringController = component "Monitoring Controller" "Deploys Prometheus, Thanos, Tempo, OTel, Perses" "Controller" {
                tags "Controller"
            }
            componentControllers = component "Component Controllers (16)" "Individual controllers for Dashboard, KServe, Kueue, Ray, DSP, etc." "Controllers" {
                tags "Controller"
            }
            webhooks = component "Admission Webhooks (12)" "Validating/mutating webhooks for DSC, DSCI, HardwareProfile, connections" "Webhook Server" {
                tags "Webhook"
            }
        }

        // Managed AI/ML Components (deployed by rhods-operator)
        dashboard = softwareSystem "ODH Dashboard" "AI/ML platform web UI" "Managed Component"
        kserve = softwareSystem "KServe" "Model serving with LLM inference support" "Managed Component"
        kueue = softwareSystem "Kueue" "Job queuing and resource management" "Managed Component"
        ray = softwareSystem "Ray" "Distributed computing framework" "Managed Component"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (DSPO)" "Managed Component"
        trustyai = softwareSystem "TrustyAI" "AI trustworthiness and explainability" "Managed Component"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and artifact registry" "Managed Component"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments" "Managed Component"
        modelsAsService = softwareSystem "Models as a Service" "MaaS controller for model deployment" "Managed Component"
        trainingOperator = softwareSystem "Training Operator" "Kubeflow distributed training" "Managed Component"

        // Platform Dependencies (internal)
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "Internal Dependency"
        istio = softwareSystem "Istio / Sail Operator" "Service mesh, Envoy proxy, traffic management" "Internal Dependency"
        monitoringStackOp = softwareSystem "Monitoring Stack Operator (COO)" "Prometheus/Thanos stack operator" "Internal Dependency"
        tempoOp = softwareSystem "Tempo Operator" "Distributed tracing backend" "Internal Dependency"
        otelOp = softwareSystem "OpenTelemetry Operator" "Trace collection" "Internal Dependency"
        persesOp = softwareSystem "Perses Operator" "Dashboard visualization" "Internal Dependency"
        authorino = softwareSystem "Authorino" "API authentication for MaaS" "Internal Dependency"
        lws = softwareSystem "LeaderWorkerSet Operator" "LLM inference pod management" "Internal Dependency"

        // External Systems
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Platform authentication" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Auto TLS certificate injection" "External"

        // Relationships - Users
        platformAdmin -> rhodsOperator "Creates DSC/DSCI CRs via kubectl/console"
        dataScientist -> dashboard "Accesses AI/ML platform UI"
        dataScientist -> workbenches "Creates notebooks and workbenches"
        dataScientist -> kserve "Deploys ML models for inference"

        // Relationships - Operator to managed components
        rhodsOperator -> dashboard "Deploys and manages" "K8s API (SSA)"
        rhodsOperator -> kserve "Deploys and manages" "K8s API (SSA)"
        rhodsOperator -> kueue "Deploys and manages" "K8s API (SSA)"
        rhodsOperator -> ray "Deploys and manages" "K8s API (SSA)"
        rhodsOperator -> dsp "Deploys and manages" "K8s API (SSA)"
        rhodsOperator -> trustyai "Deploys and manages" "K8s API (SSA)"
        rhodsOperator -> modelRegistry "Deploys and manages" "K8s API (SSA)"
        rhodsOperator -> workbenches "Deploys and manages" "K8s API (SSA)"
        rhodsOperator -> modelsAsService "Deploys and manages" "K8s API (SSA)"
        rhodsOperator -> trainingOperator "Deploys and manages" "K8s API (SSA)"

        // Relationships - Platform dependencies
        rhodsOperator -> certManager "Requests TLS certificates" "K8s API (Certificate CRDs)"
        rhodsOperator -> istio "Creates EnvoyFilter, DestinationRule" "K8s API (Istio CRDs)"
        rhodsOperator -> monitoringStackOp "Deploys MonitoringStack" "K8s API (monitoring.rhobs CRDs)"
        rhodsOperator -> tempoOp "Deploys Tempo instances" "K8s API (tempo.grafana.com CRDs)"
        rhodsOperator -> otelOp "Deploys OTel collectors" "K8s API (opentelemetry.io CRDs)"
        rhodsOperator -> persesOp "Deploys Perses dashboards" "K8s API (perses.dev CRDs)"
        rhodsOperator -> authorino "Configures API auth" "K8s API (kuadrant.io CRDs)"
        rhodsOperator -> lws "Required by KServe" "K8s API (leaderworkerset CRDs)"

        // Relationships - External systems
        rhodsOperator -> k8sApi "All controller operations" "HTTPS/6443 TLS 1.2+ SA token"
        rhodsOperator -> openshiftOAuth "Registers OAuth client, auth flow" "HTTPS/443 TLS 1.2+"
        rhodsOperator -> olm "Manages Subscriptions, CSVs" "K8s API"
        rhodsOperator -> openshiftServiceCA "Auto TLS cert injection" "Annotation-based"

        // Cloud manager relationships
        cloudmanager -> certManager "Deploys via Helm" "Helm charts"
        cloudmanager -> istio "Deploys via Helm" "Helm charts"
        cloudmanager -> lws "Deploys via Helm" "Helm charts"
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
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Managed Component" {
                background #7ed321
                color #ffffff
            }
            element "Internal Dependency" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Primary" {
                background #438dd5
            }
            element "Secondary" {
                background #85bbf0
            }
            element "Controller" {
                background #438dd5
            }
            element "Webhook" {
                background #e65100
                color #ffffff
            }
        }
    }
}

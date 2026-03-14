workspace {
    model {
        user = person "Data Scientist / Administrator" "Uses the dashboard to manage data science projects, notebooks, models, and pipelines"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based UI for managing Open Data Hub and RHOAI components" {
            frontend = container "Frontend Application" "React 18 + PatternFly 6 SPA with module federation" "TypeScript, React" {
                tags "Web Application"
            }

            backend = container "Backend API Server" "REST API proxy to Kubernetes, authentication handling" "Node.js, Fastify" {
                tags "API Server"
            }

            kubeRbacProxy = container "kube-rbac-proxy" "OAuth enforcement and TLS termination sidecar" "Go" {
                tags "Security Proxy"
            }

            modelRegistryUI = container "Model Registry UI" "Federated micro-frontend for model registry management" "React" {
                tags "Micro-frontend"
            }

            genAiUI = container "GenAI UI" "Federated micro-frontend for GenAI features" "React" {
                tags "Micro-frontend"
            }

            maasUI = container "MaaS UI" "Federated micro-frontend for Model-as-a-Service" "React" {
                tags "Micro-frontend"
            }
        }

        # External Systems
        openshift = softwareSystem "OpenShift Platform" "Container orchestration and OAuth authentication" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "User authentication and token issuance" "External"
        prometheus = softwareSystem "Prometheus" "Cluster metrics and monitoring" "External"

        # Internal ODH Components
        odhOperator = softwareSystem "ODH/RHODS Operator" "Manages DataScienceCluster and component lifecycle" "Internal ODH"
        notebooksController = softwareSystem "Kubeflow Notebooks Controller" "Manages Jupyter notebook instances" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving and inference platform" "Internal ODH"
        modelRegistryOp = softwareSystem "Model Registry Operator" "Model metadata and registry management" "Internal ODH"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "ML pipeline orchestration" "Internal ODH"
        feastOperator = softwareSystem "Feast Operator" "Feature store management" "Internal ODH"
        rayOperator = softwareSystem "Ray Operator" "Distributed workload management" "Internal ODH"
        nvidiaNim = softwareSystem "NVIDIA NIM" "NVIDIA model serving integration" "Internal ODH"

        # External Services
        s3Storage = softwareSystem "S3 Storage" "Object storage for models and data" "External Service"
        imageRegistry = softwareSystem "Container Image Registries" "Container images for notebooks and serving runtimes" "External Service"

        # User interactions
        user -> odhDashboard "Uses web UI to manage data science workloads" "HTTPS/443, OAuth Bearer Token"

        # Dashboard internal relationships
        user -> frontend "Accesses dashboard UI" "HTTPS/443"
        frontend -> kubeRbacProxy "Authenticates via" "HTTPS/8443"
        kubeRbacProxy -> oauthServer "Validates OAuth tokens" "HTTPS/443"
        kubeRbacProxy -> backend "Forwards authenticated requests" "HTTP/8080"
        backend -> frontend "Serves UI assets" "HTTP/8080"

        frontend -> modelRegistryUI "Loads via module federation" "HTTPS/8043"
        frontend -> genAiUI "Loads via module federation" "HTTPS/8143"
        frontend -> maasUI "Loads via module federation" "HTTPS/8243"

        # Backend integrations
        backend -> kubernetesAPI "CRUD operations on Kubernetes resources" "HTTPS/443, ServiceAccount + Impersonation"
        backend -> kubernetesAPI "WebSocket watch streams for real-time updates" "WSS/443"
        backend -> prometheus "Queries metrics for dashboards" "HTTPS/9091, ServiceAccount Token"

        # Component integrations
        backend -> odhOperator "Watches DataScienceCluster and DSCInitialization CRDs" "HTTPS/443"
        backend -> notebooksController "Creates and manages Notebook CRDs" "HTTPS/443"
        backend -> kserve "Watches InferenceService and ServingRuntime CRDs" "HTTPS/443"
        backend -> modelRegistryOp "Manages ModelRegistry CRDs" "HTTPS/443"
        backend -> dspOperator "Integrates with pipeline APIs" "HTTPS/443"
        backend -> feastOperator "Watches FeatureStore CRDs" "HTTPS/443"
        backend -> rayOperator "Watches distributed workload CRDs" "HTTPS/443"
        backend -> nvidiaNim "Manages NIM Account CRDs" "HTTPS/443"

        modelRegistryUI -> modelRegistryOp "Accesses model registry backend" "HTTPS"

        # External service integrations
        backend -> s3Storage "References object storage for models and data" "HTTPS/443, AWS credentials"
        backend -> imageRegistry "References container images for notebooks" "HTTPS/443"

        # OpenShift platform dependencies
        kubeRbacProxy -> openshift "Uses OpenShift Routes and service-ca for TLS" "HTTPS"
        backend -> openshift "Uses OpenShift-specific resources (Routes, ConsoleLinks)" "HTTPS/443"
    }

    views {
        systemContext odhDashboard "SystemContext" {
            include *
            autoLayout
            description "System context diagram for ODH Dashboard showing external users, ODH components, and external services"
        }

        container odhDashboard "Containers" {
            include *
            autoLayout
            description "Container diagram showing internal components of ODH Dashboard including frontend, backend, proxy, and micro-frontends"
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }

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
                color #000000
            }

            element "External Service" {
                background #f5a623
                color #000000
            }

            element "Container" {
                background #438dd5
                color #ffffff
            }

            element "Web Application" {
                shape WebBrowser
                background #438dd5
                color #ffffff
            }

            element "API Server" {
                background #4a90e2
                color #ffffff
            }

            element "Security Proxy" {
                background #f5a623
                color #000000
            }

            element "Micro-frontend" {
                background #9b59b6
                color #ffffff
            }
        }

        theme default
    }
}

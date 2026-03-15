workspace {
    model {
        user = person "Data Scientist" "Creates and manages data science projects, notebooks, and model deployments"
        admin = person "Platform Administrator" "Configures ODH/RHOAI components and monitors system health"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based UI for Open Data Hub and Red Hat OpenShift AI platform management" {
            frontend = container "Frontend" "Single-page application with React 18 and PatternFly 6" "TypeScript/React" {
                tags "Web Application"
            }
            backend = container "Backend" "REST API server and Kubernetes proxy" "Node.js/Fastify" {
                tags "API Server"
            }
            proxy = container "kube-rbac-proxy" "OAuth authentication and authorization sidecar" "Go Proxy" {
                tags "Security"
            }
            modelRegistryUI = container "Model Registry UI" "Federated micro-frontend for model registry management" "React" {
                tags "Web Application" "Modular"
            }
            genAIUI = container "GenAI UI" "Federated micro-frontend for GenAI features" "React" {
                tags "Web Application" "Modular"
            }
            maasUI = container "MaaS UI" "Federated micro-frontend for Model-as-a-Service" "React" {
                tags "Web Application" "Modular"
            }
        }

        # External Systems
        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration and resource management" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes platform with OAuth and routing" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Internal ODH Components
        odhOperator = softwareSystem "ODH/RHODS Operator" "Manages DataScienceCluster and component lifecycle" "Internal ODH"
        notebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook instances for data science work" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving platform for ML inference" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and artifact management" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration" "Internal ODH"
        feast = softwareSystem "Feast" "Feature store for ML training and serving" "Internal ODH"
        ray = softwareSystem "Ray Operator" "Distributed workload management" "Internal ODH"
        nim = softwareSystem "NVIDIA NIM" "NVIDIA inference microservices" "Internal ODH"

        # External Services
        s3 = softwareSystem "S3 Storage" "Object storage for models and data" "External Service"
        imageRegistry = softwareSystem "Container Registry" "Container images for notebooks and serving" "External Service"

        # User interactions
        user -> odhDashboard "Creates projects, notebooks, and deploys models via web UI" "HTTPS/443"
        admin -> odhDashboard "Configures components and monitors status" "HTTPS/443"

        # Container relationships
        user -> frontend "Uses web interface"
        admin -> frontend "Configures platform"
        frontend -> proxy "Accesses via authenticated session" "HTTPS/8443"
        proxy -> backend "Forwards authenticated requests" "HTTP/8080"
        proxy -> openshift "Validates OAuth tokens" "HTTPS/443"
        backend -> kubernetes "Manages resources via API" "HTTPS/443"
        backend -> prometheus "Queries metrics" "HTTPS/9091"
        backend -> modelRegistryUI "Loads federated UI" "Module Federation"
        backend -> genAIUI "Loads federated UI" "Module Federation"
        backend -> maasUI "Loads federated UI" "Module Federation"

        # Component integrations
        odhDashboard -> kubernetes "Creates and manages Kubernetes resources" "HTTPS/443"
        odhDashboard -> openshift "Uses OAuth for authentication, Routes for ingress" "HTTPS/443"
        odhDashboard -> prometheus "Queries performance metrics" "HTTPS/9091"
        odhDashboard -> odhOperator "Watches DataScienceCluster and DSCInitialization status" "Kubernetes API"
        odhDashboard -> notebooks "Creates and manages Notebook CRDs" "Kubernetes API"
        odhDashboard -> kserve "Monitors InferenceService and ServingRuntime resources" "Kubernetes API"
        odhDashboard -> modelRegistry "Creates and manages ModelRegistry CRDs" "Kubernetes API"
        odhDashboard -> pipelines "Integrates pipeline management (if enabled)" "REST API"
        odhDashboard -> feast "Manages FeatureStore CRDs" "Kubernetes API"
        odhDashboard -> ray "Monitors distributed workloads" "Kubernetes API"
        odhDashboard -> nim "Manages NVIDIA NIM Account CRDs" "Kubernetes API"
        odhDashboard -> s3 "Accesses model artifacts and data" "HTTPS/443"
        odhDashboard -> imageRegistry "Pulls container images for notebooks and serving" "HTTPS/443"

        # Model Registry integration
        modelRegistryUI -> modelRegistry "Fetches model metadata and artifacts" "REST API"
    }

    views {
        systemContext odhDashboard "SystemContext" {
            include *
            autoLayout lr
        }

        container odhDashboard "Containers" {
            include *
            autoLayout lr
        }

        styles {
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
            element "Web Application" {
                shape WebBrowser
                background #4a90e2
                color #ffffff
            }
            element "API Server" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
            element "Security" {
                shape Hexagon
                background #f5a623
                color #000000
            }
            element "Modular" {
                border Dashed
            }
        }
    }
}

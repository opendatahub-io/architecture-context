workspace {
    model {
        user = person "Data Scientist" "Creates and manages data science workloads, notebooks, and model deployments"
        admin = person "Platform Administrator" "Configures ODH/RHOAI platform settings and manages users"

        odh_dashboard = softwareSystem "ODH Dashboard" "Web-based user interface for managing Red Hat OpenShift AI platform components" {
            frontend = container "Frontend" "User interface for dashboard features" "React/TypeScript SPA" {
                tags "Web Browser"
            }
            backend = container "Backend" "API server handling K8s operations and business logic" "Fastify (Node.js) REST API" {
                tags "API"
            }
            oauth_proxy = container "OAuth Proxy" "OpenShift OAuth authentication and authorization" "Sidecar container" {
                tags "Security"
            }
        }

        # External Platform Components
        openshift_oauth = softwareSystem "OpenShift OAuth Server" "User authentication and authorization" "External Platform"
        k8s_api = softwareSystem "Kubernetes API Server" "Cluster resource management" "External Platform"
        thanos = softwareSystem "Thanos Querier" "Metrics collection and querying" "External Platform"
        imagestream_api = softwareSystem "ImageStream API" "Container image metadata service" "External Platform"

        # Internal ODH/RHOAI Components
        notebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook environments for data science" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving platform" "Internal ODH"
        modelmesh = softwareSystem "ModelMesh" "Alternative model serving backend" "Internal ODH"
        model_registry = softwareSystem "Model Registry" "Model versioning and registry" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal ODH"
        nim_serving = softwareSystem "NIM Serving" "NVIDIA NIM model serving" "Internal ODH"

        # User interactions
        user -> odh_dashboard "Creates projects, launches notebooks, deploys models" "HTTPS/443"
        admin -> odh_dashboard "Configures platform settings, manages accelerator profiles" "HTTPS/443"

        # Dashboard internal relationships
        user -> oauth_proxy "Authenticates via browser" "HTTPS/443"
        oauth_proxy -> frontend "Serves UI after authentication" "HTTPS/8443"
        frontend -> backend "API calls" "HTTP/8080"

        # External dependencies
        oauth_proxy -> openshift_oauth "OAuth 2.0 authentication" "HTTPS/443"
        backend -> k8s_api "Manage CRDs, namespaces, resources" "HTTPS/6443"
        backend -> thanos "Query metrics for model serving and notebooks" "HTTPS/9092"
        backend -> imagestream_api "Retrieve notebook image metadata" "HTTPS/443"

        # ODH component integrations
        backend -> notebooks "Create and manage Jupyter notebooks" "K8s API"
        backend -> kserve "Deploy and manage inference services" "K8s API"
        backend -> modelmesh "Manage ModelMesh serving runtimes" "K8s API"
        backend -> model_registry "Manage model registries and RBAC" "K8s API"
        backend -> pipelines "Integrate with ML pipelines" "K8s API"
        backend -> nim_serving "Manage NVIDIA NIM accounts" "K8s API"
    }

    views {
        systemContext odh_dashboard "SystemContext" {
            include *
            autoLayout
        }

        container odh_dashboard "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "API" {
                shape Hexagon
            }
            element "Security" {
                background #f5a623
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages data science workloads including notebooks, model serving, and pipelines"
        platformAdmin = person "Platform Admin" "Configures dashboard, manages users, and monitors platform health"

        dashboard = softwareSystem "ODH Dashboard" "Web-based user interface for managing Open Data Hub and Red Hat OpenShift AI platform components" {
            frontend = container "Frontend SPA" "Web user interface" "React 18, PatternFly 6, Redux" {
                description "Single-page application providing UI for dashboard functionality"
            }
            backend = container "Backend API" "REST API server and K8s proxy" "Node.js 20, Fastify" {
                description "Fastify-based REST API that proxies to Kubernetes API and provides business logic"
            }
            oauthProxy = container "OAuth Proxy" "Authentication and TLS termination" "OpenShift OAuth Proxy" {
                description "Sidecar container providing OpenShift OAuth authentication and HTTPS termination"
            }
            moduleFederation = container "Module Federation" "Dynamic plugin loader" "Webpack 5 Module Federation" {
                description "Loads feature plugins dynamically (gen-ai, model-registry, etc.)"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External Platform" {
            description "Manages all Kubernetes resources and enforces RBAC"
        }

        oauthServer = softwareSystem "OpenShift OAuth Server" "Authentication service" "External Platform" {
            description "Provides OAuth 2.0 authentication for OpenShift users"
        }

        prometheus = softwareSystem "Prometheus/Thanos" "Metrics and monitoring" "External Platform" {
            description "Collects and stores metrics data"
        }

        odhOperator = softwareSystem "ODH Operator" "Platform orchestration" "Internal ODH" {
            description "Manages DataScienceCluster and DSCInitialization resources"
        }

        notebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook management" "Internal ODH" {
            description "Manages Jupyter notebook custom resources and workbenches"
        }

        kserve = softwareSystem "KServe" "Model serving platform" "Internal ODH" {
            description "Serverless inference for ML models"
        }

        modelRegistry = softwareSystem "Model Registry" "Model metadata and versioning" "Internal ODH" {
            description "Stores model metadata, versions, and artifacts"
        }

        pipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration" "Internal ODH" {
            description "Manages pipeline runs and experiments"
        }

        codeflare = softwareSystem "CodeFlare Operator" "Distributed training" "Internal ODH" {
            description "Manages distributed training workloads"
        }

        kueue = softwareSystem "Kueue" "Workload queue management" "Internal ODH" {
            description "Manages distributed workload queue configurations"
        }

        s3Storage = softwareSystem "S3 Storage" "Model artifact storage" "External Service" {
            description "Stores model artifacts and data"
        }

        segmentAnalytics = softwareSystem "Segment Analytics" "Usage analytics" "External Service" {
            description "Optional usage analytics and telemetry"
        }

        // User interactions
        dataScientist -> dashboard "Creates notebooks, deploys models, runs pipelines via" "HTTPS/443"
        platformAdmin -> dashboard "Configures dashboard, manages users, monitors health via" "HTTPS/443"

        // Dashboard internal relationships
        frontend -> backend "API calls" "HTTP/8080 (proxied via OAuth)"
        oauthProxy -> backend "Forwards authenticated requests" "HTTP/8080"
        oauthProxy -> oauthServer "Validates user authentication" "HTTPS/6443"
        backend -> k8sAPI "Manages Kubernetes resources" "HTTPS/6443, SA Token"
        backend -> prometheus "Queries metrics data" "HTTPS/9092, SA Token"

        // Dashboard to ODH components (via K8s API)
        backend -> odhOperator "Reads DataScienceCluster status" "via K8s API"
        backend -> notebooks "Creates and manages Notebook CRs" "via K8s API"
        backend -> kserve "Reads InferenceService status" "via K8s API"
        backend -> modelRegistry "Creates and manages ModelRegistry CRs" "via K8s API"
        backend -> pipelines "Integrates with pipeline runs" "via K8s API"
        backend -> codeflare "Manages distributed workloads" "via K8s API"
        backend -> kueue "Manages queue configurations" "via K8s API"

        // External services
        backend -> segmentAnalytics "Sends usage analytics" "HTTPS/443, API Key" {
            tags "Optional"
        }

        // Supporting services
        prometheus -> oauthProxy "Scrapes /metrics endpoint" "HTTPS/8443, No Auth"
        modelRegistry -> s3Storage "Stores model artifacts" "HTTPS/443"
    }

    views {
        systemContext dashboard "DashboardSystemContext" {
            include *
            autoLayout lr
            description "System context diagram for ODH Dashboard showing all external dependencies and integrations"
        }

        container dashboard "DashboardContainers" {
            include *
            autoLayout lr
            description "Container diagram showing internal components of ODH Dashboard"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External Platform" {
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            relationship "Optional" {
                dashed true
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

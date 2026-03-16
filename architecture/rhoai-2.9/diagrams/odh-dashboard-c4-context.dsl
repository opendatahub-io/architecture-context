workspace {
    model {
        dataScientist = person "Data Scientist" "Uses RHOAI platform to develop, train, and deploy ML models"
        admin = person "Administrator" "Manages RHOAI platform configuration and user access"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management interface for Red Hat OpenShift AI platform" {
            frontend = container "React Frontend" "User interface for RHOAI platform management" "React 18 + PatternFly 5" {
                tags "WebApp"
            }
            backend = container "Dashboard Backend" "REST API server interfacing with Kubernetes and platform services" "Fastify/Node.js 18" {
                tags "API"
            }
            oauthProxy = container "OAuth Proxy" "Authenticates users and enforces RBAC policies" "OpenShift OAuth Proxy" {
                tags "Security"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Manages cluster resources and custom resources" "External Platform"
        oauthServer = softwareSystem "OpenShift OAuth Server" "Authenticates users and issues access tokens" "External Platform"
        thanosQuerier = softwareSystem "Thanos Querier" "Queries cluster and workload metrics from Prometheus" "External Platform"
        imageRegistry = softwareSystem "OpenShift Image Registry" "Stores and serves container images" "External Platform"

        kubeflowNotebook = softwareSystem "Kubeflow Notebook Controller" "Manages Jupyter notebook workbench lifecycle" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving platform with serverless autoscaling" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration and execution" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and lineage tracking (preview)" "Internal ODH"

        %% User relationships
        dataScientist -> odhDashboard "Creates notebooks, deploys models, monitors pipelines" "HTTPS/443"
        admin -> odhDashboard "Configures platform settings, manages users and groups" "HTTPS/443"

        %% Dashboard component relationships
        oauthProxy -> frontend "Proxies authenticated requests to" "HTTPS/8443"
        oauthProxy -> backend "Forwards requests with user token" "HTTP/8080 localhost"
        frontend -> backend "Makes API calls to" "via OAuth Proxy"

        %% External platform dependencies
        oauthProxy -> oauthServer "Validates user sessions and tokens" "HTTPS/443"
        backend -> k8sAPI "Manages CRDs, namespaces, secrets, RBAC" "HTTPS/6443"
        backend -> thanosQuerier "Queries metrics for dashboards" "HTTPS/9092"
        backend -> imageRegistry "Retrieves notebook image metadata" "HTTPS/443"

        %% Internal ODH integrations
        odhDashboard -> kubeflowNotebook "Creates and manages Notebook CRs" "via K8s API"
        odhDashboard -> kserve "Manages ServingRuntime and InferenceService CRs" "via K8s API"
        odhDashboard -> dsPipelines "Retrieves pipeline runs and logs" "HTTPS/8443"
        odhDashboard -> modelRegistry "Fetches model metadata (feature-flagged)" "gRPC/API"

        %% Controller watches
        kubeflowNotebook -> k8sAPI "Watches Notebook CRs" "K8s Watch API"
        kserve -> k8sAPI "Watches ServingRuntime CRs" "K8s Watch API"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
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
            element "WebApp" {
                shape WebBrowser
                background #4a90e2
                color #ffffff
            }
            element "API" {
                background #4a90e2
                color #ffffff
            }
            element "Security" {
                background #f5a623
                color #ffffff
            }
        }
    }
}

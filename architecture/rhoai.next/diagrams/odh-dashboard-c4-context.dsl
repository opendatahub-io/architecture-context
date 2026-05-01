workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, workbenches, deploys models, runs pipelines"
        admin = person "Platform Admin" "Configures dashboard, manages hardware profiles, sets cluster settings"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for RHOAI providing unified UI for ML/AI workloads" {
            frontend = container "Dashboard Frontend" "React SPA with Module Federation host, PatternFly 6, Redux state management" "TypeScript/React"
            backend = container "Dashboard Backend" "API proxy to K8s API, WebSocket relay, Prometheus proxy, service discovery proxy, static file server" "Node.js/Fastify"
            kubeRbacProxy = container "kube-rbac-proxy" "RBAC enforcement proxy validating OpenShift identity, injecting auth headers" "Go Sidecar"
            genAiBff = container "Gen AI BFF" "LlamaStack integration, vector stores, RAG, guardrails, MCP tools, prompt management" "Go BFF"
            maasBff = container "MaaS BFF" "Model-as-a-Service tier management, API key provisioning, subscription/policy management" "Go BFF"
            automlBff = container "AutoML BFF" "Automated ML pipeline execution for tabular/time-series data" "Go BFF"
            autoragBff = container "AutoRAG BFF" "Automated RAG pipeline orchestration" "Go BFF"
            evalHubBff = container "Eval Hub BFF" "Model evaluation job management via TrustyAI" "Go BFF"
            mlflowBff = container "MLflow BFF" "Experiment tracking and model lifecycle management" "Go BFF"
            modelRegBff = container "Model Registry BFF" "Model versioning, artifact management, model catalog, MCP catalog" "Go BFF"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for all resource CRUD and RBAC" "Platform"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "User authentication via OAuth2 Authorization Code flow" "Platform"
        thanosQuerier = softwareSystem "Thanos Querier" "Prometheus metrics queries for monitoring dashboards" "Platform"
        dsPipelines = softwareSystem "DS Pipelines" "Kubeflow Pipelines for ML pipeline execution" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model version and artifact management service" "Internal RHOAI"
        trustyAI = softwareSystem "TrustyAI / EvalHub" "AI explainability, bias metrics, model evaluation" "Internal RHOAI"
        llamaStack = softwareSystem "LlamaStack Distribution" "Gen AI model inference, vector stores, RAG" "Internal RHOAI"
        maasApi = softwareSystem "MaaS API" "Model-as-a-Service backend for tier/subscription management" "Internal RHOAI"
        mlflowTracking = softwareSystem "MLflow Tracking Server" "Experiment tracking, prompt management" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless model serving (ServingRuntime, InferenceService)" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for data files (CSV, Parquet) and model artifacts" "External"

        # Person relationships
        dataScientist -> odhDashboard "Manages notebooks, models, pipelines via browser" "HTTPS/443"
        admin -> odhDashboard "Configures platform, hardware profiles, feature flags" "HTTPS/443"

        # Internal container relationships
        frontend -> backend "Serves SPA and API calls"
        kubeRbacProxy -> backend "Forwards authenticated requests" "HTTP/8080 with x-forwarded-access-token"
        backend -> genAiBff "Proxies /_mf/gen-ai requests" "HTTPS/8143"
        backend -> maasBff "Proxies /_mf/maas requests" "HTTPS/8243"
        backend -> automlBff "Proxies /_mf/automl requests" "HTTPS/8643"
        backend -> autoragBff "Proxies /_mf/autorag requests" "HTTPS/8743"
        backend -> evalHubBff "Proxies /_mf/eval-hub requests" "HTTPS/8543"
        backend -> mlflowBff "Proxies /_mf/mlflow requests" "HTTPS/8343"
        backend -> modelRegBff "Proxies /_mf/model-registry requests" "HTTPS/8043"
        genAiBff -> maasBff "Inter-BFF token issuance" "HTTPS/8243"

        # External system relationships
        odhDashboard -> k8sApi "All K8s resource CRUD, CRD watch, RBAC enforcement" "HTTPS/6443"
        odhDashboard -> openshiftOAuth "User authentication, token issuance" "HTTPS/443"
        odhDashboard -> thanosQuerier "Prometheus metrics for dashboards" "HTTPS/9092"
        odhDashboard -> dsPipelines "Pipeline run management" "HTTPS/8443"
        odhDashboard -> modelRegistry "Model version and artifact management" "HTTP/8080"
        odhDashboard -> trustyAI "Bias metrics, explainability, evaluations" "HTTP/8080"
        odhDashboard -> llamaStack "Gen AI inference, vector stores, RAG" "HTTP/8321"
        odhDashboard -> maasApi "Tier/subscription management" "HTTPS/8443"
        odhDashboard -> mlflowTracking "Experiment tracking, prompts" "HTTP/5000"
        odhDashboard -> kserve "ServingRuntime and InferenceService lifecycle" "HTTPS/6443 (via K8s API)"
        odhDashboard -> s3Storage "Data file access for AutoML/AutoRAG" "HTTPS/443"
    }

    views {
        systemContext odhDashboard "SystemContext" {
            include *
            autoLayout
        }

        container odhDashboard "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
        }
    }
}

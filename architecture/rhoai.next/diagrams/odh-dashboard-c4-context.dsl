workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, deploys models, runs pipelines, manages ML workflows"
        platformAdmin = person "Platform Admin" "Configures dashboard settings, manages hardware profiles, controls feature flags"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Red Hat OpenShift AI (RHOAI) providing unified UI for ML/AI workloads" {
            kubeRbacProxy = container "kube-rbac-proxy" "OpenShift RBAC enforcement proxy - validates user identity, injects auth headers" "Go Sidecar" "Auth"
            frontend = container "Dashboard Frontend" "React SPA with Module Federation host, PatternFly UI, Redux state management" "TypeScript/React"
            backend = container "Dashboard BFF" "API proxy to K8s, WebSocket relay, Prometheus proxy, service discovery" "Node.js/Fastify"
            genAiBff = container "Gen AI BFF" "LlamaStack integration, vector stores, RAG, guardrails, MCP tools, prompts" "Go BFF" "Optional"
            maasBff = container "MaaS BFF" "Model-as-a-Service tier management, API key provisioning, subscriptions" "Go BFF" "Optional"
            automlBff = container "AutoML BFF" "Automated ML pipeline execution for tabular/time-series data" "Go BFF" "Optional"
            autoragBff = container "AutoRAG BFF" "Automated RAG pipeline orchestration" "Go BFF" "Optional"
            evalHubBff = container "Eval Hub BFF" "Model evaluation job management via TrustyAI" "Go BFF" "Optional"
            mlflowBff = container "MLflow BFF" "Experiment tracking and model lifecycle management" "Go BFF" "Optional"
            modelRegBff = container "Model Registry BFF" "Model versioning, artifact management, catalog, MCP catalog" "Go BFF" "Optional"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for all resource management and RBAC" "Platform"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "User authentication and token issuance" "Platform"
        thanosQuerier = softwareSystem "Thanos Querier" "Prometheus metrics aggregation in openshift-monitoring" "Platform"

        dsPipelines = softwareSystem "DS Pipelines" "Kubeflow Pipelines API for ML pipeline management" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model version and artifact management service" "Internal RHOAI"
        trustyAI = softwareSystem "TrustyAI / EvalHub" "AI explainability, bias metrics, model evaluation" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving with ServingRuntime and InferenceService" "Internal RHOAI"
        llamaStack = softwareSystem "LlamaStack Distribution" "Gen AI model inference, vector stores, RAG" "Internal RHOAI"
        maasApi = softwareSystem "MaaS API" "Model-as-a-Service backend for tier/subscription management" "Internal RHOAI"
        mlflowServer = softwareSystem "MLflow Tracking Server" "Experiment tracking, prompt management" "Internal RHOAI"
        feast = softwareSystem "Feature Store (Feast)" "Feature store for ML feature management" "Internal RHOAI"

        s3 = softwareSystem "S3-compatible Storage" "Object storage for data files and model artifacts" "External"

        # Person interactions
        dataScientist -> odhDashboard "Manages notebooks, models, pipelines via browser" "HTTPS/443"
        platformAdmin -> odhDashboard "Configures dashboard, hardware profiles, feature flags" "HTTPS/443"

        # System context relationships
        odhDashboard -> k8sApi "All K8s resource CRUD, watch, RBAC" "HTTPS/6443 + WSS"
        odhDashboard -> openshiftOAuth "User authentication" "OAuth2/HTTPS/443"
        odhDashboard -> thanosQuerier "Prometheus metrics queries" "HTTPS/9092"
        odhDashboard -> dsPipelines "Pipeline run management" "HTTPS/8443"
        odhDashboard -> modelRegistry "Model version and artifact management" "HTTP/8080"
        odhDashboard -> trustyAI "Bias metrics, explainability, evaluations" "HTTP/8080"
        odhDashboard -> kserve "ServingRuntime and InferenceService lifecycle" "via K8s API CRDs"
        odhDashboard -> llamaStack "Gen AI inference, vector stores, RAG" "HTTP/8321"
        odhDashboard -> maasApi "Tier, subscription, policy management" "HTTPS/8443"
        odhDashboard -> mlflowServer "Experiment tracking, prompts" "HTTP/5000"
        odhDashboard -> feast "Feature store status monitoring" "via K8s API CRDs"
        odhDashboard -> s3 "Data file access (AutoML, AutoRAG)" "HTTPS/443"

        # Container relationships
        dataScientist -> kubeRbacProxy "HTTPS requests with Bearer token" "HTTPS/8443"
        kubeRbacProxy -> backend "Validated requests with identity headers" "HTTP/8080"
        backend -> frontend "Serves SPA static files" "HTTP"
        backend -> genAiBff "Module federation proxy" "HTTPS/8143"
        backend -> maasBff "Module federation proxy" "HTTPS/8243"
        backend -> automlBff "Module federation proxy" "HTTPS/8643"
        backend -> autoragBff "Module federation proxy" "HTTPS/8743"
        backend -> evalHubBff "Module federation proxy" "HTTPS/8543"
        backend -> mlflowBff "Module federation proxy" "HTTPS/8343"
        backend -> modelRegBff "Module federation proxy" "HTTPS/8043"
        genAiBff -> maasBff "Inter-BFF token issuance" "HTTPS/8243"

        backend -> k8sApi "REST + WebSocket proxy" "HTTPS/6443"
        backend -> thanosQuerier "Prometheus query proxy" "HTTPS/9092"
        backend -> dsPipelines "Pipeline service proxy" "HTTPS/8443"
        backend -> modelRegistry "Model registry proxy" "HTTP/8080"
        backend -> trustyAI "TrustyAI service proxy" "HTTP/8080"
        genAiBff -> llamaStack "LlamaStack API proxy" "HTTP/8321"
        maasBff -> maasApi "MaaS API proxy" "HTTPS/8443"
        mlflowBff -> mlflowServer "MLflow API proxy" "HTTP/5000"
        automlBff -> dsPipelines "Pipeline execution" "HTTPS/8443"
        automlBff -> s3 "Data file access" "HTTPS/443"
        autoragBff -> llamaStack "Model and vector store listing" "HTTP/8321"
        autoragBff -> s3 "Data file access" "HTTPS/443"
        modelRegBff -> modelRegistry "Model registry API" "HTTP/8080"
        evalHubBff -> trustyAI "Evaluation job management" "HTTP/8080"
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
            element "Software System" {
                background #438DD5
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
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Auth" {
                background #e74c3c
                color #ffffff
            }
            element "Optional" {
                background #8e44ad
                color #ffffff
            }
        }
    }
}

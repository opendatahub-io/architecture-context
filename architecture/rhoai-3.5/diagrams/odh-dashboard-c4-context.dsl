workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, deploys models, runs pipelines, uses AI studio"
        admin = person "Platform Admin" "Manages dashboard configuration, RBAC, connection types"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Red Hat OpenShift AI" {
            frontend = container "React SPA" "User-facing web interface with module federation host and PatternFly UI" "TypeScript/React"
            backend = container "Dashboard Backend" "API gateway proxying K8s API, Prometheus, ML services; serves static frontend" "Node.js/Fastify"
            kubeRbacProxy = container "kube-rbac-proxy" "HTTPS termination and RBAC enforcement proxy" "Go Sidecar"
            coreBff = container "core-bff" "Core API gateway in modular architecture mode" "Go BFF"
            genAiBff = container "gen-ai BFF" "AI studio: LlamaStack chat, vector stores, MCP tools, guardrails" "Go BFF"
            modelRegistryBff = container "model-registry BFF" "Model registry: registered models, versions, artifacts, catalog" "Go BFF"
            maasBff = container "maas BFF" "Model-as-a-Service: API keys, subscriptions, policies" "Go BFF"
            mlflowBff = container "mlflow BFF" "MLflow: experiments, prompts, tracking server proxy" "Go BFF"
            evalHubBff = container "eval-hub BFF" "Evaluation Hub: evaluations, collections, providers" "Go BFF"
            automlBff = container "automl BFF" "AutoML: S3 ops, pipeline runs, AutoGluon orchestration" "Go BFF"
            autoragBff = container "autorag BFF" "AutoRAG: RAG pipeline runs, OGX queries, S3 ops" "Go BFF"
            agentOpsBff = container "agent-ops BFF" "Agent Operations: agent runtime lifecycle, catalog" "Go BFF"
        }

        dashboardOperator = softwareSystem "Dashboard Operator" "Go operator managing Dashboard CR lifecycle, module deployment, RBAC, observability" "Internal"

        rhodsOperator = softwareSystem "rhods-operator" "Platform operator creating Dashboard CR and managing DSC" "Internal"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for all resource operations" "Infrastructure"
        thanos = softwareSystem "Thanos Querier" "Prometheus metrics aggregation" "Infrastructure"
        llamaStack = softwareSystem "LlamaStack / OGX" "Generative AI backend for chat, vector stores, models" "AI Service"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation service" "AI Service"
        mlflowServer = softwareSystem "MLflow Tracking Server" "Experiment and prompt tracking" "AI Service"
        maasApi = softwareSystem "MaaS API" "Model-as-a-Service backend" "AI Service"
        evalHubApi = softwareSystem "EvalHub API" "Model evaluation backend" "AI Service"
        dsPipelines = softwareSystem "DataSciencePipelines" "ML pipeline management" "Internal"
        modelRegistry = softwareSystem "Model Registry" "Model artifact management" "Internal"
        kserve = softwareSystem "KServe" "Model serving platform" "Internal"
        trustyAi = softwareSystem "TrustyAI" "AI explainability and bias metrics" "Internal"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration" "Internal"
        perses = softwareSystem "Perses" "Observability dashboards" "Internal"
        s3 = softwareSystem "S3 Storage" "Object storage for ML artifacts" "External"
        pgvector = softwareSystem "pgvector (PostgreSQL)" "Vector database for gen-ai" "External"

        # User interactions
        dataScientist -> odhDashboard "Uses via browser" "HTTPS/443"
        admin -> odhDashboard "Configures via browser" "HTTPS/443"

        # Operator interactions
        rhodsOperator -> dashboardOperator "Creates Dashboard CR"
        dashboardOperator -> odhDashboard "Manages deployment lifecycle"

        # Dashboard to platform services
        odhDashboard -> k8sApi "All K8s resource operations" "HTTPS/6443"
        odhDashboard -> thanos "Prometheus metrics queries" "HTTPS/9091"
        odhDashboard -> dsPipelines "ML pipeline management" "HTTPS"
        odhDashboard -> modelRegistry "Model artifact management" "HTTP/HTTPS"
        odhDashboard -> kserve "Model serving status" "CRD Watch"
        odhDashboard -> trustyAi "AI explainability" "HTTPS/9443"
        odhDashboard -> perses "Observability dashboards" "HTTP/8080"

        # Dashboard to AI/ML services
        odhDashboard -> llamaStack "Generative AI operations" "HTTP/HTTPS"
        odhDashboard -> nemoGuardrails "Content moderation" "HTTP/HTTPS"
        odhDashboard -> mlflowServer "Experiment tracking" "HTTP/HTTPS"
        odhDashboard -> maasApi "Model-as-a-Service" "HTTPS"
        odhDashboard -> evalHubApi "Model evaluation" "HTTP/HTTPS"
        odhDashboard -> kubeflowPipelines "Pipeline orchestration" "HTTPS"

        # Dashboard to external services
        odhDashboard -> s3 "File storage (AutoML/AutoRAG)" "HTTPS/443"
        odhDashboard -> pgvector "Vector database (gen-ai)" "TCP/5432"

        # Container relationships
        kubeRbacProxy -> backend "Forwards authenticated requests" "HTTP/8080"
        backend -> frontend "Serves static files"
        backend -> coreBff "Core API delegation" "HTTP/4000"
        backend -> genAiBff "Gen AI module proxy" "HTTPS/8143"
        backend -> modelRegistryBff "Model Registry module proxy" "HTTPS/8043"
        backend -> maasBff "MaaS module proxy" "HTTPS/8243"
        backend -> mlflowBff "MLflow module proxy" "HTTPS/8343"
        backend -> evalHubBff "Eval Hub module proxy" "HTTPS/8543"
        backend -> automlBff "AutoML module proxy" "HTTPS/8643"
        backend -> autoragBff "AutoRAG module proxy" "HTTPS/8743"
        backend -> agentOpsBff "Agent Ops module proxy" "HTTPS/8843"
        genAiBff -> maasBff "Inter-BFF: MaaS models" "HTTPS/8243"
        genAiBff -> mlflowBff "Inter-BFF: prompts" "HTTPS/8343"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "AI Service" {
                background #9673a6
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

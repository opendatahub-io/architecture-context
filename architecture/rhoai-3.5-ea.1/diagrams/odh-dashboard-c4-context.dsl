workspace {
    model {
        datascientist = person "Data Scientist" "Creates notebooks, deploys models, runs pipelines, evaluates AI systems"
        platformadmin = person "Platform Admin" "Configures RHOAI platform settings, manages users and resources"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Red Hat OpenShift AI — unified interface for projects, model serving, pipelines, notebooks, and platform configuration" {
            kubeRbacProxy = container "kube-rbac-proxy" "TLS termination, OIDC token validation, K8s RBAC enforcement" "Go Sidecar" "auth"
            backend = container "odh-dashboard Backend" "Core dashboard shell — serves UI, proxies K8s API, manages module federation routing" "Node.js 22 / Fastify 4"
            frontend = container "React Frontend" "PatternFly 6 SPA with Module Federation host, dynamic module loading" "React 18 / TypeScript"
            modelRegistryBFF = container "model-registry-ui BFF" "Model Registry management UI and API proxy" "Go 1.25 BFF + React"
            genAiBFF = container "gen-ai-ui BFF" "GenAI Studio — LLM management, MCP servers, guardrails" "Go 1.25 BFF + React"
            maasBFF = container "maas-ui BFF" "Model-as-a-Service deployment and management" "Go 1.25 BFF + React"
            mlflowBFF = container "mlflow-ui BFF" "MLflow experiment tracking and API proxy" "Go 1.25 BFF + React"
            evalHubBFF = container "eval-hub-ui BFF" "AI evaluation hub for LMEval workflows" "Go 1.24 BFF + React"
            automlBFF = container "automl-ui BFF" "Automated ML pipeline management" "Go 1.24 BFF + React"
            autoragBFF = container "autorag-ui BFF" "Automated RAG pipeline management" "Go 1.24 BFF + React"
        }

        gatewayAPI = softwareSystem "Gateway API" "data-science-gateway — external ingress routing" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for all resource CRUD and CRD operations" "External"
        kserve = softwareSystem "KServe" "Serverless ML model inference platform" "Internal RHOAI"
        notebookController = softwareSystem "Kubeflow Notebook Controller" "Notebook lifecycle management" "Internal RHOAI"
        pipelines = softwareSystem "Kubeflow Pipelines (DS Pipelines)" "ML pipeline orchestration" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model artifact and metadata management" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI fairness, bias metrics, guardrails, evaluation" "Internal RHOAI"
        thanos = softwareSystem "Thanos Querier" "Prometheus metrics aggregation" "External"
        mlflow = softwareSystem "MLflow Operator" "Experiment tracking server" "Internal RHOAI"
        feast = softwareSystem "Feast Operator" "Feature store management" "Internal RHOAI"
        ogx = softwareSystem "OGX Operator" "MCP (Model Context Protocol) server management" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Distributed workload scheduling" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager" "External"
        llamaStack = softwareSystem "Llama Stack" "LLM serving framework" "Internal RHOAI"
        perses = softwareSystem "Perses" "Observability dashboards" "Internal RHOAI"
        rhodsOperator = softwareSystem "RHOAI Operator" "Platform operator (DataScienceCluster, DSCInitialization)" "Internal RHOAI"
        nim = softwareSystem "NVIDIA NIM" "NVIDIA model inference integration" "External"

        datascientist -> odhDashboard "Uses for notebook, model, pipeline, and project management" "HTTPS/443"
        platformadmin -> odhDashboard "Configures platform settings, manages users and resources" "HTTPS/443"

        odhDashboard -> gatewayAPI "Receives traffic via" "HTTPRoute"
        odhDashboard -> k8sAPI "All K8s resource CRUD, CRD watch operations" "HTTPS/6443"
        odhDashboard -> kserve "Manages InferenceService and ServingRuntime CRDs" "K8s API"
        odhDashboard -> notebookController "Creates and manages Notebook CRDs" "K8s API"
        odhDashboard -> pipelines "Proxies pipeline API calls" "HTTPS/8443"
        odhDashboard -> modelRegistry "Proxies model registry API and manages CRDs" "HTTPS"
        odhDashboard -> trustyai "Proxies fairness/bias metrics and manages guardrail CRDs" "HTTPS"
        odhDashboard -> thanos "Queries Prometheus metrics" "HTTPS/9092"
        odhDashboard -> mlflow "Proxies experiment tracking API and watches CRDs" "HTTPS/8443"
        odhDashboard -> feast "Proxies feature store API and watches CRDs" "HTTPS"
        odhDashboard -> ogx "Watches OGXServer CRDs for MCP server management" "K8s API"
        odhDashboard -> kueue "Watches ClusterQueue, LocalQueue, Workload CRDs" "K8s API"
        odhDashboard -> olm "Watches Subscription and CSV CRDs for operator status" "K8s API"
        odhDashboard -> llamaStack "Proxies LLM serving API calls" "HTTP/8321"
        odhDashboard -> perses "Proxies observability dashboard API" "HTTP/8080"
        odhDashboard -> rhodsOperator "Watches DataScienceCluster and DSCInitialization CRDs" "K8s API"
        odhDashboard -> nim "Manages NIM Account CRDs and serving resources" "K8s API"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "auth" {
                background #e74c3c
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

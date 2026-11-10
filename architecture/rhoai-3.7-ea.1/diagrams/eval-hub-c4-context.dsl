workspace "eval-hub" "EvalHub evaluation orchestration service (RHOAI 3.7-ea.1)" {
    model {
        dataScientist = person "Data Scientist" "Submits LLM evaluation jobs via SDK or dashboard"
        aiAssistant = person "AI Assistant User" "Drives evaluations through an MCP-capable assistant"

        evalHub = softwareSystem "EvalHub" "Multi-tenant REST API that catalogs evaluation providers and orchestrates LLM evaluation runs as Kubernetes Jobs" {
            kubeRbacProxy = container "kube-rbac-proxy" "Authenticates callers (TokenReview + SAR), sets X-Tenant / X-User" "Go auth proxy, 8443/TCP HTTPS" "Platform"
            api = container "eval-hub API server" "REST API for jobs, post-processing, collections, providers, logs, status events" "Go, 127.0.0.1:8080/TCP"
            metrics = container "Metrics listener" "Prometheus /metrics, unauthenticated" "Go, 0.0.0.0:8081/TCP"
            k8sRuntime = container "Kubernetes runtime" "Builds ConfigMap, reference Secret, NetworkPolicy and Job per evaluation" "Go plugin"
            storage = container "SQL storage" "Tenant-scoped persistence" "SQLite / PostgreSQL (pgx)"
            catalog = container "Provider / collection catalog" "Built-in evaluation framework and benchmark definitions" "YAML config"
            mcp = container "evalhub-mcp" "MCP server exposing EvalHub tools over stdio / Streamable HTTP / SSE" "Go, 3001/TCP"
            initC = container "eval-runtime-init" "Stages test data from S3, Git or Hugging Face" "Go init container"
            sidecar = container "eval-runtime-sidecar" "Pod-local proxy that injects credentials for adapter traffic" "Go native sidecar, localhost:8080"
            adapter = container "Evaluation adapter" "Runs the benchmark (lm-eval, garak, ragas, lighteval, ...)" "Provider container image" "Internal RHOAI"
        }

        dashboard = softwareSystem "RHOAI Dashboard / eval-hub-sdk" "API consumers" "Internal RHOAI"
        operator = softwareSystem "trustyai-service-operator" "Deploys eval-hub, kube-rbac-proxy, ConfigMap and RBAC" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking and workspaces" "Internal RHOAI"
        hwProfile = softwareSystem "ODH HardwareProfile" "Resource sizing for evaluation Jobs (infrastructure.opendatahub.io/v1)" "Internal RHOAI"
        serviceCa = softwareSystem "OpenShift service-ca" "CA bundle for sidecar to eval-hub TLS" "External"
        k8s = softwareSystem "Kubernetes API" "Jobs, ConfigMaps, Secrets, NetworkPolicies, Pods/logs, Events" "External"
        kueue = softwareSystem "Kueue" "Job queueing via LocalQueue labels" "External"
        postgres = softwareSystem "PostgreSQL" "Persistent storage (SQLite default)" "External"
        otel = softwareSystem "OTLP Collector" "Traces, metrics, logs" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping" "External"
        oci = softwareSystem "OCI Registry" "Evaluation cards and artifacts" "External"
        dataSources = softwareSystem "S3 / Git / Hugging Face" "Test data sources" "External"
        models = softwareSystem "Model / judge endpoints" "Models under evaluation" "External"

        dataScientist -> dashboard "Uses"
        dashboard -> kubeRbacProxy "REST calls" "HTTPS/8443, Bearer token"
        aiAssistant -> mcp "MCP tools" "stdio or HTTP/3001"
        mcp -> kubeRbacProxy "REST calls" "HTTPS, Bearer EVALHUB_TOKEN"
        kubeRbacProxy -> api "Forwards with X-Tenant / X-User" "HTTP/8080 pod-local"
        api -> storage "Reads/writes tenant-scoped records"
        api -> catalog "Loads providers and collections"
        api -> k8sRuntime "Dispatches evaluations"
        storage -> postgres "SQL" "PostgreSQL/5432"
        api -> mlflow "Creates experiments" "HTTPS, Bearer token"
        api -> otel "Exports telemetry" "OTLP gRPC/4317"
        api -> oci "Evaluation cards" "HTTPS/443"
        prometheus -> metrics "Scrapes" "HTTP/8081, no auth"
        k8sRuntime -> k8s "Creates Job, ConfigMap, Secret, NetworkPolicy; reads pod logs" "HTTPS/6443, ServiceAccount"
        k8sRuntime -> hwProfile "Reads HardwareProfiles" "HTTPS/6443"
        k8sRuntime -> kueue "Lists LocalQueues, sets queue labels" "HTTPS/6443"
        initC -> dataSources "Downloads test data" "HTTPS/443"
        adapter -> sidecar "All outbound calls" "HTTP localhost:8080"
        sidecar -> kubeRbacProxy "Status events" "HTTPS, service-ca, Bearer token"
        sidecar -> mlflow "Logs results" "HTTPS, Bearer token"
        sidecar -> oci "Pushes/pulls artifacts" "HTTPS/443, OCI token"
        sidecar -> models "Inference requests" "HTTP/HTTPS, model credentials"
        sidecar -> serviceCa "Trusts CA bundle"
        operator -> evalHub "Deploys and configures"
    }

    views {
        systemContext evalHub "SystemContext" {
            include *
            autoLayout
        }

        container evalHub "Containers" {
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
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Platform" {
                background #f5a623
                color #000000
            }
        }
    }
}

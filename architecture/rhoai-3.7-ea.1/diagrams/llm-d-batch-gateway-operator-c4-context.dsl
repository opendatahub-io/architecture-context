workspace "llm-d-batch-gateway-operator" "C4 context for the llm-d Batch Gateway operator (RHOAI 3.7-ea.1)" {

    model {
        nsAdmin = person "Namespace Admin / Editor" "Creates LLMBatchGateway CRs in a workload namespace"
        apiClient = person "Batch API Client" "Submits OpenAI-compatible batch jobs and files"
        platformAdmin = person "Platform Admin" "Enables batch gateway via DataScienceCluster aigateway.batchGateway"

        batchOperator = softwareSystem "llm-d-batch-gateway-operator" "Reconciles LLMBatchGateway CRs into a full llm-d Batch Gateway deployment by rendering embedded Helm charts and applying them with Server-Side Apply" {
            manager = container "Manager" "Entrypoint: scheme, flags, TLS profile resolution, metrics/health servers, leader election" "Go, controller-runtime v0.23.3"
            reconciler = container "LLMBatchGatewayReconciler" "Validates spec, copies cross-namespace Secret, renders charts, SSA apply, orphan cleanup, status conditions" "Go controller"
            metricsController = container "MetricsController" "Manages operator metrics Service, ServiceMonitor and PrometheusRule alerts" "Go controller"
            helmRenderer = container "HelmRenderer" "Loads and renders charts in memory; no Helm releases" "helm.sh/helm/v3 v3.20.2"
            tlsWatcher = container "SecurityProfileWatcher" "Watches cluster TLS profile and restarts operator on change" "openshift/controller-runtime-common"
            charts = container "Embedded charts" "batch-gateway v0.1.0 and llm-d-async v0.7.0 under /charts" "Helm charts"
        }

        batchGateway = softwareSystem "llm-d Batch Gateway (operand)" "API server (/v1/batches, /v1/files on 8000), processor, GC and async processor deployed per CR" "Internal ODH" {
            apiServer = container "API Server" "OpenAI-compatible Batch and Files API" "8000/TCP HTTP/HTTPS"
            processor = container "Processor" "Batch job processing, enqueues requests" "StatefulSet"
            gc = container "Garbage Collector" "Cleans expired jobs and files" "Deployment"
            asyncProcessor = container "Async Processor" "Dispatches queued requests to inference gateways" "llm-d-async"
        }

        aiGatewayOperator = softwareSystem "ai-gateway-operator" "Parent module operator; deploys this operator from config/base" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform orchestrator; supplies operand image digests via params.env" "Internal ODH"
        inferenceGateway = softwareSystem "llm-d Inference Gateway / EPP" "Model inference targets for batch requests" "Internal ODH"
        platformGateway = softwareSystem "Platform Gateway (Gateway API)" "External exposure of /v1/batches and /v1/files via HTTPRoute; gateway-level auth e.g. MaaS" "Internal ODH"
        monitoring = softwareSystem "Platform Monitoring" "Prometheus in redhat-ods-monitoring / openshift-monitoring" "Internal ODH"

        k8sApi = softwareSystem "Kubernetes API Server" "Watches, SSA, status, TokenReview/SAR" "External"
        openshiftConfig = softwareSystem "OpenShift config API and service-ca" "APIServer TLS security profile; metrics serving certificate" "External"
        certManager = softwareSystem "cert-manager" "Optional: issues API server certificate" "External"
        postgres = softwareSystem "PostgreSQL" "Job metadata; optional SQL async queue" "External"
        s3 = softwareSystem "S3-compatible storage / PVC" "Batch input and output files" "External"
        redis = softwareSystem "Redis / Valkey" "Default async transport (redis-sortedset)" "External"

        # Relationships - people
        platformAdmin -> rhodsOperator "Sets aigateway.batchGateway: Managed"
        nsAdmin -> k8sApi "Creates LLMBatchGateway CR" "HTTPS/6443, user token + RBAC"
        apiClient -> platformGateway "Submits batches and files" "HTTPS/443"

        # Platform chain
        rhodsOperator -> aiGatewayOperator "Deploys"
        aiGatewayOperator -> batchOperator "Deploys (kustomize config/base)"

        # Operator
        batchOperator -> k8sApi "Watches CRs, SSA operand resources, copies Secrets, patches status" "HTTPS/6443, SA token"
        batchOperator -> openshiftConfig "Reads TLS profile; uses service-ca cert" "HTTPS/6443"
        batchOperator -> batchGateway "Deploys and manages lifecycle" "SSA via Kubernetes API"
        batchOperator -> certManager "Creates Certificate (optional)" "SSA"
        batchOperator -> platformGateway "Creates HTTPRoute (optional)" "SSA"
        monitoring -> batchOperator "Scrapes /metrics" "HTTPS/8443, Bearer token"

        # Container-level
        manager -> reconciler "Starts"
        manager -> metricsController "Starts if POD_NAMESPACE set"
        manager -> tlsWatcher "Starts"
        reconciler -> helmRenderer "Renders Helm values"
        helmRenderer -> charts "Loads at startup"
        reconciler -> k8sApi "SSA, orphan delete, status" "HTTPS/6443"
        metricsController -> k8sApi "SSA Service, ServiceMonitor, PrometheusRule" "HTTPS/6443"
        tlsWatcher -> openshiftConfig "Watches APIServer TLS profile"

        # Operand
        platformGateway -> apiServer "Routes /v1/batches, /v1/files" "HTTP/HTTPS 8000"
        apiServer -> postgres "Job metadata" "PostgreSQL/5432"
        apiServer -> s3 "Files" "HTTPS/443"
        processor -> postgres "Job state" "PostgreSQL/5432"
        processor -> redis "Enqueue requests" "Redis/6379"
        gc -> postgres "Cleanup" "PostgreSQL/5432"
        asyncProcessor -> redis "Dequeue requests, write results" "Redis/6379"
        asyncProcessor -> inferenceGateway "Inference requests" "HTTP/HTTPS, optional mTLS, API key"
    }

    views {
        systemContext batchOperator "SystemContext" {
            include *
            autoLayout
        }

        container batchOperator "OperatorContainers" {
            include *
            autoLayout
        }

        container batchGateway "OperandContainers" {
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
                background #6aa9ec
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
        }
    }
}

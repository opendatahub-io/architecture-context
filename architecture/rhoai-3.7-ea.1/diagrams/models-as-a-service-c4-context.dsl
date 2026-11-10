workspace "Models-as-a-Service (RHOAI 3.7-ea.1)" "C4 context and containers for MaaS, generated from architecture/rhoai-3.7-ea.1/models-as-a-service.md" {

    model {
        apiClient = person "API Client" "Calls governed LLM endpoints with an sk-oai API key"
        dataScientist = person "User / Data Scientist" "Manages API keys and subscriptions via dashboard or REST"
        admin = person "Cluster / Tenant Admin" "Creates MaaSModelRef, MaaSAuthPolicy, MaaSSubscription, AITenant, Config"

        maas = softwareSystem "Models-as-a-Service" "Governance layer for model serving: API keys, subscriptions, per-tenant token rate limiting and usage telemetry enforced through Kuadrant policies" {
            controller = container "maas-controller" "Reconciles MaaS CRDs into Kuadrant/Istio/Gateway API/llm-d resources; serves 5 validating webhooks (9443/TCP); deploys maas-api, payload-processing, observability and maas-discovery from embedded kustomize via SSA" "Go, controller-runtime v0.25.2"
            maasApi = container "maas-api" "Per-tenant REST API (models, subscriptions, API keys, /v1/me, Loki proxy) and internal Authorino callbacks (key validation, subscription selection). 8443/TCP HTTPS" "Go, gin v1.12.0"
            discovery = container "maas-discovery" "Optional tenant/gateway discovery API (GET /v1/tenants), TokenReview-authenticated. 8443/TCP HTTPS" "Go"
            cleanup = container "maas-api-cleanup" "CronJob every 15 min and revocation Jobs calling maas-api internal endpoints with SA maas-api-cleanup token" "Kubernetes CronJob / Job (ubi-minimal + curl)"
            database = container "PostgreSQL" "API key store (SHA-256 hashes only), tenant-scoped queries; connection from maas-db-config Secret" "PostgreSQL (external)" "Database"
        }

        rhoaiOperator = softwareSystem "RHOAI Operator" "Deploys maas-controller via DataScienceCluster modelsAsService component" "Internal RHOAI"
        gateway = softwareSystem "maas-default-gateway" "Shared Gateway API gateway in openshift-ingress (gatewayClass openshift-default), 443/TCP HTTPS" "External"
        kuadrant = softwareSystem "Red Hat Connectivity Link (Kuadrant)" "Authorino (authN/authZ) and Limitador (token quotas)" "External"
        istio = softwareSystem "OpenShift Service Mesh / Istio" "DestinationRule, EnvoyFilter, ServiceEntry, Telemetry" "External"
        payloadProcessing = softwareSystem "payload-processing (IPP)" "Envoy ext_proc service on 9004/TCP: body-based routing and API translation" "Internal RHOAI"
        aiGatewayController = softwareSystem "ai-gateway-controller" "inference.opendatahub.io ExternalModel/ExternalProvider, AIGuardrails" "Internal RHOAI"
        kserve = softwareSystem "KServe" "LLMInferenceService model backends" "Internal RHOAI"
        llmd = softwareSystem "llm-d" "InferenceObjective per subscription" "Internal RHOAI"
        dashboard = softwareSystem "odh-dashboard / maas-ui" "UI for API keys and subscriptions" "Internal RHOAI"
        monitoring = softwareSystem "RHOAI Monitoring" "Prometheus in redhat-ods-monitoring" "Internal RHOAI"
        observability = softwareSystem "OpenTelemetry / Loki / Perses" "Usage logs, dashboards" "External"
        k8s = softwareSystem "Kubernetes API" "kube-apiserver 6443/TCP" "External"
        providers = softwareSystem "External LLM Providers" "OpenAI, Anthropic, ... via Istio ServiceEntry" "External"

        # People
        apiClient -> gateway "Inference requests" "HTTPS/443, Bearer sk-oai-..."
        dataScientist -> dashboard "Manages keys and subscriptions"
        dataScientist -> gateway "API key lifecycle /maas-api/v1/api-keys" "HTTPS/443, OpenShift/OIDC token"
        admin -> k8s "Creates MaaS CRs" "kubectl / HTTPS"

        # Lifecycle
        rhoaiOperator -> controller "Deploys"
        controller -> k8s "Watches MaaS CRs; SSA operands; generates policies" "HTTPS/6443, SA token"
        k8s -> controller "Admission webhooks" "HTTPS/443->9443, service-ca TLS"
        controller -> kuadrant "Generates AuthPolicy, TokenRateLimitPolicy, RateLimitPolicy, TelemetryPolicy"
        controller -> istio "Generates DestinationRule, EnvoyFilter, ServiceEntry, Telemetry"
        controller -> gateway "Generates HTTPRoutes"
        controller -> llmd "Generates InferenceObjectives"
        controller -> kserve "Reads LLMInferenceServices"
        controller -> payloadProcessing "Deploys operand into openshift-ingress"
        controller -> aiGatewayController "Reads AIGuardrails; migrates ExternalModel"
        controller -> observability "Deploys OpenTelemetryCollector, Perses dashboards, Loki wiring"
        controller -> maasApi "Deploys per-tenant instance (TenantReconciler)"
        controller -> discovery "Deploys when maas-discovery-enabled=true"
        controller -> cleanup "Creates revocation Jobs on AITenant deletion"

        # Data plane
        gateway -> payloadProcessing "ext_proc ipp-pre (fail-open) / ipp (fail-closed)" "gRPC/9004, TLS skip-verify"
        gateway -> kuadrant "Auth and quota checks" "gRPC"
        kuadrant -> maasApi "Validate API key, select subscription (/internal/v1/...)" "HTTPS/8443, no caller auth (NetworkPolicy)"
        kuadrant -> k8s "TokenReview" "HTTPS/6443"
        gateway -> maasApi "maas-api-route with X-MaaS-* headers" "HTTPS/8443, DR SIMPLE insecureSkipVerify"
        gateway -> kserve "Model inference (Authorization stripped)" "HTTPS/8000 or 443"
        gateway -> providers "External model inference with provider key" "HTTPS/443"
        maasApi -> database "Key storage and lookup" "PostgreSQL/5432, sslmode per URL"
        maasApi -> k8s "Informers, TokenReview, SAR, Secret read" "HTTPS/6443"
        maasApi -> gateway "Model access probes" "HTTPS/443, forwarded Bearer"
        maasApi -> observability "Loki log proxy, OTLP traces" "HTTPS / OTLP"
        cleanup -> maasApi "Cleanup / revocation" "HTTPS/8443, Bearer SA maas-api-cleanup"
        discovery -> k8s "TokenReview, AITenant/Gateway/Route reads" "HTTPS/6443"
        dashboard -> maasApi "Keys / subscriptions REST" "HTTPS/8443"
        monitoring -> maasApi "Scrape metrics" "HTTPS/9090"
        monitoring -> controller "Scrape metrics" "HTTPS/8443"
    }

    views {
        systemContext maas "SystemContext" {
            include *
            autoLayout lr
        }

        container maas "Containers" {
            include *
            autoLayout lr
        }

        styles {
            element "Person" {
                shape person
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
            element "Database" {
                shape cylinder
                background #f5a623
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}

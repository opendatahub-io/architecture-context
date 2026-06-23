workspace {
    model {
        user = person "Data Scientist / Platform Admin" "Creates and deploys OGX server instances via OGXServer CRDs"

        ogxOperator = softwareSystem "OGX Kubernetes Operator" "Manages OGXServer CRD lifecycle — deploys and reconciles OGX server infrastructure on Kubernetes/OpenShift" {
            controller = container "OGXServer Controller" "Watches OGXServer CRs and reconciles Deployments, Services, PVCs, ConfigMaps, NetworkPolicies, HPAs, PDBs, Ingresses" "Go (controller-runtime)"
            webhook = container "Validating Webhook" "Validates OGXServer CRs on create/update — distribution names, provider IDs, model references, adoption annotations" "Go (controller-runtime webhook)" "9443/TCP HTTPS"
            configGenerator = container "Config Generation Pipeline" "Resolves base config from OCI labels, expands typed provider specs, merges overrides, produces content-hashed immutable ConfigMaps" "Go (in-process)"
            kustomizer = container "Kustomize Manifest Renderer" "5-stage plugin chain (Name Prefix → Namespace → Field Mutator → NetworkPolicy Transformer → Autoscaling Handler) renders per-instance K8s manifests" "Go (kustomize/api)"
            legacyAdoption = container "Legacy Adoption Handler" "Migrates PVCs, Services, Ingresses from LlamaStackDistribution CRs to OGXServer instances" "Go"
        }

        ogxModule = softwareSystem "OGX Module" "Scaffolded platform component controller — defines cluster-scoped OGX CRD for platform operator integration (reconciler not yet implemented)" "Scaffolded"

        configgenCLI = softwareSystem "configgen CLI" "Offline config generation and validation tool for testing OGX configuration synthesis without a cluster" "Development Tool"

        # External systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource CRUD, watch, and admission" "External"
        ociRegistry = softwareSystem "OCI Container Registries" "Distribution image label storage for base config resolution" "External"
        platformOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys OGX operator via kustomize overlays" "Internal Platform"
        caBundle = softwareSystem "odh-trusted-ca-bundle" "Platform-provided CA bundle ConfigMap auto-detected and merged into OGX server pods" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via ServiceMonitor/PrometheusRule CRDs" "Internal Platform"

        # OGX Server (managed workload)
        ogxServer = softwareSystem "OGX Server Pods" "Managed OGX GenAI server instances deployed per OGXServer CR" "Managed Workload"

        # External AI/Data services (accessed by OGX Server, not operator)
        aiProviders = softwareSystem "AI Provider APIs" "OpenAI, Azure OpenAI, AWS Bedrock, Google Vertex AI, IBM watsonx.ai, vLLM — inference backends" "External"
        dataStores = softwareSystem "Data Storage Backends" "PostgreSQL (pgvector), Milvus, Qdrant, Redis, S3 — vector I/O, KV, file storage" "External"

        # Relationships - User
        user -> ogxOperator "Creates OGXServer CRs via kubectl" "HTTPS/6443 via K8s API"

        # Relationships - Operator internal
        controller -> webhook "Validates CRs"
        controller -> configGenerator "Generates config"
        controller -> kustomizer "Renders manifests"
        controller -> legacyAdoption "Adopts legacy resources"

        # Relationships - Operator to external
        ogxOperator -> k8sAPI "CRUD on managed resources (Deployments, Services, PVCs, ConfigMaps, etc.)" "HTTPS/6443, TLS 1.2+, SA Bearer token"
        ogxOperator -> ociRegistry "Fetch image manifests and labels for base config resolution" "HTTPS/443, Anonymous"
        ogxOperator -> ogxServer "Status polling — /v1/health, /v1/providers, /v1/version" "HTTP/8321, Plaintext"

        # Relationships - Platform
        platformOperator -> ogxOperator "Deploys via kustomize overlays" "Kustomize manifests"
        caBundle -> ogxOperator "Provides trusted CA certificates" "ConfigMap watch"
        ogxOperator -> prometheus "Creates ServiceMonitor and PrometheusRule resources" "K8s API"

        # Relationships - OGX Server to backends
        ogxServer -> aiProviders "Proxies inference requests to configured AI providers" "HTTPS/443, API keys/IAM"
        ogxServer -> dataStores "Connects to configured storage backends" "TCP/HTTP/gRPC, Various auth"

        # Relationships - K8s API webhook
        k8sAPI -> ogxOperator "Sends admission reviews to validating webhook" "HTTPS/9443, mTLS"
    }

    views {
        systemContext ogxOperator "SystemContext" {
            include *
            autoLayout
        }

        container ogxOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #333333
            }
            element "Managed Workload" {
                background #4a90e2
                color #ffffff
            }
            element "Scaffolded" {
                background #b8d4f0
                color #333333
            }
            element "Development Tool" {
                background #e8e8e8
                color #333333
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

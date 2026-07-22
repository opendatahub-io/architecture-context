workspace {
    model {
        user = person "Data Scientist" "Creates and deploys AI/ML inference stacks using OGXServer CRs"

        ogxOperator = softwareSystem "OGX K8s Operator" "Kubernetes operator that deploys and manages OGX server workloads for generative AI inference, vector I/O, tool runtime, and agentic workflows" {
            rootController = container "OGX Operator Controller" "Manages OGXServer CRs — reconciles Deployments, Services, PVCs, NetworkPolicies, PDBs, HPAs, Ingresses, ConfigMaps, and ServiceMonitors per instance" "Go (controller-runtime)"
            validatingWebhook = container "Validating Webhook" "Validates OGXServer CRs on create/update — distribution name existence, provider ID uniqueness, provider reference integrity, adoption annotation safety" "Admission Webhook (9443/TCP HTTPS)"
            configGenerator = container "Config Generator" "Compiles declarative provider/storage/resource specs into OGX server config.yaml, resolves OCI image labels for distribution defaults" "Go Library (pkg/config)"
            kustomizeRenderer = container "Kustomize Renderer" "Renders per-instance manifests from kustomize bases with Go-based transformer plugins" "Go Library (pkg/deploy)"
            moduleController = container "OGX Module Controller" "Implements ODH/RHOAI platform module contract — watches cluster-scoped OGX CR, deploys root operator manifests, reports component health" "Go (controller-runtime)"
        }

        ogxServer = softwareSystem "OGX Server" "Runtime instance serving AI inference, vector I/O, and tool APIs" "Managed Workload"

        # Platform Dependencies
        platformOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that manages component lifecycle via CRs" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / CMO" "Cluster monitoring for metrics collection" "Internal Platform"
        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "CA certificate ConfigMap for TLS to external providers" "Internal Platform"

        # OpenShift Infrastructure
        openshiftCertSigner = softwareSystem "OpenShift service-serving-cert-signer" "Auto-provisions TLS certificates for Services" "OpenShift Infrastructure"
        certManager = softwareSystem "cert-manager" "Certificate provisioning on vanilla Kubernetes" "External Infrastructure"
        openshiftAPIServer = softwareSystem "OpenShift APIServer CR" "Cluster TLS security profile configuration" "OpenShift Infrastructure"

        # External AI/ML Providers
        vllm = softwareSystem "vLLM" "Local/remote inference engine" "External Provider"
        openai = softwareSystem "OpenAI API" "Cloud inference provider" "External Provider"
        azureOpenAI = softwareSystem "Azure OpenAI" "Cloud inference provider" "External Provider"
        awsBedrock = softwareSystem "AWS Bedrock" "Cloud inference provider" "External Provider"
        vertexAI = softwareSystem "Google Vertex AI" "Cloud inference provider" "External Provider"
        watsonx = softwareSystem "IBM Watsonx" "Cloud inference provider" "External Provider"

        # Vector I/O
        pgvector = softwareSystem "PostgreSQL (pgvector)" "Vector database for embeddings" "External Provider"
        milvus = softwareSystem "Milvus" "Vector database" "External Provider"
        qdrant = softwareSystem "Qdrant" "Vector database" "External Provider"

        # Tool Runtime
        braveSearch = softwareSystem "Brave Search API" "Web search tool" "External Provider"
        tavily = softwareSystem "Tavily Search API" "Web search tool" "External Provider"
        s3 = softwareSystem "S3-compatible Storage" "File storage for models and data" "External Provider"

        # Infrastructure
        ociRegistry = softwareSystem "OCI Container Registry" "Stores distribution images with config labels" "External Infrastructure"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "Infrastructure"

        # Relationships - User
        user -> ogxOperator "Creates OGXServer CRs via kubectl/API"

        # Relationships - Internal
        rootController -> validatingWebhook "Delegates CR validation"
        rootController -> configGenerator "Generates OGX server config.yaml"
        rootController -> kustomizeRenderer "Renders per-instance K8s manifests"
        moduleController -> rootController "Deploys via kustomize manifests"

        # Relationships - Platform
        platformOperator -> ogxOperator "Creates OGX CR to enable/disable component"
        ogxOperator -> k8sAPI "CRUD on managed resources, leader election" "HTTPS/443"
        ogxOperator -> ogxServer "Polls /v1/providers, /v1/version for status" "HTTP/8000"
        ogxOperator -> ociRegistry "Fetches image manifests for config resolution" "HTTPS/443"
        ogxOperator -> openshiftAPIServer "Reads cluster TLS security profile"
        prometheus -> ogxOperator "Scrapes operator metrics" "HTTPS/8080"
        prometheus -> ogxServer "Scrapes server metrics" "HTTP/9464"
        ogxOperator -> odhTrustedCA "Auto-detects CA bundle for pod injection"
        openshiftCertSigner -> ogxOperator "Provisions webhook TLS certificate"
        certManager -> ogxOperator "Provisions webhook TLS cert (vanilla K8s)"

        # Relationships - OGX Server to Providers
        ogxServer -> vllm "Inference requests" "HTTP/HTTPS"
        ogxServer -> openai "Inference requests" "HTTPS/443"
        ogxServer -> azureOpenAI "Inference requests" "HTTPS/443"
        ogxServer -> awsBedrock "Inference requests" "HTTPS/443"
        ogxServer -> vertexAI "Inference requests" "HTTPS/443"
        ogxServer -> watsonx "Inference requests" "HTTPS/443"
        ogxServer -> pgvector "Vector operations" "PostgreSQL/5432"
        ogxServer -> milvus "Vector operations" "HTTP/gRPC"
        ogxServer -> qdrant "Vector operations" "HTTP/gRPC"
        ogxServer -> braveSearch "Web search" "HTTPS/443"
        ogxServer -> tavily "Web search" "HTTPS/443"
        ogxServer -> s3 "File storage" "HTTPS/443"
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
            element "External Provider" {
                background #999999
                color #ffffff
            }
            element "External Infrastructure" {
                background #bbbbbb
                color #ffffff
            }
            element "OpenShift Infrastructure" {
                background #cc0000
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #50a0d2
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Managed Workload" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

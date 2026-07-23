workspace {
    model {
        user = person "Data Scientist" "Creates and configures OGXServer instances for ML inference, vector I/O, and tool runtimes"

        ogxOperator = softwareSystem "OGX K8s Operator" "Kubernetes operator managing OGX AI server deployments with declarative provider configuration" {
            operatorController = container "OGX Operator Controller" "Watches OGXServer CRs, reconciles Deployments, Services, NetworkPolicy, HPA, PDB, PVC, monitoring" "Go Operator (controller-runtime)"
            validatingWebhook = container "Validating Webhook" "Validates OGXServer CRs: distribution names, provider ID uniqueness, model-provider references" "Go Admission Webhook"
            configGenerator = container "Config Generator" "Offline config.yaml generation from OGXServer CR specs" "Go CLI"
            ogxModule = container "OGX Module" "Platform integration controller; deploys OGX Operator via kustomize within RHOAI/ODH" "Go Operator (controller-runtime)"
        }

        ogxServer = softwareSystem "OGX Server" "OGX distribution server instances (inference, vector I/O, tool runtime, file storage)" "Managed Pod"

        platformOperator = softwareSystem "RHOAI / ODH Platform Operator" "Manages platform component lifecycle (rhods-operator / opendatahub-operator)" "Internal RHOAI"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Provides Deployer, GarbageCollector, status management for platform integration" "Internal RHOAI"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, CRD watches, leader election" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Container image registry; provides OCI image labels for base config resolution" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate issuance and rotation for webhook" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor and recording rules via PrometheusRule" "External"

        inferenceProviders = softwareSystem "External Inference Providers" "vLLM, OpenAI, Azure, Bedrock, VertexAI, Watsonx inference endpoints" "External"
        vectorDatabases = softwareSystem "Vector Databases" "PGVector, Milvus, Qdrant for vector I/O operations" "External"
        searchAPIs = softwareSystem "Search APIs" "Brave Search, Tavily for tool runtime integrations" "External"
        s3Storage = softwareSystem "S3 / S3-Compatible Storage" "File storage backend for OGX server pods" "External"
        postgresql = softwareSystem "PostgreSQL" "Optional SQL storage backend" "External"
        redis = softwareSystem "Redis" "Optional KV storage backend" "External"

        // User interactions
        user -> ogxOperator "Creates OGXServer CR via kubectl" "HTTPS/6443"

        // Platform integration
        platformOperator -> ogxOperator "Creates OGX platform CR to enable component" "HTTPS/6443"
        ogxOperator -> odhPlatformUtils "Uses Deployer, GarbageCollector, status management" "Go library"

        // Operator → infrastructure
        ogxOperator -> k8sAPI "CRD watches, resource CRUD, leader election" "HTTPS/6443 TLS 1.2+"
        ogxOperator -> ociRegistry "Fetches OCI image labels for base config" "HTTPS/443"
        ogxOperator -> ogxServer "Health checks, status polling" "HTTP/configurable"

        // OGX Server → external services
        ogxServer -> inferenceProviders "Inference API calls" "HTTPS/443 API Key"
        ogxServer -> vectorDatabases "Vector I/O operations" "TCP/configurable"
        ogxServer -> searchAPIs "Tool runtime searches" "HTTPS/443 API Key"
        ogxServer -> s3Storage "File storage operations" "HTTPS/443 IAM"
        ogxServer -> postgresql "SQL storage" "TCP/5432"
        ogxServer -> redis "KV storage" "TCP/6379"

        // Monitoring
        prometheus -> ogxServer "Scrapes metrics" "HTTP/9464 ServiceMonitor"
        prometheus -> ogxOperator "Scrapes operator metrics" "HTTP/8080 TLS"
        certManager -> ogxOperator "Issues webhook TLS certificates" "TLS"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Managed Pod" {
                background #4a90e2
                color #ffffff
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

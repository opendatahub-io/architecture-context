workspace {
    model {
        user = person "Data Scientist / Admin" "Creates and manages OGXServer custom resources for AI inference"

        ogxOperator = softwareSystem "OGX K8s Operator" "Kubernetes operator that reconciles OGXServer CRs into managed AI inference server deployments" {
            controller = container "OGX Controller" "Reconciles OGXServer CRs, manages full lifecycle of inference server resources" "Go (controller-runtime)"
            webhook = container "Validating Webhook" "Validates OGXServer create/update: distribution, provider IDs, references" "Go (9443/TCP HTTPS)"
            kustomizeEngine = container "Kustomize Render Engine" "In-process manifest rendering with transformer plugins (name prefix, namespace, field mutations, NetworkPolicy)" "Go (kustomize/api)"
            adoptionReconciler = container "Legacy Adoption Reconciler" "Migrates LlamaStackDistribution v1alpha1 resources to OGXServer v1beta1" "Go"
        }

        ogxServer = softwareSystem "OGX Server" "AI inference server pods created and managed by the operator" "Managed"

        # Control Plane
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for CR reconciliation and resource management" "Infrastructure"

        # Platform
        platformOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys OGX K8s Operator via kustomize overlays" "Internal Platform"
        odhCABundle = softwareSystem "ODH Trusted CA Bundle" "ConfigMap providing custom CA certificates for managed pods" "Internal Platform"
        certSigner = softwareSystem "OpenShift service-serving-cert-signer" "Auto-generates TLS certificates for webhook service" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "Infrastructure"

        # AI Provider Backends (External)
        vllm = softwareSystem "vLLM" "Remote inference provider for large language models" "External AI Provider"
        openai = softwareSystem "OpenAI API" "Remote inference provider" "External AI Provider"
        azure = softwareSystem "Azure OpenAI" "Remote inference provider" "External AI Provider"
        bedrock = softwareSystem "AWS Bedrock" "Remote inference provider" "External AI Provider"
        vertexai = softwareSystem "Google Vertex AI" "Remote inference provider" "External AI Provider"
        watsonx = softwareSystem "IBM watsonx" "Remote inference provider" "External AI Provider"

        # Vector Databases
        pgvector = softwareSystem "PGVector" "Vector database for vector_io provider" "External Database"
        milvus = softwareSystem "Milvus" "Vector database for vector_io provider" "External Database"
        qdrant = softwareSystem "Qdrant" "Vector database for vector_io provider" "External Database"

        # Storage
        s3 = softwareSystem "S3-Compatible Storage" "Files provider storage for model artifacts" "External Storage"

        # Relationships - User
        user -> ogxOperator "Creates OGXServer CRs via kubectl"
        user -> ogxServer "Sends inference requests"

        # Relationships - Operator internal
        controller -> kustomizeEngine "Renders manifests"
        controller -> adoptionReconciler "Delegates legacy migration"
        controller -> webhook "Registers validating webhook"

        # Relationships - Operator to infrastructure
        ogxOperator -> k8sAPI "Watches CRs, creates/updates/deletes managed resources" "HTTPS/443"
        ogxOperator -> ogxServer "Health probes, version/provider queries" "HTTP/8321"
        ogxOperator -> odhCABundle "Reads CA certificates for injection" "ConfigMap watch"

        # Relationships - Platform
        platformOperator -> ogxOperator "Deploys via kustomize overlays (RHOAI/ODH)"
        certSigner -> ogxOperator "Generates webhook TLS certificate"
        prometheus -> ogxOperator "Scrapes metrics" "HTTPS/8443"

        # Relationships - OGX Server to backends
        ogxServer -> vllm "Inference requests" "HTTP/HTTPS"
        ogxServer -> openai "Inference requests" "HTTPS/443"
        ogxServer -> azure "Inference requests" "HTTPS/443"
        ogxServer -> bedrock "Inference requests" "HTTPS/443"
        ogxServer -> vertexai "Inference requests" "HTTPS/443"
        ogxServer -> watsonx "Inference requests" "HTTPS"
        ogxServer -> pgvector "Vector operations" "TCP"
        ogxServer -> milvus "Vector operations" "HTTP/gRPC"
        ogxServer -> qdrant "Vector operations" "HTTP/gRPC"
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
            element "External AI Provider" {
                background #999999
                color #ffffff
            }
            element "External Database" {
                background #b0b0b0
                color #ffffff
            }
            element "External Storage" {
                background #f5a623
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #dae8fc
                color #333333
            }
            element "Managed" {
                background #d5e8d4
                color #333333
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}

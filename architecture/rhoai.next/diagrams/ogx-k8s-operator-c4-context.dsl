workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages OGXServer instances for AI inference"
        platformAdmin = person "Platform Admin" "Deploys and configures the OGX K8s Operator"

        ogxOperator = softwareSystem "OGX K8s Operator" "Kubernetes operator managing OGX AI distribution server lifecycle on OpenShift/Kubernetes" {
            controller = container "OGXServerReconciler" "Primary reconcile loop for OGXServer CRs; creates/updates Deployments, Services, PVCs, NetworkPolicies, HPAs, PDBs, RoleBindings" "Go (controller-runtime)"
            webhook = container "OGXServerValidator" "Validates OGXServer create/update: distribution name, provider ID uniqueness, provider references, adoption safety" "Go Webhook Server"
            kustomizePipeline = container "Kustomize Pipeline" "Embedded kustomize engine with Go plugins for namespace injection, name prefixing, field mutation, NetworkPolicy transformation" "kustomize/api"
            legacyAdoption = container "Legacy Adoption Controller" "Transfers ownership of LlamaStackDistribution (v1alpha1) PVCs, Services, Ingresses to OGXServer (v1beta1)" "Go"

            controller -> kustomizePipeline "Renders manifests"
            controller -> legacyAdoption "Triggers adoption"
        }

        ogxServer = softwareSystem "OGX Server Instance" "AI distribution server providing inference, vector I/O, tool runtime, and file storage APIs" {
            serverPod = container "OGX Server Pod" "Deployed OGX distribution image (starter, remote-vllm, meta-reference-gpu, postgres-demo)" "Container 8321/TCP"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane for resource management" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhook" "External"
        containerRegistries = softwareSystem "Container Registries" "Image reference validation and distribution image pulls" "External"

        // AI Provider Backends (accessed by OGX Server)
        vllm = softwareSystem "vLLM" "High-performance LLM inference engine" "External"
        openai = softwareSystem "OpenAI API" "OpenAI-compatible inference endpoint" "External"
        azure = softwareSystem "Azure OpenAI" "Azure-hosted OpenAI inference" "External"
        bedrock = softwareSystem "AWS Bedrock" "AWS managed AI inference" "External"
        watsonx = softwareSystem "IBM watsonx" "IBM AI platform inference" "External"

        // Vector I/O backends
        pgvector = softwareSystem "pgvector" "PostgreSQL vector database extension" "External"
        milvus = softwareSystem "Milvus" "Vector similarity search engine" "External"
        qdrant = softwareSystem "Qdrant" "Vector database" "External"

        // Platform operators
        platformOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys this operator as a managed component" "Internal Platform"

        // Configuration
        odhTrustedCA = softwareSystem "odh-trusted-ca-bundle" "Platform-injected CA certificate bundle" "Internal Platform"
        operatorConfig = softwareSystem "ogx-operator-config" "Operator-level image mapping overrides" "Internal Platform"

        // Relationships
        dataScientist -> ogxOperator "Creates OGXServer CRs via kubectl" "HTTPS/443"
        platformAdmin -> ogxOperator "Deploys and configures operator" "HTTPS/443"
        platformOperator -> ogxOperator "Deploys as managed component" "CRD deployment"

        ogxOperator -> k8sAPI "CRUD on managed resources (Deployments, Services, PVCs, etc.)" "HTTPS/443 TLS 1.2+"
        ogxOperator -> ogxServer "Health checks, provider info, version polling" "HTTP/8321"
        ogxOperator -> containerRegistries "Image reference validation" "HTTPS/443 TLS 1.2+"
        ogxOperator -> certManager "Optional TLS cert provisioning for webhook" "CRD"
        ogxOperator -> odhTrustedCA "Auto-detected CA certificates" "API Read HTTPS"
        ogxOperator -> operatorConfig "Image mapping overrides" "API Read HTTPS"

        ogxServer -> vllm "Inference requests" "HTTPS"
        ogxServer -> openai "Inference requests" "HTTPS"
        ogxServer -> azure "Inference requests" "HTTPS"
        ogxServer -> bedrock "Inference requests" "HTTPS"
        ogxServer -> watsonx "Inference requests" "HTTPS"
        ogxServer -> pgvector "Vector I/O" "TCP"
        ogxServer -> milvus "Vector I/O" "gRPC"
        ogxServer -> qdrant "Vector I/O" "gRPC/HTTPS"

        k8sAPI -> ogxOperator "Webhook validation callbacks" "HTTPS/443"
    }

    views {
        systemContext ogxOperator "SystemContext" {
            include *
            autoLayout
        }

        container ogxOperator "OperatorContainers" {
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
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys OGX AI inference servers via OGXServer CRDs"
        client = person "Inference Client" "Sends inference requests to deployed OGX servers"

        ogxOperator = softwareSystem "OGX K8s Operator" "Kubernetes operator managing lifecycle of OGX AI inference servers including deployment, networking, autoscaling, and provider configuration" {
            controller = container "OGXServer Reconciler" "Watches OGXServer CRs, reconciles desired state by managing Deployments, Services, NetworkPolicies, PVCs, HPAs, PDBs, Ingresses, ConfigMaps" "Go (controller-runtime)"
            webhook = container "Validating Webhook" "Validates OGXServer CRs: distribution name, provider ID uniqueness, provider references, adoption annotations" "Go (9443/TCP HTTPS)"
            kustomizeEngine = container "Kustomize Engine" "Renders deployment manifests from base templates using embedded kustomize with Go plugin pipeline (namespace, name-prefix, field mutation, network policy transform)" "Go Library"
            legacyAdoption = container "Legacy Adoption System" "Migrates LlamaStackDistribution (v1alpha1) resources to OGXServer (v1beta1) with zero-downtime PVC, Service, and Ingress adoption" "Go"
        }

        ogxServer = softwareSystem "OGX Server Instance" "Deployed AI inference server pods managed by the operator, configured with provider settings via config.yaml" {
            serverPod = container "OGX Server Pod" "Serves AI inference requests, connects to configured providers" "Container (configurable distribution image)"
            service = container "Instance Service" "ClusterIP service exposing OGX server on configurable port (default 8321)" "Kubernetes Service"
            ingress = container "Instance Ingress" "Optional external access via Kubernetes Ingress" "Kubernetes Ingress"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Provides API for cluster resource management" "External"
        certManager = softwareSystem "cert-manager / OpenShift service-ca" "Provisions and auto-rotates TLS certificates for webhook server" "External"
        prometheus = softwareSystem "Prometheus" "Monitors operator metrics via ServiceMonitor and kube-rbac-proxy" "External"

        openai = softwareSystem "OpenAI API" "Remote inference provider" "External"
        azure = softwareSystem "Azure OpenAI" "Remote inference provider" "External"
        bedrock = softwareSystem "AWS Bedrock" "Remote inference provider" "External"
        vertexai = softwareSystem "Google VertexAI" "Remote inference provider" "External"
        watsonx = softwareSystem "IBM Watsonx" "Remote inference provider" "External"
        vllm = softwareSystem "vLLM" "Remote/local inference provider" "External"

        pgvector = softwareSystem "PGVector / Milvus / Qdrant" "Vector I/O providers for similarity search and retrieval" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Files provider for model artifacts and data" "External"

        odhCaBundle = softwareSystem "ODH Trusted CA Bundle" "Platform-level CA certificate bundle for outbound TLS trust" "Internal Platform"
        openshiftSCC = softwareSystem "OpenShift SCC" "Security Context Constraints (anyuid) for managed server init containers" "Internal Platform"

        # User interactions
        user -> ogxOperator "Creates OGXServer CRs via kubectl" "HTTPS/443"
        client -> ogxServer "Sends inference requests" "HTTP(S)/8321"

        # Operator internal
        controller -> webhook "Validates CRs"
        controller -> kustomizeEngine "Renders manifests"
        controller -> legacyAdoption "Migrates legacy resources"

        # Operator → K8s
        ogxOperator -> kubernetesAPI "CRUD for Deployments, Services, NetworkPolicies, PVCs, HPAs, PDBs, Ingresses, ConfigMaps" "HTTPS/443"
        kubernetesAPI -> ogxOperator "Watch events for OGXServer CRs and ConfigMaps" "HTTPS/443"

        # Operator → OGX Server
        ogxOperator -> ogxServer "Health checks: /v1/providers, /v1/version" "HTTP/8321"

        # OGX Server → External providers
        ogxServer -> openai "Inference requests" "HTTPS/443 (API key)"
        ogxServer -> azure "Inference requests" "HTTPS/443 (API key)"
        ogxServer -> bedrock "Inference requests" "HTTPS/443 (AWS IAM)"
        ogxServer -> vertexai "Inference requests" "HTTPS/443 (SA JSON)"
        ogxServer -> watsonx "Inference requests" "HTTPS/443 (API key)"
        ogxServer -> vllm "Inference requests" "HTTP(S) (configurable)"
        ogxServer -> pgvector "Vector I/O queries" "TCP (password/token)"
        ogxServer -> s3 "File storage access" "HTTPS/443 (AWS creds)"

        # Supporting services
        certManager -> ogxOperator "Provisions webhook TLS certificates"
        prometheus -> ogxOperator "Scrapes /metrics" "HTTPS/8443"
        ogxOperator -> odhCaBundle "Reads CA bundle ConfigMap for outbound TLS trust"
        ogxOperator -> openshiftSCC "Creates per-instance RoleBinding for anyuid SCC"
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

        container ogxServer "ServerContainers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

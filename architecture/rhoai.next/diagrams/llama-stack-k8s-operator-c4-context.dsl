workspace {
    model {
        user = person "Data Scientist" "Creates and manages OGX AI inference servers via OGXServer custom resources"
        admin = person "Platform Admin" "Deploys and configures the OGX K8s Operator on the cluster"

        ogxOperator = softwareSystem "OGX K8s Operator" "Kubernetes operator that manages the lifecycle of OGX AI inference servers including deployment, networking, autoscaling, and provider configuration" {
            controller = container "OGXServer Reconciler" "Watches OGXServer CRs, reconciles desired state by creating/managing K8s resources" "Go (controller-runtime)"
            webhook = container "Validating Webhook" "Validates OGXServer CRs on create/update: distribution name, provider ID uniqueness, provider references" "Go Admission Webhook"
            kustomizeEngine = container "Kustomize Engine" "Renders deployment manifests from base templates using embedded kustomize with Go plugin pipeline" "Go Library"
            legacyAdoption = container "Legacy Adoption System" "Migrates resources from v1alpha1 LlamaStackDistribution CRD to v1beta1 OGXServer CRD" "Go"
            kubeRBACProxy = container "kube-rbac-proxy" "Proxies /metrics endpoint with RBAC enforcement via TokenReview and SubjectAccessReview" "Sidecar Container"
        }

        ogxServer = softwareSystem "OGX Server" "AI inference server instances deployed and managed by the operator" "Managed"

        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API for resource management" "External"
        certManager = softwareSystem "cert-manager / OpenShift service-ca" "TLS certificate provisioning for webhook server" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        odhCABundle = softwareSystem "ODH Trusted CA Bundle" "Platform CA bundle ConfigMap for outbound TLS trust" "Internal RHOAI"
        openshiftSCC = softwareSystem "OpenShift SCC" "Security Context Constraints for pod security" "External"

        openAI = softwareSystem "OpenAI API" "Remote inference provider" "External"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote inference provider" "External"
        awsBedrock = softwareSystem "AWS Bedrock" "Remote inference provider" "External"
        vertexAI = softwareSystem "Google VertexAI" "Remote inference provider" "External"
        watsonx = softwareSystem "IBM Watsonx" "Remote inference provider" "External"
        vLLM = softwareSystem "vLLM" "Remote inference endpoint" "External"

        pgvector = softwareSystem "PGVector" "Vector database for Vector I/O" "External"
        milvus = softwareSystem "Milvus" "Vector database for Vector I/O" "External"
        qdrant = softwareSystem "Qdrant" "Vector database for Vector I/O" "External"

        s3 = softwareSystem "S3-compatible Storage" "Model artifacts and file storage" "External"
        containerRegistry = softwareSystem "Container Registry" "OGX distribution images (docker.io, quay.io)" "External"

        # System-level relationships
        user -> ogxOperator "Creates OGXServer CRs via kubectl" "HTTPS/443"
        admin -> ogxOperator "Deploys and configures operator" "kubectl/OLM"
        user -> ogxServer "Sends inference requests" "HTTP(S)/{port}"

        ogxOperator -> k8sAPI "CRUD for Deployments, Services, NetworkPolicies, PVCs, HPAs, PDBs, Ingresses, ConfigMaps" "HTTPS/443 SA token"
        ogxOperator -> ogxServer "Health checks: /v1/providers, /v1/version" "HTTP/8321"
        ogxOperator -> odhCABundle "Reads CA bundle for outbound TLS trust" "ConfigMap"

        certManager -> ogxOperator "Provisions webhook TLS certificates" "Certificate CR / annotation"
        prometheus -> ogxOperator "Scrapes /metrics endpoint" "HTTPS/8443"

        ogxServer -> openAI "Remote inference" "HTTPS/443 API key"
        ogxServer -> azureOpenAI "Remote inference" "HTTPS/443 API key"
        ogxServer -> awsBedrock "Remote inference" "HTTPS/443 IAM creds"
        ogxServer -> vertexAI "Remote inference" "HTTPS/443 SA JSON"
        ogxServer -> watsonx "Remote inference" "HTTPS/443 API key"
        ogxServer -> vLLM "Remote inference" "HTTP(S) configurable"
        ogxServer -> pgvector "Vector I/O" "TCP password"
        ogxServer -> milvus "Vector I/O" "TCP token"
        ogxServer -> qdrant "Vector I/O" "TCP token"
        ogxServer -> s3 "File storage" "HTTPS/443 AWS creds"

        ogxOperator -> containerRegistry "Pulls distribution images" "HTTPS/443"

        # Container-level relationships
        controller -> webhook "Validates CRs via" "Internal"
        controller -> kustomizeEngine "Renders manifests via" "Internal"
        controller -> legacyAdoption "Triggers migration via" "Internal"
        controller -> k8sAPI "Creates/updates K8s resources" "HTTPS/443"
        controller -> ogxServer "Checks health and version" "HTTP/8321"
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
            element "Managed" {
                background #50c878
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "Data Scientist / Platform User" "Creates and manages OGXServer instances for AI inference"
        admin = person "Platform Admin" "Manages RHOAI platform and operator deployment"

        ogxOperator = softwareSystem "OGX K8s Operator" "Manages lifecycle of OGX AI inference servers on Kubernetes" {
            controller = container "OGXServer Reconciler" "Watches OGXServer CRs and reconciles desired state by managing Deployments, Services, NetworkPolicies, PVCs, HPAs, PDBs, Ingresses, ConfigMaps" "Go (controller-runtime)"
            webhook = container "Validating Webhook" "Validates OGXServer CRs on create/update: distribution name, provider ID uniqueness, provider references, adoption annotations" "HTTPS/9443"
            kustomizeEngine = container "Kustomize Engine" "Renders deployment manifests from base templates using embedded kustomize with Go plugin pipeline (namespace, name prefix, field mutation, network policy transformation)" "Internal Library"
            legacyAdoption = container "Legacy Adoption System" "Migrates v1alpha1 LlamaStackDistribution resources to v1beta1 OGXServer with zero-downtime PVC, Service, and Ingress transfer" "Go"
        }

        ogxServer = softwareSystem "OGX Server Instance" "AI inference server deployed and managed by the operator" {
            serverPod = container "OGX Server Pod" "Serves AI inference requests, routes to configured providers" "Container (OGX distribution image)"
            serverService = container "Instance Service" "ClusterIP service for internal access" "Kubernetes Service"
            serverIngress = container "Instance Ingress" "Optional external access via Kubernetes Ingress" "Kubernetes Ingress"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        certManager = softwareSystem "cert-manager / OpenShift service-ca" "TLS certificate provisioning for webhook server" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        openShiftSCC = softwareSystem "OpenShift SCC" "Security Context Constraints for pod security" "External"
        odhCABundle = softwareSystem "ODH Trusted CA Bundle" "Platform-managed CA certificates for outbound TLS trust" "Internal RHOAI"

        vllm = softwareSystem "vLLM" "Remote inference endpoint" "External Provider"
        openAI = softwareSystem "OpenAI API" "Cloud AI inference service" "External Provider"
        azureOpenAI = softwareSystem "Azure OpenAI" "Microsoft cloud AI inference service" "External Provider"
        awsBedrock = softwareSystem "AWS Bedrock" "Amazon cloud AI inference service" "External Provider"
        vertexAI = softwareSystem "Google VertexAI" "Google cloud AI inference service" "External Provider"
        watsonx = softwareSystem "IBM Watsonx" "IBM cloud AI inference service" "External Provider"
        vectorDB = softwareSystem "Vector Databases" "PGVector, Milvus, Qdrant for vector I/O" "External Provider"
        s3Storage = softwareSystem "S3 Storage" "S3-compatible object storage for files" "External Provider"
        containerRegistry = softwareSystem "Container Registries" "docker.io, quay.io for OGX distribution images" "External"

        # Relationships
        user -> ogxOperator "Creates OGXServer CRs via kubectl" "HTTPS/443"
        admin -> ogxOperator "Deploys and configures operator" "kubectl/OLM"
        user -> ogxServer "Sends inference requests" "HTTP or HTTPS/{port}"

        controller -> kustomizeEngine "Renders manifests" "Internal"
        controller -> legacyAdoption "Triggers migration" "Internal"
        controller -> webhook "Validated by" "Internal"

        ogxOperator -> k8sAPI "CRUD for managed resources" "HTTPS/443"
        ogxOperator -> ogxServer "Health checks, config injection" "HTTP/8321"
        certManager -> ogxOperator "Provisions webhook TLS cert" "Certificate CR"
        prometheus -> ogxOperator "Scrapes /metrics" "HTTPS/8443"
        ogxOperator -> openShiftSCC "Uses anyuid SCC for init containers" "RBAC"
        ogxOperator -> odhCABundle "Reads CA bundle ConfigMap" "K8s API"

        ogxServer -> vllm "Remote inference" "HTTP/HTTPS"
        ogxServer -> openAI "Remote inference" "HTTPS/443, API key"
        ogxServer -> azureOpenAI "Remote inference" "HTTPS/443, API key"
        ogxServer -> awsBedrock "Remote inference" "HTTPS/443, AWS IAM"
        ogxServer -> vertexAI "Remote inference" "HTTPS/443, SA JSON"
        ogxServer -> watsonx "Remote inference" "HTTPS/443, API key"
        ogxServer -> vectorDB "Vector I/O" "TCP, configurable"
        ogxServer -> s3Storage "File storage" "HTTPS/443, AWS creds"
        ogxServer -> containerRegistry "Pulls distribution images" "HTTPS/443"
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
            element "External Provider" {
                background #d6b656
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #333333
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

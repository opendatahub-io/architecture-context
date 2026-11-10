workspace "ogx-k8s-operator" "C4 context for the OGX Kubernetes operator (RHOAI 3.7-ea.1)" {
    model {
        user = person "Data Scientist / Platform User" "Creates OGXServer resources via kubectl or GitOps"
        endUser = person "End User" "Calls OGX GenAI APIs via Praxis or external Ingress"

        ogx = softwareSystem "ogx-k8s-operator" "Deploys and manages OGX (Open GenAI Stack, formerly Llama Stack) servers from OGXServer CRs" {
            module = container "ogx-module" "ODH/RHOAI module operator; reconciles cluster-scoped OGX CR and installs the root operator from bundled manifests" "Go controller-runtime"
            operator = container "OGX Operator" "Reconciles ogx.io/v1beta1 OGXServer; renders kustomize base, generates config.yaml, polls server status" "Go controller-runtime"
            webhook = container "Validating Webhook" "vogxserver.kb.io on 9443/TCP; validates OGXServer CREATE/UPDATE, Praxis warnings" "Go admission webhook"
            configgen = container "Config Generator" "Resolves base config from CR ConfigMap or OCI labels; emits hashed ConfigMap and env mappings" "Go library"
            server = container "OGX Server (managed workload)" "Per-OGXServer Deployment exposing 8321/TCP HTTP" "odh-ogx-core image"
            migration = container "Praxis Migration Job" "One-shot migration of Responses/Conversations data to Praxis DB" "Kubernetes Job"
        }

        platformOp = softwareSystem "ODH/RHOAI Platform Operator" "Creates OGX CR default-ogx and deploys ogx-module" "Internal ODH"
        praxis = softwareSystem "Praxis Gateway" "Front door for OGX in Praxis mode; supplies x-user-id/x-tenant-id headers" "Internal ODH"
        k8s = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        ocpConfig = softwareSystem "OpenShift APIServer config / service-ca" "TLS profile, serving certificates, caBundle injection" "External"
        registry = softwareSystem "Container Registries" "docker.io / quay.io; OCI config labels" "External"
        monitoring = softwareSystem "Prometheus / Platform Monitoring" "Scrapes operator and OGX metrics" "Internal ODH"
        ingress = softwareSystem "Ingress Controller" "Edge TLS for legacy external access" "External"
        backends = softwareSystem "Inference Providers / SQL / KV" "Backends configured in spec.providers and spec.storage" "External"

        user -> k8s "Creates OGXServer" "HTTPS/6443"
        platformOp -> k8s "Creates OGX CR" "HTTPS/6443"
        module -> k8s "Watches OGX CR; applies root operator CRD, RBAC, Deployment, webhook" "HTTPS/6443"
        operator -> k8s "Watches OGXServer; manages Deployment, Service, ConfigMap, NetworkPolicy, Ingress, PVC, HPA, PDB, Job" "HTTPS/6443"
        k8s -> webhook "AdmissionReview" "HTTPS/443->9443"
        operator -> configgen "Generates config.yaml"
        configgen -> registry "Fetches OCI config labels (anonymous, HTTP fallback)" "HTTPS/443, HTTP/80"
        operator -> server "Polls /v1/providers, /v1/version" "HTTP/8321"
        operator -> migration "Creates"
        operator -> ocpConfig "Reads TLS profile; uses service-CA certs" "HTTPS/6443"
        module -> ocpConfig "Reads TLS profile" "HTTPS/6443"
        monitoring -> operator "Scrapes /metrics (Bearer -> TokenReview/SAR)" "HTTPS/8443"
        monitoring -> module "Scrapes /metrics (no auth)" "HTTPS/8443"
        endUser -> praxis "Calls GenAI APIs" "HTTPS/443"
        praxis -> server "Forwards with x-user-id/x-tenant-id" "HTTP/8321"
        endUser -> ingress "Legacy external access" "HTTPS/443"
        ingress -> server "Forwards (edge TLS terminated)" "HTTP/8321"
        server -> backends "Inference and storage calls" "HTTPS/TCP"
        migration -> praxis "Writes migrated data to Praxis DB"
    }

    views {
        systemContext ogx "SystemContext" {
            include *
            autoLayout
        }

        container ogx "Containers" {
            include *
            autoLayout
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
            element "External" {
                background #999999
            }
            element "Internal ODH" {
                background #7ed321
            }
        }
    }
}

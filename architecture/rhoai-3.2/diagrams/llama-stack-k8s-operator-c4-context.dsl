workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages Llama Stack deployments for LLM inference and agents"

        llamaStackOperator = softwareSystem "Llama Stack K8s Operator" "Kubernetes operator that automates deployment and lifecycle management of Llama Stack servers" {
            controller = container "LlamaStackDistribution Controller" "Reconciles LlamaStackDistribution CRs and manages server lifecycle" "Go Operator"
            clusterInfo = container "Cluster Info Manager" "Manages distribution images, feature flags, and ConfigMap overrides" "Go Service"
            kustomizer = container "Kustomizer Engine" "Renders Kubernetes manifests from kustomize templates" "Go Service"
            resourceHelper = container "Resource Helper" "Constructs Kubernetes resources (Deployments, Services, HPAs, etc.)" "Go Service"
            networkPolicyMgr = container "Network Policy Manager" "Creates and manages NetworkPolicy resources (feature-flagged)" "Go Service"
            caBundleMgr = container "CA Bundle Manager" "Detects and manages TLS CA certificate bundles" "Go Service"
            metricsExporter = container "Metrics Exporter" "Exposes Prometheus metrics via kube-rbac-proxy on port 8443" "Go Service"
            healthProbe = container "Health Probe Handler" "Provides health and readiness endpoints on port 8081" "Go Service"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "Standardized inference and agent platform for Llama models" {
            description "Created and managed by the operator"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        controllerRuntime = softwareSystem "controller-runtime" "Kubernetes controller framework and reconciliation engine" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "RBAC authorization proxy for metrics endpoints" "External"
        kustomize = softwareSystem "Kustomize" "Kubernetes manifest rendering and transformation tool" "External"

        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management and mTLS (optional)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning (optional)" "External"

        dashboard = softwareSystem "ODH Dashboard" "User interface for managing RHOAI components" "Internal ODH"
        trustedCA = softwareSystem "ODH Trusted CA Bundle" "ConfigMap containing trusted CA certificates for secure connections" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning information" "Internal ODH"

        vllm = softwareSystem "vLLM Inference Server" "High-throughput LLM inference backend" "External"
        ollama = softwareSystem "Ollama Inference Server" "Local LLM inference backend" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        containerRegistry = softwareSystem "Container Registry" "Stores Llama Stack distribution container images (quay.io, docker.io)" "External"

        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflows (optional integration)" "Internal ODH"

        # User interactions
        datascientist -> llamaStackOperator "Creates and manages LlamaStackDistribution CRs via kubectl or ODH Dashboard"
        datascientist -> dashboard "Uses UI to deploy Llama Stack servers"
        dashboard -> llamaStackOperator "Creates LlamaStackDistribution CRs via Kubernetes API" "HTTPS/443, TLS 1.3"

        # Operator core functions
        llamaStackOperator -> kubernetes "Watches CRDs, creates/manages Kubernetes resources (Deployments, Services, PVCs, HPAs, PDBs, NetworkPolicies)" "HTTPS/443, TLS 1.3, Bearer Token"
        controller -> controllerRuntime "Uses for reconciliation loop and CRD management"
        controller -> kustomize "Renders manifests with instance-specific transformations"

        # Operator creates and manages Llama Stack servers
        llamaStackOperator -> llamaStackServer "Deploys, configures, and manages lifecycle" "Kubernetes API"

        # Llama Stack server dependencies
        llamaStackServer -> vllm "Calls for remote inference" "HTTP/gRPC 8000/TCP, API Keys"
        llamaStackServer -> ollama "Calls for local inference" "HTTP 11434/TCP"
        llamaStackServer -> huggingface "Downloads models and datasets" "HTTPS/443, TLS 1.2+, HF Token"
        llamaStackServer -> modelRegistry "Queries model metadata (optional)" "gRPC"
        llamaStackServer -> containerRegistry "Pulls distribution images" "HTTPS/443, TLS 1.2+, Registry Credentials"

        # Operator integrations
        llamaStackOperator -> trustedCA "Auto-detects and mounts CA bundle for TLS" "ConfigMap detection"
        llamaStackOperator -> metricsExporter "Exposes metrics"
        metricsExporter -> kubeRBACProxy "Proxies metrics with RBAC authorization" "HTTP/8080 (localhost)"
        prometheus -> kubeRBACProxy "Scrapes metrics" "HTTPS/8443, TLS 1.2+, Bearer Token"

        llamaStackOperator -> certManager "Optional TLS certificate provisioning for user workloads"
        llamaStackOperator -> istio "Optional service mesh integration for mTLS and traffic management"

        dataSciencePipelines -> llamaStackOperator "Auto-deploys models via LlamaStackDistribution CRs (optional)"
    }

    views {
        systemContext llamaStackOperator "SystemContext" {
            include *
            autoLayout lr
        }

        container llamaStackOperator "Containers" {
            include *
            autoLayout tb
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
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

workspace {
    model {
        user = person "ML Engineer / Data Scientist" "Deploys and manages LLM inference workloads on Kubernetes"

        llamaStackOperator = softwareSystem "Llama Stack K8s Operator" "Kubernetes operator that automates deployment and lifecycle management of Llama Stack servers" {
            controllerManager = container "Operator Controller Manager" "Reconciles LlamaStackDistribution CRDs and manages resource lifecycle" "Go 1.24"
            llsdController = container "LlamaStackDistribution Controller" "Watches CRDs, creates Deployments, Services, PVCs, NetworkPolicies, Ingresses" "controller-runtime v0.19.4"
            kustomizeEngine = container "Kustomize-based Deployment Engine" "Dynamically generates Kubernetes manifests from templates" "kustomize kyaml v0.18.1"
            featureFlagsManager = container "Feature Flags Manager" "Controls optional features via ConfigMap" "ConfigMap"
            imageMapper = container "Distribution Image Mapper" "Maps distribution names to container images" "ConfigMap"
        }

        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        kubeAPI = container "Kubernetes API Server" "Cluster control plane API" "External" {
            tags "External"
        }

        inferenceProviders = softwareSystem "Inference Providers" "Backend LLM serving frameworks (Ollama, vLLM, TGI, Bedrock)" "External"
        containerRegistry = softwareSystem "Container Registry" "Stores Llama Stack distribution images (docker.io, quay.io)" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Hosts LLM model weights for download" "External"

        prometheusMonitoring = softwareSystem "OpenShift Monitoring" "Cluster monitoring and metrics collection via Prometheus" "Internal ODH/RHOAI"
        securityContextConstraints = softwareSystem "Security Context Constraints" "OpenShift security policy enforcement (anyuid)" "Internal ODH/RHOAI"

        # Relationships
        user -> llamaStackOperator "Creates LlamaStackDistribution CRs via kubectl/UI"
        user -> k8s "Deploys operator and manages cluster"

        llamaStackOperator -> kubeAPI "Reconciles CRDs, manages resources" "HTTPS/6443, TLS 1.2+, ServiceAccount JWT"
        llamaStackOperator -> inferenceProviders "Deploys and configures" "HTTP/gRPC"
        llamaStackOperator -> containerRegistry "Pulls distribution images" "HTTPS/443, TLS 1.2+"
        llamaStackOperator -> huggingFace "Downloads model weights (vLLM)" "HTTPS/443, TLS 1.2+, HF Token"
        llamaStackOperator -> prometheusMonitoring "Exposes metrics via ServiceMonitor" "HTTPS/8443, TLS, Bearer Token"
        llamaStackOperator -> securityContextConstraints "Requests anyuid SCC for managed pods"

        controllerManager -> llsdController "Manages controller lifecycle"
        llsdController -> kustomizeEngine "Generates manifests"
        llsdController -> featureFlagsManager "Reads configuration"
        llsdController -> imageMapper "Maps distribution images"

        k8s -> kubeAPI "Contains"
    }

    views {
        systemContext llamaStackOperator "SystemContext" {
            include *
            autoLayout
        }

        container llamaStackOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH/RHOAI" {
                background #7ed321
                color #000000
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
                background #f5a623
                color #ffffff
                shape person
            }
        }
    }
}

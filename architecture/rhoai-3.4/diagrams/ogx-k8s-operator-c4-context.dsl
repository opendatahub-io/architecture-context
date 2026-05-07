workspace {
    model {
        user = person "Data Scientist / MLOps Engineer" "Deploys and manages LlamaStack inference servers via LlamaStackDistribution CRs"
        platformAdmin = person "Platform Administrator" "Manages RHOAI/ODH platform, configures operator settings and CA bundles"

        llamaStackOperator = softwareSystem "llama-stack-k8s-operator" "Kubernetes operator managing LlamaStack distribution server deployments, providing lifecycle management for AI inference serving" {
            controller = container "LlamaStackDistribution Controller" "Reconciles LlamaStackDistribution CRs; creates Deployments, Services, Ingresses, NetworkPolicies, PVCs, HPAs, PDBs" "Go (controller-runtime)"
            kustomizePipeline = container "Kustomize Rendering Pipeline" "Transforms embedded base manifests using custom Go plugins (NamePrefix, Namespace, FieldMutator, NetworkPolicyTransformer)" "Go (kustomize/api)"
            caBundleManager = container "CA Bundle Manager" "Gathers, validates (X.509), and concatenates CA certificates from user ConfigMaps and platform trusted CA bundle" "Go (crypto/x509)"
            distributionResolver = container "Distribution Resolver" "Resolves LlamaStack container images from distributions.json, env var overrides, or config overrides" "Go"
        }

        llamaStackServer = softwareSystem "LlamaStack Server" "AI inference server running the Llama Stack framework; deployed as pods by the operator" {
            serverPod = container "LlamaStack Server Pod" "Serves inference requests via Llama Stack API on port 8321" "Python (uvicorn)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, watch events, and leader election" "Platform"
        ingressController = softwareSystem "OpenShift Ingress Controller" "Routes external traffic to cluster services via Ingress resources" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"
        containerRegistry = softwareSystem "Container Registry (quay.io)" "Hosts LlamaStack distribution container images" "External"
        rhoaiOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys the llama-stack-k8s-operator via kustomize overlays" "Internal Platform"
        odhTrustedCA = softwareSystem "odh-trusted-ca-bundle" "Platform-level trusted CA certificate ConfigMap" "Internal Platform"

        # User interactions
        user -> llamaStackOperator "Creates LlamaStackDistribution CRs via kubectl"
        user -> llamaStackServer "Sends inference requests (when Ingress enabled)"
        platformAdmin -> llamaStackOperator "Configures operator settings, CA bundles, feature flags"

        # Operator internal flows
        controller -> kustomizePipeline "Renders Kubernetes manifests"
        controller -> caBundleManager "Manages CA certificate bundles"
        controller -> distributionResolver "Resolves container image references"

        # External interactions
        llamaStackOperator -> k8sAPI "CRUD operations, watch events, leader election" "HTTPS/443, TLS 1.2+, SA token"
        llamaStackOperator -> llamaStackServer "Status queries: /v1/providers, /v1/version" "HTTP/8321"
        llamaStackOperator -> odhTrustedCA "Reads platform CA certificates" "ConfigMap API"
        ingressController -> llamaStackServer "Routes external traffic" "HTTP/8321"
        prometheus -> llamaStackOperator "Scrapes /metrics" "HTTP/8080"
        containerRegistry -> llamaStackServer "Image pull (by Kubelet)" "HTTPS/443"
        rhoaiOperator -> llamaStackOperator "Deploys operator manifests" "Kustomize overlays"
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
            element "Platform" {
                background #6c8ebf
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
        }
    }
}

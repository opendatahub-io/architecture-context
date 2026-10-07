workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys models and creates InferenceService resources"
        platformadmin = person "Platform Admin" "Configures ModelExpressServer CRs and cluster TLS policies"

        modelexpress = softwareSystem "ModelExpress" "High-performance model weight transfer system — discovers fastest path to load LLM weights into GPU memory via P2P RDMA, streaming, or host-staged I/O" {
            server = container "modelexpress-server" "gRPC metadata coordinator for model weight source discovery, download orchestration, P2P transfer coordination, and RL weight versioning" "Rust (tonic + axum)" "8001/TCP gRPC"
            operator = container "modelexpress-operator" "Reconciles ModelExpressServer CRs into Deployments, Services, PVCs, NetworkPolicies, and RBAC" "Rust (kube-rs)"
            operatorOCP = container "modelexpress-operator-openshift" "OpenShift variant — reads cluster TLS profiles, applies ServiceMonitors" "Rust (kube-rs)"
            client = container "modelexpress-client" "Client library (Rust/Python/Go) and CLI for cache management" "Rust + Python + Go bindings"
            common = container "modelexpress-common" "Shared protobuf definitions (5 protos), model-provider traits, TLS settings" "Rust Library"
        }

        vllm = softwareSystem "vLLM" "LLM inference engine (--load-format modelexpress)" "Inference Runtime"
        sglang = softwareSystem "SGLang" "LLM inference engine (remote_instance + modelexpress backend)" "Inference Runtime"
        tensorrtllm = softwareSystem "TensorRT-LLM" "NVIDIA inference engine (checkpoint_format MX)" "Inference Runtime"
        dynamo = softwareSystem "NVIDIA Dynamo" "Dynamo vLLM/SGLang runtimes for P2P transfer" "Inference Runtime"
        llmd = softwareSystem "llm-d" "Upstream Optimized Baseline integration" "Inference Orchestrator"

        redis = softwareSystem "Redis" "Metadata backend for model registry and P2P state" "External"
        k8sapi = softwareSystem "Kubernetes API" "CRD-based metadata backend and operator reconciliation" "Platform"
        ocpconfig = softwareSystem "OpenShift APIServer Config" "Cluster TLS security profile" "Platform"
        prometheus = softwareSystem "Prometheus" "Operator metrics scraping via ServiceMonitor" "Observability"

        hfhub = softwareSystem "Hugging Face Hub" "Model weight repository" "External"
        ngc = softwareSystem "NGC Catalog" "NVIDIA model weight repository" "External"

        # Relationships
        datascientist -> modelexpress "Creates ModelExpressServer CRs, triggers model downloads"
        platformadmin -> modelexpress "Configures TLS, RBAC, metadata backend"

        vllm -> server "P2P weight transfer" "gRPC/8001"
        sglang -> server "P2P weight transfer" "gRPC/8001"
        tensorrtllm -> server "P2P weight transfer (beta)" "gRPC/8001"
        dynamo -> server "P2P weight transfer" "gRPC/8001"
        llmd -> server "Model coordination" "gRPC/8001"

        server -> redis "Store/query metadata" "TCP/6379"
        server -> k8sapi "CRD CRUD (ModelMetadata, ModelCacheEntry)" "HTTPS/443"
        server -> hfhub "Download model weights" "HTTPS/443"
        server -> ngc "Download model weights" "HTTPS/443"

        operator -> k8sapi "Reconcile resources (Deployment, Service, PVC, RBAC, NetworkPolicy)" "HTTPS/443"
        operatorOCP -> ocpconfig "Watch TLS security profile" "HTTPS/443"
        operatorOCP -> prometheus "Apply ServiceMonitor dynamically" "HTTPS/443"

        client -> server "Cache management, health checks" "gRPC/8001"
    }

    views {
        systemContext modelexpress "SystemContext" {
            include *
            autoLayout
        }

        container modelexpress "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #6366f1
                color #ffffff
            }
            element "Inference Runtime" {
                background #3b82f6
                color #ffffff
            }
            element "Inference Orchestrator" {
                background #2563eb
                color #ffffff
            }
            element "Observability" {
                background #8b5cf6
                color #ffffff
            }
            element "Person" {
                background #10b981
                color #ffffff
                shape Person
            }
        }
    }
}

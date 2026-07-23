workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        platformeng = person "Platform Engineer" "Deploys and manages llm-d infrastructure on Kubernetes"

        llmd = softwareSystem "llm-d" "Kubernetes-native distributed LLM inference serving stack with intelligent routing, KV-cache management, and multi-accelerator support" {
            vllmServer = container "vLLM Model Server" "Core inference engine serving OpenAI-compatible API on port 8000/TCP" "Python (vLLM v0.23.0)"
            envoyProxy = container "Envoy Proxy" "L7 proxy fronting inference endpoints, routes via ext_proc" "Envoy distroless-v1.33.2"
            epp = container "EPP (Endpoint Picker)" "Scores endpoints by prefix cache affinity and load for intelligent routing" "Go (llm-d-router)"
            routingSidecar = container "Routing Sidecar" "KV cache routing for disaggregated decode pods" "Go (llm-d-routing-sidecar)"
            nixlTransfer = container "NIXL KV Transfer" "Unified communication for KV cache transfer between prefill and decode pods on port 5600/TCP" "C++ (NIXL v1.2.0)"
            lmcache = container "LMCache" "KV cache management, scheduling, and offloading" "Python (LMCache v0.4.6)"
            kustomizeRecipes = container "Kustomize Recipes" "Composable deployment manifests for gateway, model server, routing, and monitoring" "YAML (Kustomize)"
            containerImages = container "Container Image Builds" "Multi-stage Dockerfiles for CUDA, ROCm, XPU, CPU, and diagnostic images" "Dockerfile + Shell"
        }

        huggingface = softwareSystem "HuggingFace Hub" "Model weight storage and download" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API with InferencePool, Gateway, HTTPRoute CRDs" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        mooncake = softwareSystem "Mooncake" "Distributed KV cache storage backend for tiered prefix cache" "Internal"
        autoscaler = softwareSystem "Workload Variant Autoscaler" "SLO-aware autoscaling of inference pools" "Internal"

        # Relationships
        datascientist -> llmd "Sends inference requests via HTTP"
        platformeng -> llmd "Deploys and configures via kustomize/Helm"

        envoyProxy -> epp "Consults for endpoint selection" "gRPC/9002"
        envoyProxy -> vllmServer "Forwards inference requests" "HTTP/8000"
        epp -> gatewayAPI "Watches InferencePool CRD" "Kubernetes API"
        vllmServer -> huggingface "Downloads model weights" "HTTPS/443"
        vllmServer -> nixlTransfer "Transfers KV cache (prefill to decode)" "TCP-RDMA/5600"
        vllmServer -> lmcache "Manages KV cache lifecycle"
        vllmServer -> mooncake "Offloads KV cache" "gRPC/50051"
        prometheus -> epp "Scrapes metrics" "HTTP/9090"
        prometheus -> vllmServer "Scrapes metrics" "HTTP/8000"
        autoscaler -> kubernetes "Scales InferencePools" "Kubernetes API"
        containerImages -> huggingface "N/A - build-time only"
    }

    views {
        systemContext llmd "SystemContext" {
            include *
            autoLayout
        }

        container llmd "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #000000
            }
            element "Person" {
                shape person
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

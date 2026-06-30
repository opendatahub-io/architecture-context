workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to deployed LLM models"

        vllmSpyre = softwareSystem "vllm-spyre" "IBM Spyre-accelerated vLLM inference server with dual-protocol API (OpenAI HTTP + TGIS gRPC)" {
            adapter = container "vllm_tgis_adapter" "Entrypoint providing OpenAI HTTP API (8000) and TGIS gRPC API (8033)" "Python Module"
            vllmEngine = container "vLLM Engine" "High-performance LLM inference runtime" "Python / C++"
            spyreDriver = container "IBM Spyre Driver" "Hardware accelerator interface for IBM Z, Power, and x86_64" "Native Driver"
        }

        rhaiis = softwareSystem "RHAIIS Base Image" "Red Hat AI Inference Server base image providing all runtime dependencies" "External"
        kserve = softwareSystem "KServe" "Kubernetes serverless inference platform managing InferenceService lifecycle" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar providing TLS and Bearer token validation" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS and traffic management" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage" "Persistent volume or object store for ML model weights" "External"
        spyreHardware = softwareSystem "IBM Spyre Hardware" "Hardware accelerator for LLM inference on IBM Z/LinuxONE, Power, and x86_64" "External"

        user -> kubeRbacProxy "Sends inference requests" "HTTPS/8443"
        user -> istio "Sends inference requests (mesh path)" "mTLS"
        kubeRbacProxy -> vllmSpyre "Forwards authenticated requests" "HTTP/8000, gRPC/8033"
        istio -> vllmSpyre "Forwards mesh traffic" "mTLS"
        kserve -> vllmSpyre "Deploys and manages as inference container" "Kubernetes API"
        vllmSpyre -> modelStorage "Loads model weights at startup" "Volume mount / Storage API"
        vllmSpyre -> spyreHardware "Hardware-accelerated inference compute" "Hardware interface"
        rhaiis -> vllmSpyre "Provides base image with vLLM, TGIS adapter, Spyre drivers" "FROM (build-time)"
    }

    views {
        systemContext vllmSpyre "SystemContext" {
            include *
            autoLayout
        }

        container vllmSpyre "Containers" {
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

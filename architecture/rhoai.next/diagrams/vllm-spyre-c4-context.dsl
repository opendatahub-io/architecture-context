workspace {
    model {
        datascientist = person "Data Scientist" "Creates InferenceService CRs to deploy and query ML models"
        mlapp = person "ML Application" "Automated client consuming inference APIs"

        vllmSpyre = softwareSystem "vllm-spyre" "IBM Spyre-accelerated vLLM inference server with TGIS adapter for dual-protocol model serving" {
            container = container "vllm-spyre Container" "Runs vLLM engine with vllm_tgis_adapter for OpenAI-compatible HTTP (8000) and TGIS gRPC (8033) APIs" "Python / vllm_tgis_adapter"
        }

        kserve = softwareSystem "KServe" "Deploys and manages model serving containers via ServingRuntime and InferenceService CRDs" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar injected by platform, fronts inference endpoints on 8443/TCP" "Internal RHOAI"
        rhaiOperator = softwareSystem "RHOAI Operator" "Platform operator managing component lifecycle, ingress, and security configuration" "Internal RHOAI"

        rhaiisBaseImage = softwareSystem "RHAIIS vllm-spyre-rhel9" "Red Hat AI Inference Server product base image providing vLLM, TGIS adapter, Spyre runtime, and all Python dependencies" "External"
        aipccBase = softwareSystem "AIPCC Spyre Base Image" "IBM AI Platform foundation image with Spyre accelerator libraries and RHEL AI PyPI" "External"
        spyreHW = softwareSystem "IBM Spyre Accelerator" "Purpose-built AI inference chip for accelerated model serving" "External Hardware"

        s3 = softwareSystem "S3 / Object Storage" "Model weight artifact storage (AWS S3, MinIO, Ceph)" "External"
        pvc = softwareSystem "PVC Volume" "Persistent volume claim for local model weight storage" "External"
        huggingface = softwareSystem "Hugging Face Hub" "Public/private model repository for downloading model weights" "External"

        # Relationships
        datascientist -> kserve "Creates InferenceService CR" "kubectl / API"
        mlapp -> kubeRBACProxy "Sends inference requests" "HTTPS/8443"
        kubeRBACProxy -> vllmSpyre "Forwards authenticated requests" "HTTP/8000, gRPC/8033 (localhost)"
        kserve -> vllmSpyre "Deploys as ServingRuntime container" "Kubernetes API"
        rhaiOperator -> kubeRBACProxy "Injects sidecar" "Kubernetes API"

        vllmSpyre -> s3 "Downloads model artifacts" "HTTPS/443, AWS IAM"
        vllmSpyre -> pvc "Reads model weights" "Filesystem mount"
        vllmSpyre -> huggingface "Downloads models (optional)" "HTTPS/443, HF_TOKEN"
        vllmSpyre -> spyreHW "Executes inference workloads" "Device driver"

        rhaiisBaseImage -> aipccBase "Built on" "Container image layer"
        vllmSpyre -> rhaiisBaseImage "Based on (FROM)" "Container image layer"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Hardware" {
                background #666666
                color #ffffff
                shape Hexagon
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

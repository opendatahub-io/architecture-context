workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        mlEngineer = person "ML Engineer" "Configures model serving infrastructure"

        vllmRocm = softwareSystem "vllm-rocm" "Container image providing GPU-accelerated LLM inference on AMD ROCm hardware via vLLM with TGIS adapter" {
            adapter = container "vllm_tgis_adapter" "Wraps vLLM engine, exposes OpenAI-compatible HTTP and TGIS-compatible gRPC APIs" "Python Module"
            engine = container "vLLM Engine" "High-performance LLM inference using PagedAttention, compiled for AMD ROCm GPUs" "Python / C++ / ROCm"
        }

        kserve = softwareSystem "KServe" "Serverless model serving platform that deploys and manages inference containers" "Deploying Platform"
        modelmesh = softwareSystem "ModelMesh" "Multi-model serving platform for efficient model management" "Deploying Platform"
        konflux = softwareSystem "Konflux CI/CD" "Build pipeline that produces the container image from Dockerfile" "Build System"
        rhaiis = softwareSystem "RHAIIS Base Image" "Red Hat AI Infrastructure base image providing vLLM ROCm runtime (v3.2.1)" "Base Image"
        gpu = softwareSystem "AMD ROCm GPU" "Hardware accelerator for LLM inference computation" "Hardware"
        modelStorage = softwareSystem "Model Storage" "Storage backend for model weights (path configured at deploy time)" "External Storage"

        datascientist -> vllmRocm "Sends inference requests" "HTTP/8000, gRPC/8033"
        mlEngineer -> kserve "Deploys InferenceService"
        mlEngineer -> modelmesh "Deploys ServingRuntime"

        kserve -> vllmRocm "Deploys and manages container lifecycle"
        modelmesh -> vllmRocm "Deploys and manages container lifecycle"
        konflux -> vllmRocm "Builds container image" "Tekton Pipelines"
        vllmRocm -> rhaiis "Inherits runtime from base image" "FROM directive"
        vllmRocm -> gpu "Runs inference computation" "ROCm / PCIe"
        vllmRocm -> modelStorage "Loads model weights at startup" "Filesystem"

        adapter -> engine "Routes inference requests"
    }

    views {
        systemContext vllmRocm "SystemContext" {
            include *
            autoLayout
        }

        container vllmRocm "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Deploying Platform" {
                background #999999
                color #ffffff
            }
            element "Build System" {
                background #f5a623
                color #ffffff
            }
            element "Base Image" {
                background #f5a623
                color #ffffff
            }
            element "Hardware" {
                background #9b59b6
                color #ffffff
            }
            element "External Storage" {
                background #e8e8e8
            }
            element "Person" {
                shape Person
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

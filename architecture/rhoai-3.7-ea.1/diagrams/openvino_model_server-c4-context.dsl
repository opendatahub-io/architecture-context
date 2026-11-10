workspace {
    model {
        user = person "Data Scientist" "Deploys models as InferenceServices that use the OVMS runtime"
        client = person "Inference Client" "Calls KServe v2, TFS v1 or OpenAI-compatible APIs"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance C++ inference server for OpenVINO IR, ONNX, TF, Paddle, PyTorch and GenAI models (RHOAI 3.7-ea.1, OVMS 2026.4.0)" {
            rest = container "REST frontend" "KServe v2, TFS v1, OpenAI /v3, config and /metrics on 8888/TCP plain HTTP" "C++ / Drogon"
            grpc = container "gRPC frontend" "KServe v2 GRPCInferenceService, TFS PredictionService and ModelService on 8001/TCP, insecure credentials" "C++ / gRPC"
            modelManager = container "Model manager" "Loads models from /mnt/models or cloud filesystems, version policy, config polling" "C++"
            genai = container "LLM / GenAI pipelines" "Continuous batching, embeddings, rerank, image generation, audio" "C++ / MediaPipe / OpenVINO GenAI"
            runtime = container "OpenVINO runtime" "CPU inference engine and model frontends" "C++ RPM"
            pullModule = container "Pull module" "--pull downloads models from Hugging Face" "C++ / libgit2 / curl"
            pyovms = container "Python node runtime" "pyovms Python graph nodes; venv with openvino 2026.4.0, torch 2.13.0 CPU" "Python 3.12"
        }

        kserve = softwareSystem "KServe" "Deploys OVMS pods per InferenceService (RawDeployment) and creates predictor Service" "Internal RHOAI"
        storageInit = softwareSystem "KServe Storage Initializer" "Downloads model artifacts into /mnt/models" "Internal RHOAI"
        odhModelController = softwareSystem "ODH Model Controller" "Registers kserve-ovms ServingRuntime template; creates Route / Gateway HTTPRoute" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "Runtime selection UI via template annotations" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus (UWM)" "Scrapes inference metrics" "Internal RHOAI"
        route = softwareSystem "OpenShift Route / Gateway" "TLS ingress, optional kube-rbac-proxy / Authorino" "Internal RHOAI"

        objectStorage = softwareSystem "Object Storage" "S3 / GCS / Azure Blob model artifacts" "External"
        huggingFace = softwareSystem "Hugging Face" "Model hub for --pull" "External"
        rpmChannel = softwareSystem "RHEL AI RPM channel (rhelai-3.6)" "Prebuilt OVMS / OpenVINO RPMs (build time)" "External"
        aipccBase = softwareSystem "AIPCC base image" "cpu-el9.8:3.6.0 OS and Python foundation (build time)" "External"

        user -> kserve "Creates InferenceService selecting kserve-ovms"
        user -> dashboard "Selects OVMS runtime"
        client -> route "Inference requests" "HTTPS/443"
        route -> rest "Forwards via predictor Service" "HTTP/80 to 8888"
        odhModelController -> route "Creates"
        odhModelController -> kserve "Provides ServingRuntime template"
        kserve -> ovms "Creates Deployment and Service"
        storageInit -> objectStorage "Downloads model artifacts" "HTTPS/443"
        storageInit -> modelManager "Provides /mnt/models" "shared emptyDir"
        prometheus -> rest "Scrapes /metrics" "HTTP/8888"

        rest -> modelManager "Dispatches inference"
        grpc -> modelManager "Dispatches inference"
        rest -> genai "OpenAI /v3 requests"
        modelManager -> runtime "Compiles and runs models"
        genai -> runtime "Runs GenAI pipelines"
        genai -> pyovms "Executes Python nodes"
        modelManager -> objectStorage "Direct s3:// gs:// az:// reads (optional)" "HTTPS/443"
        modelManager -> pullModule "Triggers model pull"
        pullModule -> huggingFace "Downloads models (optional HF_TOKEN)" "HTTPS/443"

        ovms -> rpmChannel "Built from RPMs (hermetic prefetch)"
        ovms -> aipccBase "Built on"
    }

    views {
        systemContext ovms "SystemContext" {
            include *
            autoLayout
        }

        container ovms "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

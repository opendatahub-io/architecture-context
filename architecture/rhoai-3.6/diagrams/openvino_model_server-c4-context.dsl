workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and manages model deployments"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance model inference server built on Intel OpenVINO, exposing KServe v2, TFS, and OpenAI-compatible APIs over gRPC and REST" {
            drogonServer = container "Drogon HTTP Server" "REST API frontend serving TFS v1, KServe v2, OpenAI v3, and metrics endpoints" "C++ / Drogon Framework"
            grpcServer = container "gRPC Server Module" "gRPC frontend for TFS and KServe inference protocols" "C++ / gRPC"
            modelManager = container "Model Manager" "Model lifecycle management: loading, versioning, hot-reload, multi-model orchestration" "C++"
            mediaipeExecutor = container "MediaPipe Graph Executor" "Graph-based execution engine for GenAI workloads (LLM, embeddings, rerank, image gen, speech)" "C++ / MediaPipe"
            dagScheduler = container "DAG Scheduler" "Directed Acyclic Graph pipeline scheduler for multi-model inference chains" "C++"
            filesystemBackends = container "Filesystem Backends" "Pluggable model storage backends (local, S3, GCS, Azure)" "C++"
            hfPullModule = container "HuggingFace Pull Module" "Model download from HuggingFace Hub via libgit2 and curl" "C++"
            metricModule = container "Metric Module" "Prometheus metrics collection and /metrics endpoint" "C++"
        }

        nginxMtls = softwareSystem "nginx-mtls-auth" "Optional sidecar providing mTLS termination in front of OVMS" "Sidecar"

        kserve = softwareSystem "KServe" "Manages OVMS pod lifecycle via ServingRuntime CRD definitions" "Internal RHOAI"
        istio = softwareSystem "Istio / Service Mesh" "TLS termination and traffic management for RHOAI deployments" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        s3 = softwareSystem "AWS S3" "Model artifact storage" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model repository for downloading pretrained models" "External"

        openvinoRuntime = softwareSystem "OpenVINO Runtime" "Intel inference engine for model execution on CPU/GPU/NPU" "Embedded"

        # Relationships - Users
        dataScientist -> ovms "Sends inference requests via REST/gRPC"
        mlEngineer -> kserve "Creates InferenceService/ServingRuntime resources"

        # Relationships - Internal
        drogonServer -> modelManager "Routes inference requests"
        grpcServer -> modelManager "Routes inference requests"
        drogonServer -> mediaipeExecutor "Routes OpenAI v3 requests"
        modelManager -> dagScheduler "Executes multi-model pipelines"
        modelManager -> filesystemBackends "Loads models from storage"
        modelManager -> hfPullModule "Downloads models from HuggingFace"
        modelManager -> openvinoRuntime "Executes inference" "In-process"
        mediaipeExecutor -> openvinoRuntime "Executes GenAI inference" "In-process"

        # Relationships - Platform
        kserve -> ovms "Manages pod lifecycle via ServingRuntime CRD"
        istio -> ovms "Provides mTLS and traffic routing"
        prometheus -> ovms "Scrapes /metrics endpoint" "HTTP"

        # Relationships - External
        filesystemBackends -> s3 "Downloads model artifacts" "HTTPS/443"
        filesystemBackends -> gcs "Downloads model artifacts" "HTTPS/443"
        filesystemBackends -> azure "Downloads model artifacts" "HTTPS/443"
        hfPullModule -> hfHub "Downloads models (git clone + direct download)" "HTTPS/443"
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
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Sidecar" {
                background #e67e22
                color #ffffff
            }
            element "Embedded" {
                background #0071c5
                color #ffffff
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
                background #5ba3f5
                color #ffffff
            }
        }
    }
}

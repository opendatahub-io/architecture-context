workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for text generation"
        platformOps = person "Platform Operator" "Manages RHOAI platform and model serving infrastructure"

        tgis = softwareSystem "Text Generation Inference Server (TGIS)" "GPU-accelerated text generation inference server with gRPC/HTTP interfaces, continuous batching, and tensor parallelism" {
            launcher = container "text-generation-launcher" "Process orchestrator — spawns shard and router processes, manages lifecycle and graceful shutdown" "Rust CLI"
            router = container "text-generation-router" "gRPC/HTTP server providing API endpoints, request validation, continuous dynamic batching, and metrics" "Rust Service" {
                grpcServer = component "gRPC Server" "GenerationService (Generate, GenerateStream, Tokenize, ModelInfo)" "tonic 0.11.0"
                httpServer = component "HTTP Server" "Health checks (/health) and Prometheus metrics (/metrics)" "axum 0.6.20"
                validator = component "Request Validator" "Input validation, sequence length checks, tokenization" "Rust"
                batcher = component "Continuous Dynamic Batcher" "Request queuing, batch assembly, padding optimization" "Rust"
            }
            server = container "text-generation-server" "Model loading, inference execution, KV cache management, distributed tensor parallel computation" "Python gRPC Service"
            kernels = container "custom_kernels" "Custom CUDA kernels for optimized attention and other operations" "Python C Extension"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Model serving platform that manages TGIS as a serving runtime" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "Internal Platform"
        modelStorage = softwareSystem "Model Weight Storage" "Persistent volume providing model weights" "Internal Platform"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloading model weights" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"

        # Relationships
        dataScientist -> kserve "Deploys InferenceService with TGIS runtime"
        kserve -> tgis "Sends inference requests" "gRPC/8033"

        # Internal container relationships
        launcher -> router "Spawns and monitors"
        launcher -> server "Spawns N shard processes (one per GPU)"
        router -> server "Forwards batched inference requests" "gRPC over Unix Domain Socket"
        server -> kernels "Uses for optimized CUDA operations"

        # External relationships
        tgis -> modelStorage "Loads model weights" "Volume mount (read-only)"
        tgis -> huggingface "Downloads model weights (pre-deployment only)" "HTTPS/443"
        prometheus -> tgis "Scrapes metrics" "HTTP/3000 /metrics"
        otel -> tgis "Receives traces" "gRPC OTLP"
        kubernetes -> tgis "Health probes" "HTTP/3000 /health"
        platformOps -> prometheus "Monitors TGIS instances"
    }

    views {
        systemContext tgis "SystemContext" {
            include *
            autoLayout
            description "System context showing TGIS in the RHOAI ecosystem"
        }

        container tgis "Containers" {
            include *
            autoLayout
            description "Internal container structure of TGIS showing multi-process architecture"
        }

        component router "RouterComponents" {
            include *
            autoLayout
            description "Internal components of the Rust router showing request processing pipeline"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys LLM models and sends inference requests"
        platformEngineer = person "Platform Engineer" "Deploys and configures KV cache infrastructure"

        kvCacheSystem = softwareSystem "llm-d-kv-cache" "Multi-component KV cache indexing and management system for prefix-cache-aware LLM inference scheduling" {
            kvIndexer = container "KV Cache Indexer" "Tracks KV block-to-pod mappings; provides scoring API for prefix-cache-aware request routing" "Go Library"
            kvEventsPipeline = container "KV Events Pipeline" "Processes ZMQ PUB/SUB events from vLLM/SGLang engines to maintain real-time index state" "Go Library"
            udsTokenizer = container "UDS Tokenizer" "Tokenizes prompts and renders chat templates via gRPC over Unix Domain Socket" "Python gRPC Sidecar"
            fsBackend = container "llmd_fs_backend" "Offloads KV cache blocks between GPU memory and shared filesystem/object storage via C++/CUDA extension" "Python vLLM Plugin + C++ CUDA"
            pvcEvictor = container "PVC Evictor" "Monitors disk usage on shared KV cache PVC and evicts stale blocks using N+2 multiprocessing architecture" "Python Daemon"
            storageOffload = container "storage_offload" "High-performance GPU-to-Storage block transfer engine with CUDA streams, pinned memory pools, and GDS support" "C++17 CUDA Extension"

            kvEventsPipeline -> kvIndexer "Updates block-to-pod index"
            kvIndexer -> udsTokenizer "Tokenize prompts" "gRPC over UDS"
            fsBackend -> storageOffload "GPU memory transfer" "CUDA API"
        }

        gateway = softwareSystem "llm-d-inference-scheduler" "Routing gateway that uses KV cache scores for prefix-cache-aware request scheduling" "Internal RHOAI"

        vllmPods = softwareSystem "vLLM Inference Pods" "Serve LLM inference requests with KV cache management" "Internal RHOAI"

        redis = softwareSystem "Redis / Valkey" "Distributed key-value store for KV block index (optional)" "External"
        sharedPVC = softwareSystem "Shared PVC" "ReadWriteMany persistent volume for KV cache block storage" "Kubernetes Storage"
        s3 = softwareSystem "S3 / MinIO" "Object storage for KV cache blocks via NIXL" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and tokenizer file hosting" "External"
        otlp = softwareSystem "OTLP Collector" "OpenTelemetry trace aggregation" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster management and pod discovery" "Kubernetes"

        # Relationships - Gateway consumes KV cache as Go library
        gateway -> kvCacheSystem "Imports KV cache indexer/scorer" "Go library (in-process)"

        # vLLM interactions
        vllmPods -> kvCacheSystem "Publishes KV block lifecycle events" "ZMQ PUB/SUB 5557/TCP"
        kvCacheSystem -> vllmPods "fs_backend runs as vLLM plugin" "In-process Python"

        # External dependencies
        kvCacheSystem -> redis "Stores distributed block index" "Redis protocol 6379/TCP"
        kvCacheSystem -> sharedPVC "Reads/writes KV cache blocks" "POSIX filesystem I/O"
        kvCacheSystem -> s3 "Object storage for KV cache (OBJ mode)" "HTTP/HTTPS 9000/TCP"
        kvCacheSystem -> huggingface "Downloads tokenizer model files" "HTTPS 443/TCP"
        kvCacheSystem -> otlp "Exports distributed traces" "gRPC 4317/TCP"
        kvCacheSystem -> k8sAPI "Pod discovery for ZMQ subscribers" "HTTPS 443/TCP"
        prometheus -> kvCacheSystem "Scrapes metrics" "HTTP 8080/TCP /metrics"

        # User interactions
        dataScientist -> gateway "Sends inference requests"
        platformEngineer -> kvCacheSystem "Deploys and configures via Helm/Kustomize"
    }

    views {
        systemContext kvCacheSystem "SystemContext" {
            include *
            autoLayout
        }

        container kvCacheSystem "Containers" {
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
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Kubernetes Storage" {
                background #f5a623
                color #ffffff
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
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

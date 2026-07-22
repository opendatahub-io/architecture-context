workspace {
    model {
        mlEngineer = person "ML Engineer / SRE" "Deploys and monitors LLM inference workloads"

        kvCacheSystem = softwareSystem "llm-d-kv-cache" "KV-cache indexing and management for KV-cache-aware routing and cross-node cache coordination in vLLM-based inference" {
            indexer = container "KV-Cache Indexer" "Core scoring engine using longest-prefix-match across multi-backend block store" "Go Library"
            eventsPool = container "KV Events Pool" "Sharded FNV-1a worker queue ingesting ZMQ event streams from vLLM pods" "Go Library"
            blockIndex = container "kvblock.Index" "Multi-backend block store (CostAwareMemory, Valkey, Redis, InMemory LRU)" "Go Library"
            indexerGRPC = container "IndexerService gRPC" "gRPC wrapper exposing pod scoring via GetPodScores RPC on 50051/TCP" "Go gRPC Service"
            udsTokenizer = container "UDS Tokenizer Service" "Sidecar providing tokenization and chat template rendering over Unix Domain Sockets" "Python gRPC Service"
            httpAPI = container "HTTP API" "REST endpoints for scoring, health, and metrics on 8080/TCP" "Go HTTP Service"
            fsBackend = container "llmd-fs-backend" "Storage backend for GPU ↔ shared storage KV-cache offloading (deprecated; upstreamed to vLLM v0.23)" "Python vLLM Plugin"
            pvcEvictor = container "PVC Evictor" "Multi-process utility managing disk space on KV-cache PVCs using threshold-based hysteresis" "Python Utility"
        }

        vllm = softwareSystem "vLLM Inference Pods" "vLLM-based LLM inference engines serving predictions" "Internal llm-d"
        router = softwareSystem "llm-d-router" "KV-cache-aware request scheduler/router for distributed inference" "Internal llm-d"
        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes control plane for pod discovery and lifecycle management" "Infrastructure"
        redis = softwareSystem "Redis / Valkey" "Optional persistent distributed KV-block index storage" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model and tokenizer artifact repository" "External"
        otlp = softwareSystem "OTLP Collector" "OpenTelemetry trace collection and export" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping and monitoring" "Infrastructure"
        sharedPVC = softwareSystem "Shared PVC" "Persistent Volume Claim for KV-cache block storage" "Infrastructure"

        # External relationships
        vllm -> kvCacheSystem "Publishes KVEvents via ZMQ PUB" "ZMQ/5557 plaintext"
        router -> kvCacheSystem "Imports kvcache.Indexer for pod scoring" "Go library (in-process)"
        kvCacheSystem -> redis "Stores/retrieves KV-block index" "Redis/6379 plaintext"
        kvCacheSystem -> hfHub "Downloads tokenizer models" "HTTPS/443 TLS 1.2+"
        kvCacheSystem -> k8sAPI "Discovers vLLM pods by label selector" "HTTPS/443 TLS"
        kvCacheSystem -> otlp "Exports distributed traces" "gRPC/4317"
        prometheus -> kvCacheSystem "Scrapes metrics" "HTTP/8080"
        kvCacheSystem -> sharedPVC "Reads/writes KV-cache blocks" "POSIX I/O"

        # Internal container relationships
        eventsPool -> indexer "Feeds decoded KVEvents"
        indexer -> blockIndex "Score lookup via longest-prefix-match"
        indexer -> udsTokenizer "Tokenization requests" "gRPC over UDS"
        indexerGRPC -> indexer "Delegates GetPodScores RPC"
        httpAPI -> indexer "Delegates scoring HTTP requests"
        fsBackend -> sharedPVC "Writes KV-cache blocks" "POSIX I/O"
        fsBackend -> eventsPool "Publishes storage events" "ZMQ PUB"
        pvcEvictor -> sharedPVC "Manages disk space" "POSIX I/O"
        udsTokenizer -> hfHub "Downloads tokenizer models" "HTTPS/443"
        blockIndex -> redis "Persistent index ops" "Redis/6379"
        eventsPool -> k8sAPI "Pod reconciler" "HTTPS/443"
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
            element "Internal llm-d" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

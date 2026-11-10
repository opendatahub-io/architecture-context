workspace {
    model {
        operator = person "Platform Operator" "Deploys LLMInferenceService and the PVC evictor"

        kvcache = softwareSystem "llm-d-kv-cache" "KV-cache support for llm-d: indexer library, UDS tokenizer sidecar, PVC evictor" {
            indexer = container "KV-cache Indexer Library" "pkg/kvcache, kvblock, kvevents, tokenization, telemetry. Linked into the EPP scheduler; scores pods by prefix-cache hit" "Go library"
            tokenizer = container "UDS Tokenizer Sidecar" "tokenization.TokenizationService over unix socket; HF tokenizer download; vLLM chat/completion rendering; /healthz 8082" "Python gRPC (odh-llm-d-kv-cache-rhel9)"
            evictor = container "PVC Evictor" "Deletes cold KV-cache .bin files above 85% usage down to 70%; optional ZMQ BlockRemoved publisher" "Go Deployment (odh-llm-d-kv-pvc-evictor-rhel9)"
            pvc = container "Shared KV-cache PVC" "Offloaded vLLM KV blocks at /kv-cache" "PersistentVolumeClaim" "Storage"
        }

        epp = softwareSystem "llm-d EPP Scheduler" "Inference scheduler with precise-prefix-cache-scorer (llm-d-router)" "Internal RHOAI"
        kserve = softwareSystem "KServe LLMInferenceService Controller" "Renders scheduler pod, injects tokenizer sidecar and socket config" "Internal RHOAI"
        vllm = softwareSystem "vLLM" "Model server (RHAIIS / llm-d runtime); publishes KVEvents, writes offloaded KV blocks" "Internal RHOAI"
        aipcc = softwareSystem "AIPCC Base Images" "Python base images and RHEL AI PyPI index" "Internal RHOAI"
        hf = softwareSystem "Hugging Face Hub" "Tokenizer and config files" "External"
        modelscope = softwareSystem "ModelScope" "Optional tokenizer source" "External"
        redis = softwareSystem "Redis / Valkey" "Optional distributed KV-block index" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Trace collection" "External"

        operator -> kserve "Creates LLMInferenceService"
        operator -> evictor "Deploys via kustomize (kv_connectors/pvc_evictor/deploy)"
        kserve -> tokenizer "Injects sidecar and WithUdsTokenizerConfig"
        kserve -> epp "Configures precise-prefix-cache-scorer"
        epp -> indexer "Imports and calls GetPodScores" "Go in-process"
        indexer -> tokenizer "Tokenize / RenderChatCompletion" "gRPC over UDS, insecure"
        vllm -> indexer "KVEvents BlockStored/BlockRemoved" "ZMTP 5557/TCP, msgpack, plaintext"
        vllm -> pvc "Writes offloaded KV blocks" "POSIX FS"
        evictor -> pvc "statfs, stat atime, unlink cold files" "POSIX FS"
        evictor -> indexer "Optional BlockRemoved events" "ZMTP PUB, plaintext, no CURVE"
        tokenizer -> hf "Downloads tokenizers (trust_remote_code)" "HTTPS 443/TCP"
        tokenizer -> modelscope "Optional tokenizer download" "HTTPS 443/TCP"
        indexer -> redis "Optional index backend" "RESP 6379/TCP, TLS if rediss://"
        indexer -> otel "Exports traces" "OTLP/gRPC 4317/TCP, insecure"
        tokenizer -> aipcc "Built on cpu:3.5 base" "Container image"
    }

    views {
        systemContext kvcache "SystemContext" {
            include *
            autoLayout
        }

        container kvcache "Containers" {
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
            }
            element "Storage" {
                shape Cylinder
                background #f5a623
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

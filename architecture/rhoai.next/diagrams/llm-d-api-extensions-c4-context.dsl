workspace {
    model {
        operator = person "ML Platform Operator" "Deploys and configures vLLM inference servers with llm-d routing"

        llmDApiExtensions = softwareSystem "llm-d-api-extensions" "Pip-installable Python library that adds read-only server introspection HTTP endpoints to vLLM inference servers for the llm-d routing layer" {
            configPlugin = container "ServerConfigPlugin" "Exposes server launch configuration: model info, scheduler, parallelism, KV cache config, KV transfer settings" "Python vLLM Endpoint Plugin"
            devicesPlugin = container "ServerDevicesPlugin" "Exposes per-rank GPU hardware properties (name, memory, compute capability) via collective_rpc" "Python vLLM Endpoint Plugin"
            kvCachePlugin = container "ServerKVCachePlugin" "Exposes post-profiling KV cache capacity and attention group structure" "Python vLLM Endpoint Plugin"
            workerExtension = container "DeviceInfoWorkerExtension" "Collects device properties per worker rank using current_platform API" "Python vLLM Worker Extension"
            schemas = container "Pydantic Schemas" "Response models with discriminated unions for KV cache group specs" "Python Pydantic v2"
        }

        vllm = softwareSystem "vLLM Inference Server" "High-throughput LLM inference engine; hosts plugins in-process" "Host Process" {
            tags "External"
        }

        llmDRouter = softwareSystem "llm-d Router/Scheduler" "Intelligent routing and scheduling layer for LLM inference requests" "Internal Platform" {
            tags "Internal"
        }

        fastapi = softwareSystem "FastAPI" "Python async web framework for HTTP route registration" "Library" {
            tags "External"
        }

        pydantic = softwareSystem "Pydantic v2" "Data validation and serialization library" "Library" {
            tags "External"
        }

        # Relationships
        operator -> vllm "Configures with VLLM_PLUGINS env var to enable plugins"
        llmDApiExtensions -> vllm "Registers as in-process plugin via vllm.endpoint_plugins entry point"
        llmDApiExtensions -> fastapi "Uses for HTTP route registration (APIRouter)"
        llmDApiExtensions -> pydantic "Uses for response model serialization"

        configPlugin -> vllm "Reads VllmConfig internals (ModelConfig, SchedulerConfig, ParallelConfig)" "In-process"
        devicesPlugin -> vllm "Calls collective_rpc to gather per-rank GPU properties" "In-process RPC"
        kvCachePlugin -> vllm "Calls get_kv_cache_spec and get_kv_cache_group_metadata" "In-process"
        workerExtension -> vllm "Mixed into Worker via --worker-extension-cls" "In-process"

        llmDRouter -> llmDApiExtensions "GET /plugins/llm-d-server-introspection/{config,devices,kv-cache}" "HTTP/8000"
    }

    views {
        systemContext llmDApiExtensions "SystemContext" {
            include *
            autoLayout
        }

        container llmDApiExtensions "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
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

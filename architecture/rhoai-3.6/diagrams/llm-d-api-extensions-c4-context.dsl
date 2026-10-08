workspace {
    model {
        operator = person "Platform Operator" "Deploys and configures vLLM inference servers with llm-d plugins"

        llmDApiExtensions = softwareSystem "llm-d-api-extensions" "Python library providing read-only server introspection HTTP endpoints for vLLM" {
            configPlugin = container "ServerConfigPlugin" "Exposes server launch configuration (model, scheduler, parallelism, KV transfer)" "Python / FastAPI"
            devicesPlugin = container "ServerDevicesPlugin" "Exposes per-rank GPU/accelerator hardware properties via collective_rpc" "Python / FastAPI"
            kvCachePlugin = container "ServerKVCachePlugin" "Exposes post-profiling KV cache capacity and attention group structure" "Python / FastAPI"
            deviceWorkerExt = container "DeviceInfoWorkerExtension" "Worker mixin for per-rank device property queries" "Python / vLLM Worker Extension"
        }

        vllm = softwareSystem "vLLM Inference Server" "Host inference server that loads plugins via endpoint_plugins entry point" "External"
        gateway = softwareSystem "llm-d Gateway/Router" "Queries introspection endpoints for intelligent routing and scheduling decisions" "Internal llm-d"
        fastapi = softwareSystem "FastAPI" "HTTP framework for route registration and request handling" "External"
        pydantic = softwareSystem "Pydantic" "Response schema definition and validation (v2+)" "External"

        operator -> vllm "Deploys with VLLM_PLUGINS env var and --worker-extension-cls"
        vllm -> llmDApiExtensions "Loads via vllm.endpoint_plugins entry point"
        gateway -> llmDApiExtensions "GET /plugins/llm-d-server-introspection/* (HTTP/8000)"
        llmDApiExtensions -> vllm "Reads VllmConfig, EngineClient, worker state (in-process)"
        configPlugin -> fastapi "Registers HTTP routes"
        devicesPlugin -> fastapi "Registers HTTP routes"
        kvCachePlugin -> fastapi "Registers HTTP routes"
        devicesPlugin -> deviceWorkerExt "collective_rpc dispatch"
        configPlugin -> pydantic "ServerConfig response model"
        devicesPlugin -> pydantic "ServerDevices response model"
        kvCachePlugin -> pydantic "ServerKVCache response model (10 discriminated union types)"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

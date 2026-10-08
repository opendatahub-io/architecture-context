workspace {
    model {
        operator = person "Platform Operator" "Deploys and configures vLLM inference servers with llm-d"

        llmdApiExtensions = softwareSystem "llm-d-api-extensions" "Python plugin library adding read-only server introspection HTTP endpoints to vLLM for llm-d routing decisions" {
            configPlugin = container "ServerConfigPlugin" "Exposes operator-supplied launch configuration (model, scheduler, parallelism, KV transfer)" "Python vLLM Endpoint Plugin"
            devicesPlugin = container "ServerDevicesPlugin" "Exposes per-rank GPU device properties (name, memory, compute capability)" "Python vLLM Endpoint Plugin"
            kvCachePlugin = container "ServerKVCachePlugin" "Exposes post-profiling KV cache capacity and attention group structure" "Python vLLM Endpoint Plugin"
            workerExtension = container "DeviceInfoWorkerExtension" "Worker-side mixin providing get_device_properties via collective_rpc" "Python vLLM Worker Extension"
        }

        vllm = softwareSystem "vLLM Inference Server" "High-performance LLM serving engine providing plugin framework and worker infrastructure" "External"
        llmdRouter = softwareSystem "llm-d Routing Layer" "Distributed LLM serving platform that routes and schedules inference requests" "Internal llm-d"
        fastapi = softwareSystem "FastAPI" "Web framework for HTTP route registration" "External"
        pydantic = softwareSystem "Pydantic" "Data validation and serialization library" "External"

        operator -> vllm "Deploys with VLLM_PLUGINS env and --worker-extension-cls flag"
        llmdRouter -> llmdApiExtensions "Queries introspection endpoints for routing/scheduling" "HTTP/8000"
        llmdApiExtensions -> vllm "Reads VllmConfig, EngineClient, and worker state" "In-process Python API"
        devicesPlugin -> workerExtension "Collects device properties" "collective_rpc"
        configPlugin -> vllm "Reads VllmConfig at init" "In-process"
        kvCachePlugin -> vllm "Reads KV cache spec and group metadata" "In-process"
        llmdApiExtensions -> fastapi "Registers API routes via APIRouter" "In-process"
        llmdApiExtensions -> pydantic "Serializes response models" "In-process"
    }

    views {
        systemContext llmdApiExtensions "SystemContext" {
            include *
            autoLayout
        }

        container llmdApiExtensions "Containers" {
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
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

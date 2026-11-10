workspace "llm-d-api-extensions" "vLLM server-introspection endpoint plugins for llm-d (RHOAI 3.7-ea.1)" {
    model {
        operator = person "Platform Operator" "Enables plugins via VLLM_PLUGINS and --worker-extension-cls on vLLM containers"

        apiExt = softwareSystem "llm-d-api-extensions" "Opt-in vLLM endpoint plugins exposing read-only server introspection (config, devices, kv-cache)" {
            configPlugin = container "ServerConfigPlugin" "GET /plugins/llm-d-server-introspection/config - launch config snapshot, KV-transfer topology (redacted extra config)" "Python / FastAPI router"
            devicesPlugin = container "ServerDevicesPlugin" "GET /plugins/llm-d-server-introspection/devices - per-rank accelerator properties" "Python / FastAPI router"
            kvPlugin = container "ServerKVCachePlugin" "GET /plugins/llm-d-server-introspection/kv-cache - KV-cache capacity and group layout" "Python / FastAPI router"
            workerExt = container "DeviceInfoWorkerExtension" "Worker mixin adding get_device_properties via current_platform" "Python / vLLM worker extension"
            common = container "common + schemas" "Drift-tolerant reads, tolerant Pydantic build, guarded init_state, nullable response models" "Python / Pydantic v2"
        }

        vllm = softwareSystem "vLLM Model Server" "Host inference server: API server (8000/TCP), EngineClient, GPU workers" "Internal Platform"
        llmd = softwareSystem "llm-d Scheduler / Router" "Consumes introspection data for routing and scheduling" "Internal Platform"
        kserve = softwareSystem "KServe LLMInferenceService / llm-d tooling" "Would configure VLLM_PLUGINS and --worker-extension-cls (inferred, not wired in repo)" "Internal Platform"
        upstreamApi = softwareSystem "vLLM get_kv_cache_group_metadata (vllm#48121)" "Unreleased upstream API; optional source of KV-cache group structure" "External"

        operator -> kserve "Configures model deployments"
        kserve -> vllm "Sets plugin env/flags on vLLM containers"
        vllm -> apiExt "Loads via vllm.endpoint_plugins entry points" "In-process"
        llmd -> vllm "GET /plugins/llm-d-server-introspection/*" "HTTP/8000 (TLS+auth inherited)"

        vllm -> configPlugin "attach_router / init_state" "In-process"
        vllm -> devicesPlugin "attach_router / init_state" "In-process"
        vllm -> kvPlugin "attach_router / init_state" "In-process"
        devicesPlugin -> vllm "collective_rpc('get_device_properties')" "vLLM internal IPC"
        vllm -> workerExt "Invokes get_device_properties on each rank" "vLLM internal IPC"
        kvPlugin -> upstreamApi "Optional call if method exists (getattr)" "In-process / IPC"
        configPlugin -> common "Uses"
        devicesPlugin -> common "Uses"
        kvPlugin -> common "Uses"
    }

    views {
        systemContext apiExt "SystemContext" {
            include *
            autoLayout
        }

        container apiExt "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
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
            element "External" {
                background #999999
            }
            element "Internal Platform" {
                background #7ed321
            }
        }
    }
}

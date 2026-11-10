workspace {
    model {
        client = person "Inference Client" "Calls OpenAI-compatible completion APIs through the Gateway"

        sidecar = softwareSystem "llm-d-routing-sidecar" "Reverse proxy in vLLM decode pods that orchestrates disaggregated prefill/decode inference (deprecated upstream; code moved to llm-d-inference-scheduler)" {
            proxyServer = container "Proxy Server" "ServeMux: /health, completion interception, pass-through to decoder; optional TLS listener on :8000" "Go net/http"
            connectors = container "P/D Connectors" "nixlv2 (default), nixl, lmcache: prefill rewrite, then decode with kv_transfer_params" "Go"
            allowlist = container "AllowlistValidator" "Optional SSRF protection: InferencePool member host/IP allowlist" "client-go dynamic informers"
            certGen = container "Self-signed Cert Generator" "RSA-4096, 10-year fallback server cert" "Go crypto"

            proxyServer -> connectors "Routes P/D completion requests"
            connectors -> allowlist "Validates prefill target"
            proxyServer -> certGen "Uses when no -cert-path"
        }

        gateway = softwareSystem "Gateway (Envoy / Istio)" "Gateway API ingress with Kuadrant AuthPolicy" "Internal RHOAI"
        epp = softwareSystem "llm-d EPP / Inference Scheduler" "Selects decode and prefill pods; sets x-prefiller-host-port" "Internal RHOAI"
        vllmDecode = softwareSystem "vLLM Decode" "Co-located decode engine on localhost:8001" "Internal RHOAI"
        vllmPrefill = softwareSystem "vLLM Prefill Pods" "Prefill engines with NIXL/LMCache KV connector" "Internal RHOAI"
        kserve = softwareSystem "KServe LLMInferenceService Controller" "Injects the sidecar into decode pods" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes API" "InferencePool and Pod watches" "External"

        client -> gateway "Sends completion requests" "HTTPS/443, Bearer token"
        gateway -> epp "Asks for endpoint selection"
        gateway -> proxyServer "Forwards to decode pod" "HTTPS/8000, TLS 1.2+"
        connectors -> vllmPrefill "Prefill pass (max_tokens=1)" "HTTP(S)/header port"
        connectors -> vllmDecode "Decode pass with kv_transfer_params" "HTTP/8001 loopback"
        proxyServer -> vllmDecode "Pass-through for non-P/D traffic" "HTTP/8001"
        vllmDecode -> vllmPrefill "Pulls KV cache" "NIXL/UCX"
        allowlist -> k8s "LIST/WATCH inferencepools and pods" "HTTPS/6443, SA token"
        kserve -> sidecar "Injects as native sidecar"
    }

    views {
        systemContext sidecar "SystemContext" {
            include *
            autoLayout
        }

        container sidecar "Containers" {
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
        }
    }
}

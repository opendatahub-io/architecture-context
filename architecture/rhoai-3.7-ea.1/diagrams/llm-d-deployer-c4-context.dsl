workspace "llm-d-deployer" "Deprecated llm-d umbrella Helm chart and quickstart installer (RHOAI 3.7 EA1 historical reference)" {
    model {
        user = person "Platform Operator" "Installs the llm-d chart and creates ModelService CRs"
        client = person "Inference Client" "Calls the OpenAI-compatible inference API"

        deployer = softwareSystem "llm-d-deployer" "Umbrella Helm chart (llm-d v1.0.23) and installer for the first-generation llm-d stack. Deprecated 2025-07-25." {
            installer = container "llmd-installer.sh" "Installs CRDs, gateway provider, HF Secret, PVC/model download, monitoring, helm upgrade" "Bash"
            controller = container "modelservice controller" "Reconciles ModelService CRs into Deployments, Services, SAs, RoleBindings, InferencePool/Model, HTTPRoute" "Go, ghcr.io/llm-d/llm-d-model-service:v0.0.15"
            presets = container "Preset ConfigMaps" "Go-templated Deployment/Service/EPP/InferencePool skeletons (4 presets)" "ConfigMap"
            gateway = container "Inference Gateway" "Gateway API Gateway, HTTP :80, ext_proc to EPP" "Envoy (Istio / kgateway / GKE L7)"
            epp = container "Endpoint Picker" "ext_proc service scoring endpoints (prefix, load, KV-cache, session)" "Go, llm-d-inference-scheduler:v0.1.0, gRPC 9002"
            sidecar = container "Routing sidecar" "Decode-side P/D proxy 8000 to 8001, nixlv2 connector" "Go, llm-d-routing-sidecar:0.0.7"
            decode = container "Decode vLLM" "Model server for decode phase" "Python, llm-d:0.0.8, 8001"
            prefill = container "Prefill vLLM" "Model server for prefill phase" "Python, llm-d:0.0.8, 8000"
            redis = container "Redis" "KV-cache index and LMCache lookup, auth disabled" "Redis 7, port 8100"
            grafana = container "Grafana quickstart" "Dashboards with Thanos datasource" "Grafana Operator CRs"
        }

        k8s = softwareSystem "Kubernetes API" "kube-apiserver, >= 1.30" "External"
        gwProvider = softwareSystem "Gateway provider" "Istio 1.27 alpha / kgateway v2.0.3 / GKE L7" "External"
        gie = softwareSystem "Gateway API + Inference Extension CRDs" "Gateway, HTTPRoute, InferencePool, InferenceModel" "External"
        hf = softwareSystem "Hugging Face Hub" "Model and tokenizer download" "External"
        registries = softwareSystem "Container registries" "ghcr.io, quay.io, gcr.io/istio-testing" "External"
        gpuOp = softwareSystem "NVIDIA GPU Operator" "nvidia.com/gpu resources" "External"
        prom = softwareSystem "Prometheus / OpenShift UWM" "ServiceMonitor-based metrics" "Internal ODH"
        thanos = softwareSystem "Thanos Querier" "OpenShift monitoring query endpoint" "Internal ODH"
        modelService = softwareSystem "llm-d-model-service" "Controller image + CRD source" "Internal ODH"
        scheduler = softwareSystem "llm-d-inference-scheduler (llm-d-router)" "EPP image and CRD kustomize source" "Internal ODH"
        kvcache = softwareSystem "llm-d-kv-cache" "KV-cache-aware scoring" "Internal ODH"
        infra = softwareSystem "llm-d-infra" "Successor (Helmfile + llm-d-modelservice charts)" "Internal ODH"
        kserve = softwareSystem "KServe LLMInferenceService" "Supported RHOAI llm-d deployment path" "Internal ODH"

        user -> installer "Runs"
        user -> k8s "Creates ModelService" "HTTPS/6443"
        client -> gateway "OpenAI-compatible requests" "HTTP/80, no auth"
        installer -> gie "Installs CRDs" "HTTPS/443 github.com"
        installer -> gwProvider "Installs"
        installer -> deployer "helm upgrade -i"
        controller -> k8s "Watches ModelService, creates workloads" "HTTPS/6443, SA token"
        controller -> presets "Reads baseConfigMapRef"
        gateway -> epp "ext_proc" "gRPC/9002, TLS no verify"
        gateway -> sidecar "Routes to InferencePool target" "HTTP/8000"
        epp -> redis "KV-cache index" "RESP/8100, no auth"
        sidecar -> prefill "Prefill request" "HTTP/8000"
        sidecar -> decode "Decode request" "HTTP/8001 localhost"
        prefill -> decode "KV transfer" "NIXL 5557/TCP + UCX"
        decode -> redis "LMCache lookup" "RESP/8100"
        decode -> hf "Model pull" "HTTPS/443, Bearer HF_TOKEN"
        prefill -> hf "Model pull" "HTTPS/443, Bearer HF_TOKEN"
        epp -> hf "Tokenizer download" "HTTPS/443, Bearer HF_TOKEN"
        prom -> decode "Scrape /metrics" "HTTP/8000"
        prom -> epp "Scrape /metrics" "HTTP/9090, Bearer SA token"
        grafana -> thanos "Queries" "HTTPS/9091, tlsSkipVerify"
        deployer -> gwProvider "Uses for Gateway"
        deployer -> gie "Consumes CRDs"
        deployer -> registries "Pulls images" "HTTPS/443"
        deployer -> gpuOp "Requires GPUs"
        deployer -> modelService "Deploys image + CRD"
        deployer -> scheduler "Deploys EPP image"
        deployer -> kvcache "KV-cache scoring via EPP / LMCache"
        infra -> deployer "Supersedes"
        kserve -> deployer "Replaces in RHOAI"
    }

    views {
        systemContext deployer "SystemContext" {
            include *
            autoLayout
        }

        container deployer "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
            }
        }
    }
}

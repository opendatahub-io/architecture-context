workspace "llm-d-pd-utils" "Diagnostic tooling for llm-d prefill/decode (P/D) disaggregated deployments" {

    model {
        operator = person "llm-d Operator / SRE" "Validates GPU topology, RDMA/TCP networking and KV-cache transfer performance"
        agent = person "AI Coding Agent (Claude Code)" "Runs the Agentic Skills from natural-language prompts"

        pdUtils = softwareSystem "llm-d-pd-utils" "Agentic Skills, Python test runners and NIXL benchmark manifests. Tooling only: no controller, CRD or long-running service" {
            preflightSkill = container "/llm-d-preflight-checks skill" "Instructs the agent to inject the preflight script via ConfigMap + kustomize patch" "SKILL.md"
            preflightScript = container "llm-d-preflight-checks.py" "Runs before vllm serve; prints diagnostics; pause mode serves /health, /info, /exit on 8000/TCP (plain HTTP, no auth)" "Python 3 stdlib (in-pod)"
            networkingSkill = container "/llm-d-networking-tests skill" "Instructs the agent how to run and interpret the network test suite" "SKILL.md"
            runTests = container "run-tests.sh / run-tests.py" "Pod discovery, perftest, iperf3, NCCL/RCCL, nixlbench, preflight control, matplotlib plots" "Python >=3.10 via uv"
            benchmark = container "NIXL benchmark" "benchmark.py + benchmark_deployment.sh + deployment/nixl_*.yaml; NIXL READ/WRITE over ZMQ 5555 + UCX" "Python, Bash, Kubernetes YAML"
            image = container "NIXL benchmark image" "CUDA 12.5.1 / Ubuntu 24.04, MOFED, gdrcopy, UCX 1.18.0, NIXL 0.1.1" "Dockerfile"
        }

        k8sApi = softwareSystem "Kubernetes API server" "kubectl get/exec/debug, oc apply" "External"
        modelServer = softwareSystem "llm-d vLLM model-server pods" "Target of preflight injection and network tests (label llm-d.ai/model)" "Internal RHOAI"
        llmdGuides = softwareSystem "llm-d deployment guides" "quickstart, pd-disaggregation, llm-d-benchmark kustomize overlays" "Internal RHOAI"
        nixlConnector = softwareSystem "vLLM NIXL KV connector" "P/D KV-cache transfer path (NIXL/UCX) under test" "Internal RHOAI"
        gie = softwareSystem "Gateway API Inference Extension CRDs" "Prerequisite installed with llm-d quickstart" "Internal RHOAI"
        nvidiaOps = softwareSystem "NVIDIA GPU & Network Operators" "nvidia.com/gpu, nvidia.com/roce_gdr scheduling" "External"
        multus = softwareSystem "Multus CNI" "multi-nic-network secondary RoCE NICs" "External"
        github = softwareSystem "GitHub / PyPI / package mirrors" "Source and package downloads for --install-deps (no checksum verification)" "External"
        vendorRegistries = softwareSystem "nvcr.io / content.mellanox.com / developer.nvidia.com" "CUDA base image, MOFED, Nsight Systems" "External"
        ghcr = softwareSystem "ghcr.io/llm-d" "Release image registry (GHCR_TOKEN)" "External"

        operator -> agent "Prompts"
        operator -> runTests "Runs directly" "CLI"
        agent -> preflightSkill "Follows"
        agent -> networkingSkill "Follows"
        networkingSkill -> runTests "Drives"
        preflightSkill -> llmdGuides "Writes *-preflight kustomize overlay in llm-d checkout"
        preflightSkill -> k8sApi "Creates ConfigMap, patches modelserver Deployment" "HTTPS/6443 kubeconfig"
        preflightScript -> modelServer "Gates vllm serve (&&) inside the pod" "HTTP/8000 no auth"
        runTests -> k8sApi "get pods, exec, debug" "HTTPS/6443 TLS 1.2+ kubeconfig"
        runTests -> modelServer "Runs perftest/iperf3/NCCL/nixlbench, --unpause via kubectl exec curl" "RDMA/TCP/UDP/SSH/HTTP"
        runTests -> github "Installs/builds test tools in pods" "HTTPS/443"
        runTests -> nixlConnector "Validates NIXL/UCX transfer performance" "UCX"
        benchmark -> k8sApi "oc apply Pods + NodePort Service" "HTTPS/6443"
        benchmark -> nvidiaOps "Requests GPUs / RoCE devices"
        benchmark -> multus "Attaches multi-nic-network"
        benchmark -> nixlConnector "Benchmarks NIXL READ/WRITE" "ZMQ 5555 + UCX tcp/rc"
        image -> vendorRegistries "Pulls base image and vendor libs at build" "HTTPS/443"
        image -> ghcr "Published by CI on v* tags"
        modelServer -> gie "Deployed alongside (quickstart prerequisite)"
    }

    views {
        systemContext pdUtils "SystemContext" {
            include *
            autoLayout lr
        }

        container pdUtils "Containers" {
            include *
            autoLayout lr
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
                background #6fa8dc
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}

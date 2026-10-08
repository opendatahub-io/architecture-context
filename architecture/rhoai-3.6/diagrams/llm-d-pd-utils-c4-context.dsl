workspace {
    model {
        operator = person "Operator / SRE" "Runs diagnostics and benchmarks against llm-d pods"

        pdUtils = softwareSystem "llm-d-pd-utils" "Operational utility toolkit for llm-d prefill/decode disaggregated inference" {
            preflightChecks = container "llm-d-preflight-checks" "Gates vLLM startup with GPU topology diagnostics and optional HTTP pause server" "Python Script / Agentic Skill"
            networkTests = container "llm-d-networking-tests" "Orchestrates RDMA/TCP network performance tests between pod pairs" "Python Script Suite / Agentic Skill"
            nixlBenchmark = container "NIXL Benchmark" "Measures GPU VRAM-to-VRAM transfer throughput over UCX" "Python + PyTorch + ZMQ"
            nixlInstallers = container "NIXL Installers" "Install NIXL, UCX, gdrcopy in root and non-root containers" "Shell Scripts"
        }

        vllm = softwareSystem "llm-d Model Server" "vLLM-based LLM inference serving with prefill/decode disaggregation" "Internal llm-d"
        benchmark = softwareSystem "llm-d-benchmark" "Benchmark suite for llm-d inference performance" "Internal llm-d"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for pod management and kubectl exec" "External"
        gpuPlugin = softwareSystem "NVIDIA GPU Device Plugin" "Allocates GPU resources to pods" "External"
        multus = softwareSystem "Multus CNI" "Multi-NIC networking for RDMA/RoCE" "External"

        nixl = softwareSystem "NIXL" "GPU memory transfer library for VRAM-to-VRAM data movement" "External"
        ucx = softwareSystem "UCX" "Unified Communication X framework for RDMA/TCP transport" "External"
        gdrcopy = softwareSystem "gdrcopy" "GPU Direct RDMA copy library" "External"

        github = softwareSystem "GitHub" "Source code hosting for NIXL, UCX, gdrcopy downloads" "External"
        mellanox = softwareSystem "Mellanox Content" "MLNX_OFED driver distribution" "External"
        nvidia = softwareSystem "NVIDIA Developer" "Nsight Systems distribution" "External"

        operator -> pdUtils "Runs diagnostic and benchmark scripts"
        operator -> k8sAPI "Uses kubectl to manage pods" "HTTPS/443"

        preflightChecks -> vllm "Injected via ConfigMap, gates vLLM startup"
        preflightChecks -> k8sAPI "Reads pod environment" "kubectl exec"
        networkTests -> k8sAPI "Executes tests inside pods" "kubectl exec HTTPS/443"
        networkTests -> vllm "Discovers and tests llm-d pods"

        nixlBenchmark -> nixl "Uses for GPU VRAM transfers" "UCX transport"
        nixlBenchmark -> gpuPlugin "Requests nvidia.com/gpu resources"

        nixlInstallers -> nixl "Installs from source"
        nixlInstallers -> ucx "Installs UCX v1.18.0-v1.20.1"
        nixlInstallers -> gdrcopy "Installs gdrcopy v2.5-v2.5.2"

        pdUtils -> github "Downloads source tarballs" "HTTPS/443"
        pdUtils -> mellanox "Downloads MLNX_OFED drivers" "HTTPS/443"
        pdUtils -> nvidia "Downloads Nsight Systems" "HTTPS/443"

        preflightChecks -> benchmark "Can be included in preprocess ConfigMap"
        vllm -> multus "RoCE deployments use Multus CNI annotations"
    }

    views {
        systemContext pdUtils "SystemContext" {
            include *
            autoLayout
        }

        container pdUtils "Containers" {
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
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

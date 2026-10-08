workspace {
    model {
        operator = person "Operator / SRE" "Runs diagnostics and benchmarks on llm-d clusters"

        pdUtils = softwareSystem "llm-d-pd-utils" "Operational utilities for diagnosing, benchmarking, and validating GPU networking in llm-d disaggregated inference deployments" {
            preflight = container "Preflight Checks" "Gathers GPU topology, NVLink, CPU, PCI diagnostics; optionally gates vLLM startup with HTTP server" "Python Script / HTTP Server"
            networkTests = container "Networking Tests Suite" "Automated RDMA, iperf3, NCCL/RCCL, nixlbench tests between pods with GPU topology discovery" "Python Scripts"
            benchmark = container "NIXL Benchmark" "Measures GPU VRAM-to-VRAM throughput between creator/peer agents using PyTorch, NIXL, and ZMQ" "Python Script"
            installers = container "NIXL Installers" "Install NIXL, UCX, and gdrcopy from source for root and non-root environments" "Bash Scripts"
        }

        llmd = softwareSystem "llm-d (vLLM)" "Disaggregated LLM inference system with prefill/decode separation" "Internal Platform"
        llmdBenchmark = softwareSystem "llm-d-benchmark" "LLM-d benchmarking framework" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster orchestration and pod management" "External"
        nvidiaGPU = softwareSystem "NVIDIA GPU" "A100 SXM4 GPUs for compute and VRAM transfers" "External"
        nixlLib = softwareSystem "NIXL Library" "GPU VRAM-to-VRAM data transfer via UCX" "External"
        ucx = softwareSystem "UCX Runtime" "Unified Communication X for RDMA/TCP networking" "External"
        multus = softwareSystem "Multus CNI" "Multi-network attachment for RoCE interfaces" "External"
        github = softwareSystem "GitHub" "Source code hosting for NIXL, UCX, gdrcopy downloads" "External"

        # Relationships
        operator -> pdUtils "Runs diagnostics and benchmarks via kubectl"
        operator -> preflight "Inspects environment via HTTP /info, releases hold via /exit" "HTTP/8000"
        operator -> networkTests "Executes test suites" "CLI"

        preflight -> llmd "Gates vLLM startup via && chaining in container command"
        preflight -> nvidiaGPU "Queries GPU topology via nvidia-smi"

        networkTests -> k8sAPI "Discovers pods and executes commands" "HTTPS/443"

        benchmark -> nixlLib "GPU VRAM-to-VRAM transfers" "Python API"
        benchmark -> ucx "High-performance networking transport" "RDMA/TCP"
        benchmark -> nvidiaGPU "Allocates PyTorch tensors on GPU"

        pdUtils -> llmdBenchmark "Preflight included in preprocesses ConfigMap"
        pdUtils -> multus "RoCE variants use multi-nic-network annotation"

        installers -> github "Downloads source tarballs" "HTTPS/443"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
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

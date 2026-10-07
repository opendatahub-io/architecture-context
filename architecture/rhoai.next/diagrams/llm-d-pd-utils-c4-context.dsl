workspace {
    model {
        operator = person "Cluster Operator" "Validates GPU networking and infrastructure health in llm-d deployments"

        llmdPdUtils = softwareSystem "llm-d-pd-utils" "Preflight diagnostics, network performance testing, and NIXL benchmarking utilities for llm-d GPU-accelerated LLM serving" {
            preflightChecks = container "Preflight Checks" "Pre-vLLM startup diagnostics with optional pause mode HTTP server" "Python Script"
            networkingTests = container "Networking Test Suite" "Unified test runner for perftest, iperf3, NCCL/RCCL, NIXL benchmarks" "Python Suite"
            nixlBenchmark = container "NIXL Benchmark" "GPU VRAM-to-VRAM data transfer throughput measurement" "Python Script"
            nixlInstaller = container "NIXL Installer" "Builds and installs NIXL, UCX, gdrcopy from source" "Shell Script"
            nixlContainer = container "NIXL Container Image" "Pre-built CUDA-based image with NIXL, UCX, gdrcopy" "Docker"
        }

        llmdModelServer = softwareSystem "llm-d Model Server" "vLLM-based LLM serving pods in the llm-d ecosystem" "Internal llm-d"
        llmdInfra = softwareSystem "llm-d-infra" "Helm charts for llm-d deployment configuration" "Internal llm-d"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for pod management and discovery" "External"
        nvidiaGpu = softwareSystem "NVIDIA GPU Hardware" "GPU compute, NVLink, RDMA capabilities" "External"
        ucxTransport = softwareSystem "UCX Transport" "Unified Communication X framework for RDMA/TCP data transfer" "External"
        multusCni = softwareSystem "Multus CNI" "Multi-NIC network plugin for RDMA support" "External"

        # External egress (build-time)
        github = softwareSystem "GitHub" "Source tarball downloads for NIXL, UCX, gdrcopy" "External"
        nvidiaRegistry = softwareSystem "NVIDIA Container Registry" "CUDA base images and MLNX_OFED drivers" "External"
        pypi = softwareSystem "PyPI" "Python package repository (torch, zmq, numpy)" "External"

        # Relationships
        operator -> llmdPdUtils "Runs diagnostics and benchmarks via kubectl and uv"
        operator -> preflightChecks "Inspects pod state via HTTP (GET /info, /exit)" "HTTP/8000"
        operator -> networkingTests "Executes network performance tests" "uv run"

        preflightChecks -> llmdModelServer "Injected into vLLM container startup chain" "entrypoint && chain"
        preflightChecks -> nvidiaGpu "Inspects GPU topology via nvidia-smi" "subprocess"

        networkingTests -> k8sApi "Discovers pods, kubectl exec into test targets" "HTTPS/443"
        networkingTests -> llmdModelServer "Runs perftest/iperf3/NCCL between pod pairs" "kubectl exec"

        nixlBenchmark -> nvidiaGpu "Allocates VRAM tensors via CUDA" "CUDA API"
        nixlBenchmark -> ucxTransport "Transfers data between GPU VRAM via NIXL" "RDMA/TCP"

        nixlInstaller -> github "Downloads source tarballs" "HTTPS/443"
        nixlContainer -> nvidiaRegistry "Pulls CUDA base image, MLNX_OFED drivers" "HTTPS/443"
        nixlContainer -> pypi "Installs Python dependencies" "HTTPS/443"

        llmdInfra -> preflightChecks "Planned Helm integration for ConfigMap mounting"
        networkingTests -> multusCni "RoCE variants use multi-nic-network annotation"
    }

    views {
        systemContext llmdPdUtils "SystemContext" {
            include *
            autoLayout
        }

        container llmdPdUtils "Containers" {
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

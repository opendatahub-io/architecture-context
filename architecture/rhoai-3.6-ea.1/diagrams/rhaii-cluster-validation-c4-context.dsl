workspace {
    model {
        admin = person "Cluster Administrator" "Validates cluster readiness for AI workloads"

        rhaiiValidator = softwareSystem "rhaii-cluster-validation" "Preflight validation CLI for GPU, RDMA, network, CRD, and operator readiness" {
            cli = container "rhaii-validator CLI" "Cobra CLI application, kubectl plugin" "Go 1.26 (FIPS)"
            controller = container "Controller" "Orchestrates validation Jobs, collects results, handles cleanup" "Go"
            crdChecker = container "CRD Checker" "Validates presence of required CRDs via API" "Go"
            operatorChecker = container "Operator Checker" "Validates operator pod health in target namespaces" "Go"
            agentPod = container "Agent Pod" "Per-node privileged Job for GPU/RDMA/network validation" "Go Container (privileged)"
            platformConfig = container "Platform Config" "Embedded YAML profiles (ocp.yaml) with thresholds and requirements" "YAML"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"

        gatewayAPI = softwareSystem "Gateway API" "Gateway API CRDs (gateways, httproutes)" "Validation Target"
        inferencePool = softwareSystem "Gateway API Inference Extension" "InferencePool CRD" "Validation Target"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "LeaderWorkerSet operator and CRD" "Validation Target"
        certManager = softwareSystem "cert-manager" "Certificate management operator and CRD" "Validation Target"
        istio = softwareSystem "Istio" "Service mesh operator" "Validation Target"

        gpuHardware = softwareSystem "GPU Hardware" "NVIDIA GPU devices on cluster nodes" "Hardware"
        rdmaDevices = softwareSystem "RDMA Devices" "InfiniBand/RDMA NICs on cluster nodes" "Hardware"

        admin -> rhaiiValidator "Runs validation checks via CLI"
        cli -> controller "Delegates validation orchestration"
        controller -> platformConfig "Loads validation thresholds"
        controller -> crdChecker "Tier 1: CRD presence validation"
        controller -> operatorChecker "Tier 1: Operator health validation"
        controller -> k8sAPI "Creates namespace, RBAC, Jobs; streams logs" "HTTPS/6443 TLS 1.2+"
        agentPod -> gpuHardware "Queries driver, ECC, memory" "Device files"
        agentPod -> rdmaDevices "Tests connectivity, bandwidth" "Device files"

        crdChecker -> k8sAPI "GET CRDs" "HTTPS/6443"
        operatorChecker -> k8sAPI "GET pods in operator namespaces" "HTTPS/6443"

        crdChecker -> gatewayAPI "Validates CRD existence"
        crdChecker -> inferencePool "Validates CRD existence"
        crdChecker -> leaderWorkerSet "Validates CRD existence"
        crdChecker -> certManager "Validates CRD existence"
        operatorChecker -> istio "Validates operator pod health"
        operatorChecker -> certManager "Validates operator pod health"
        operatorChecker -> leaderWorkerSet "Validates operator pod health"
    }

    views {
        systemContext rhaiiValidator "SystemContext" {
            include *
            autoLayout
        }

        container rhaiiValidator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Validation Target" {
                background #fff2cc
                color #333333
            }
            element "Hardware" {
                background #f8cecc
                color #333333
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}

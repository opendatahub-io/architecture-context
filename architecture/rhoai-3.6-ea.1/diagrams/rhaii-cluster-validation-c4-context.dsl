workspace {
    model {
        admin = person "Cluster Administrator" "Validates cluster readiness before AI workload deployment"

        rhaiiValidator = softwareSystem "rhaii-cluster-validation" "Preflight validation CLI for xKS clusters — verifies GPU, RDMA, network, CRDs, and operator health" {
            cli = container "Cobra CLI" "Entrypoint dispatching validation suites (gpu, network, rdma, deps, all)" "Go CLI"
            controller = container "Controller" "Orchestrates Kubernetes Jobs on target nodes, manages RBAC scaffold, aggregates results" "Go"
            agent = container "Agent" "Executes hardware and network checks on worker nodes via internal sub-commands" "Go (privileged SCC)"
            crdChecker = container "CRD/Operator Checker" "Queries Kubernetes API for required CRDs and operator namespace presence" "Go"
            platformConfig = container "Platform Config" "Embedded YAML profiles per target platform (OCP, EKS, CoreWeave)" "YAML"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API" "External" {
            tags "External"
        }

        workerNodes = softwareSystem "Worker Node Hardware" "GPU, RDMA, NIC hardware on cluster worker nodes" "External" {
            tags "External"
        }

        gatewayAPI = softwareSystem "Gateway API" "CRDs: Gateways, HTTPRoutes" "Validation Target" {
            tags "ValidationTarget"
        }
        inferencePool = softwareSystem "InferencePool" "InferencePool CRD" "Validation Target" {
            tags "ValidationTarget"
        }
        leaderWorkerSet = softwareSystem "LeaderWorkerSet" "LeaderWorkerSet CRD and operator" "Validation Target" {
            tags "ValidationTarget"
        }
        certManager = softwareSystem "cert-manager" "cert-manager CRD and operator" "Validation Target" {
            tags "ValidationTarget"
        }
        istio = softwareSystem "Istio" "Service mesh operator" "Validation Target" {
            tags "ValidationTarget"
        }

        # System context relationships
        admin -> rhaiiValidator "Invokes CLI with validation suite" "CLI / kubectl plugin"
        rhaiiValidator -> k8sAPI "Creates NS, SA, RBAC, Jobs, ConfigMap; queries CRDs" "HTTPS/6443, TLS 1.2+"
        rhaiiValidator -> workerNodes "Inspects GPU, RDMA, NIC via privileged Job pods" "sysfs, IB verbs, TCP/iperf3"

        # Validation target queries (read-only)
        rhaiiValidator -> gatewayAPI "Checks CRD presence" "Kubernetes API discovery"
        rhaiiValidator -> inferencePool "Checks CRD presence" "Kubernetes API discovery"
        rhaiiValidator -> leaderWorkerSet "Checks CRD and operator presence" "Kubernetes API discovery"
        rhaiiValidator -> certManager "Checks CRD and operator presence" "Kubernetes API discovery"
        rhaiiValidator -> istio "Checks operator namespace presence" "Kubernetes API discovery"

        # Container relationships
        admin -> cli "Runs rhaii-validator or kubectl-rhaii_validate"
        cli -> controller "Dispatches validation suite"
        controller -> crdChecker "Invokes dependency checks"
        controller -> platformConfig "Loads platform-specific thresholds"
        controller -> k8sAPI "Creates resources, deploys Jobs" "HTTPS/6443"
        crdChecker -> k8sAPI "Queries CRDs and operator namespaces" "HTTPS/6443"
        agent -> workerNodes "Reads sysfs, runs ibv/iperf3 tests" "Host access via privileged SCC"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "ValidationTarget" {
                background #d4a574
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

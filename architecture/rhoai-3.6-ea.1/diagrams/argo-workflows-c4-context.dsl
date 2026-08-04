workspace {
    model {
        dspOperator = person "DSP Operator" "Data Science Pipelines Operator that deploys and manages Argo Workflows"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow execution engine for Data Science Pipelines in RHOAI" {
            workflowController = container "Workflow Controller" "Watches Workflow CRDs and orchestrates pod-based step execution via reconciliation loop" "Go Operator"
            argoServer = container "Argo Server" "Exposes combined gRPC+HTTP gateway on port 2746 for workflow management, artifact access, and observability" "Go Service"
            gatekeeper = container "Auth Gatekeeper" "gRPC interceptor enforcing authentication via Client (bearer delegation), Server (SA), or SSO (OIDC) modes" "Go Middleware"
            argoexec = container "argoexec" "Sidecar/init container in workflow step pods managing artifact I/O and container lifecycle" "Go Sidecar"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        dspPipelines = softwareSystem "Data Science Pipelines" "Pipeline orchestration system that submits Workflow CRs" "Internal RHOAI"

        dspOperator -> argoWorkflows "Deploys and configures"
        dspPipelines -> argoWorkflows "Submits Workflow CRs for pipeline execution"

        argoServer -> gatekeeper "Authenticates requests via"
        gatekeeper -> kubernetesAPI "Delegates bearer tokens (Client mode)" "HTTPS/6443"
        workflowController -> kubernetesAPI "Manages Pods, ConfigMaps, Secrets, PDBs, CRDs" "HTTPS+WSS/6443"
        argoServer -> kubernetesAPI "CRUD operations on workflows and resources" "HTTPS/6443"
        argoexec -> kubernetesAPI "Reports task results, manages artifacts" "HTTPS/6443"

        workflowController -> argoexec "Creates step pods with argoexec sidecar"

        prometheus -> argoServer "Scrapes /metrics endpoint" "HTTP/2746"
    }

    views {
        systemContext argoWorkflows "SystemContext" {
            include *
            autoLayout
        }

        container argoWorkflows "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

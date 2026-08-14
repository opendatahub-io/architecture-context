workspace {
    model {
        dsPipelineController = person "DSP Controller" "Data Science Pipelines controller that submits workflows"
        datascientist = person "Data Scientist" "Creates and monitors ML workflows via UI or CLI"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow execution engine for Data Science Pipelines" {
            argoServer = container "Argo Server" "Unified API surface co-hosting gRPC and HTTP reverse proxy (grpc-gateway) with artifact endpoints and OAuth2 handlers" "Go Service, Port 2746"
            gatekeeper = container "Gatekeeper Interceptor" "Centralized authentication interceptor supporting Bearer, SSO/OIDC, and server SA modes" "Go Interceptor"
            workflowController = container "Workflow Controller" "Reconciles Workflow and related CRDs, orchestrates pod creation, manages memoization cache and artifact GC" "Go Controller, Port 6060 (health)"
            argoexec = container "argoexec" "Sidecar/init container in workflow pods handling artifact collection, script execution, and container lifecycle" "Go Sidecar"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Kubernetes control plane API server" "External"
        artifactStorage = softwareSystem "Artifact Storage" "Object storage for workflow artifacts (S3, GCS, Azure Blob, HDFS, MinIO)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # User interactions
        datascientist -> argoWorkflows "Submits and monitors workflows via CLI/UI" "gRPC + HTTP/2746"
        dsPipelineController -> argoWorkflows "Creates workflow CRs for pipeline runs" "Kubernetes API"

        # Internal container relationships
        gatekeeper -> argoServer "Authenticates requests before forwarding"
        argoServer -> kubernetesAPI "CRUD operations on workflow CRs" "HTTPS/6443"
        argoServer -> artifactStorage "Serves artifact downloads" "HTTPS"
        workflowController -> kubernetesAPI "Watches CRDs, creates Pods, ConfigMaps, PDBs" "HTTPS+WSS/6443"
        argoexec -> artifactStorage "Uploads/downloads workflow artifacts" "HTTPS"
        argoexec -> kubernetesAPI "Updates WorkflowTaskResult CR" "HTTPS/6443"
        workflowController -> argoexec "Spawns as sidecar in workflow pods"

        # External integrations
        argoWorkflows -> kubernetesAPI "All resource operations" "HTTPS/6443, TLS 1.2+"
        argoWorkflows -> artifactStorage "Artifact storage and retrieval" "HTTPS"
        argoWorkflows -> prometheus "Exposes /metrics endpoint" "HTTP/2746"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

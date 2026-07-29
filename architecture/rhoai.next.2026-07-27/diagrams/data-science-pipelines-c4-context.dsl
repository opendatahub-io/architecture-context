workspace {
    model {
        user = person "Data Scientist" "Creates and runs ML pipelines, uploads pipeline definitions, monitors runs"

        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines-based ML workflow orchestration platform for defining, scheduling, and running ML pipelines" {
            apiserver = container "ml-pipeline API Server" "REST and gRPC API for pipeline management, run orchestration, and artifact storage" "Go Service" {
                tags "Primary"
            }
            ui = container "ml-pipeline-ui" "Web frontend for pipeline visualization, run monitoring, and artifact browsing" "React App"
            vizServer = container "ml-pipeline-visualizationserver" "Generates pipeline run visualizations" "Python Service"
            cacheServer = container "cache-server" "Mutating/validating webhook for PipelineVersion caching" "Go Webhook"
            cacheDeployer = container "cache-deployer" "Deploys and manages cache webhook certificates" "Go Job"
            persistAgent = container "persistence-agent" "Watches Argo Workflows and reports run status to API server" "Go Agent"
            scheduledWF = container "scheduled-workflow" "Manages ScheduledWorkflow CRs, creates Argo Workflows on schedule" "Go Controller"
            viewerCRD = container "viewer-crd" "Reconciles Viewer CRs to create visualization deployments" "Go Controller"
            metadataEnvoy = container "metadata-envoy" "Envoy proxy fronting ML Metadata Store gRPC service" "Envoy Proxy"
            metadataGRPC = container "metadata-grpc" "ML Metadata Store server for pipeline execution metadata" "C++ gRPC Service"
            metadataWriter = container "metadata-writer" "Watches Argo Workflows and writes execution metadata to MLMD" "Python Agent"
            mysql = container "MySQL" "Shared relational backend for pipeline metadata, cache, and MLMD" "MySQL 8.4"
            seaweedfs = container "SeaweedFS" "S3-compatible object storage for pipeline artifacts" "SeaweedFS 4.30"
        }

        argoWF = softwareSystem "Argo Workflows" "Kubernetes-native workflow engine for pipeline step execution" "External" {
            tags "External"
        }
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management and RBAC" "External" {
            tags "External"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External" {
            tags "External"
        }
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbench management" "Internal ODH" {
            tags "Internal"
        }
        s3Storage = softwareSystem "S3-compatible Storage" "External object storage for runtime artifacts" "External" {
            tags "External"
        }

        # User interactions
        user -> ui "Browses pipelines, monitors runs via" "HTTPS"
        user -> apiserver "Creates pipelines, submits runs via" "REST/gRPC"

        # Internal container relationships
        ui -> apiserver "Fetches pipeline data, artifacts" "HTTP/8888"
        apiserver -> mysql "Stores pipeline metadata" "MySQL/3306"
        apiserver -> seaweedfs "Stores pipeline artifacts" "S3/8333"
        cacheServer -> mysql "Checks/updates cache entries" "MySQL/3306"
        metadataGRPC -> mysql "Stores execution metadata" "MySQL/3306"
        metadataEnvoy -> metadataGRPC "Proxies gRPC requests" "gRPC/8080"
        metadataWriter -> metadataEnvoy "Writes execution metadata" "gRPC/9090"
        persistAgent -> apiserver "Reports workflow status" "HTTP/8888"
        ui -> seaweedfs "Reads artifacts" "S3/8333"

        # External system interactions
        apiserver -> argoWF "Creates and manages workflow execution" "Kubernetes API"
        apiserver -> k8sAPI "RBAC, resource management, tokenreviews" "HTTPS/6443"
        scheduledWF -> argoWF "Creates scheduled Argo Workflows" "Kubernetes API"
        persistAgent -> argoWF "Watches workflow status" "Kubernetes API"
        metadataWriter -> argoWF "Watches workflow events" "Kubernetes API"
        prometheus -> apiserver "Scrapes metrics" "HTTP/8888"
        apiserver -> kubeflowNotebooks "Creates notebook workbenches" "HTTPS"
        apiserver -> s3Storage "Stores/retrieves runtime artifacts" "HTTP/HTTPS"
        k8sAPI -> cacheServer "Admission webhook calls" "HTTPS/8443"
    }

    views {
        systemContext dsp "SystemContext" {
            include *
            autoLayout
        }

        container dsp "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Primary" {
                background #1168bd
                color #ffffff
            }
        }
    }
}

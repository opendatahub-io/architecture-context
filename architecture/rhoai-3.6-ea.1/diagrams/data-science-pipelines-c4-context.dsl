workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, runs, and monitors ML pipelines"
        mlEngineer = person "ML Engineer" "Deploys and manages pipeline infrastructure"

        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines backend providing gRPC and REST APIs for ML pipeline lifecycle management with Kubernetes-native authentication" {
            apiServer = container "ml-pipeline API Server" "Central control plane exposing 10 gRPC services and REST endpoints for pipeline management" "Go (FIPS 140)"
            persistenceAgent = container "Persistence Agent" "Synchronizes Argo Workflow state back to the pipeline store" "Go"
            scheduledWorkflowCtrl = container "Scheduled Workflow Controller" "Reconciles ScheduledWorkflow CRDs to trigger pipeline runs on cron schedules" "Go"
            cacheServer = container "Cache Server" "Mutating admission webhook enabling execution caching for pipeline steps" "Go"
            viewerCrdCtrl = container "Viewer CRD Controller" "Manages Viewer custom resources by creating Deployments and Services" "Go"
            metadataEnvoy = container "Metadata Envoy" "Envoy proxy for metadata gRPC traffic" "Envoy"
            metadataGrpcStore = container "Metadata gRPC Store" "ML metadata persistence service" "ml_metadata_store_server 1.14.0"
            metadataWriter = container "Metadata Writer" "Watches Argo Workflows and writes execution metadata" "Python"
            frontend = container "ml-pipeline-ui" "Web UI for pipeline management" "Node.js"
            vizServer = container "Visualization Server" "Serves pipeline visualizations" "Python"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine for pipeline steps" "External" {
            tags "External"
        }
        mysql = softwareSystem "MySQL" "Relational database for pipeline metadata" "External" {
            tags "External"
        }
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for pipeline artifacts (SeaweedFS/MinIO)" "External" {
            tags "External"
        }
        kubernetesApi = softwareSystem "Kubernetes API Server" "Cluster API for resource management, TokenReview, SubjectAccessReview" "External" {
            tags "External"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI" {
            tags "Internal"
        }
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbench management" "Internal RHOAI" {
            tags "Internal"
        }

        # User interactions
        dataScientist -> dsp "Creates and runs ML pipelines via SDK/CLI"
        mlEngineer -> dsp "Manages pipeline infrastructure and schedules"
        dataScientist -> frontend "Views pipeline status and results" "HTTP/80"

        # System-level interactions
        dsp -> argoWorkflows "Orchestrates pipeline step execution" "Kubernetes API"
        dsp -> mysql "Stores pipeline metadata and run records" "MySQL/3306"
        dsp -> s3Storage "Stores pipeline artifacts and logs" "S3 API/HTTPS"
        dsp -> kubernetesApi "TokenReview, SubjectAccessReview, resource CRUD" "HTTPS/6443"
        prometheus -> dsp "Scrapes metrics" "HTTP/8888"
        dsp -> kubeflowNotebooks "Creates notebook workbenches" "Kubernetes API"

        # Container-level interactions
        dataScientist -> apiServer "gRPC/REST API calls" "8443/8887/8888 TCP"
        apiServer -> kubernetesApi "TokenReview authentication, SubjectAccessReview authorization" "HTTPS/6443"
        apiServer -> mysql "Pipeline metadata queries" "MySQL/3306"
        apiServer -> s3Storage "Pipeline artifact storage" "S3 API (AWS SDK v2)"

        persistenceAgent -> argoWorkflows "Watches workflow status" "Kubernetes API"
        persistenceAgent -> apiServer "Reports run status"

        scheduledWorkflowCtrl -> argoWorkflows "Creates workflows on schedule" "Kubernetes API"

        cacheServer -> argoWorkflows "Intercepts pod creation" "Admission Webhook/443 TLS"

        metadataWriter -> argoWorkflows "Watches workflow resources" "Kubernetes API"
        metadataWriter -> metadataEnvoy "Writes execution metadata" "gRPC/9090"
        metadataEnvoy -> metadataGrpcStore "Proxies gRPC requests" "gRPC/8080"

        viewerCrdCtrl -> kubernetesApi "Creates Deployments and Services" "HTTPS/6443"

        frontend -> apiServer "API calls for UI" "HTTP"
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
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
        }
    }
}

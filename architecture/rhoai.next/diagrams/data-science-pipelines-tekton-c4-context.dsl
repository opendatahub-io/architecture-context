workspace {
    model {
        user = person "Data Scientist" "Authors, schedules, and monitors ML pipelines"
        admin = person "Platform Admin" "Manages pipeline platform configuration and multi-user access"

        dsp = softwareSystem "Data Science Pipelines Tekton" "Tekton-based backend for Kubeflow Pipelines, enabling ML pipeline authoring, scheduling, execution, caching, and artifact tracking" {
            apiserver = container "API Server" "Core service exposing gRPC and REST APIs for pipeline CRUD, run management, experiment tracking" "Go Service" "8888/HTTP, 8887/gRPC"
            frontend = container "Frontend" "React-based web UI for pipeline management" "TypeScript/Node.js" "3000/TCP"
            cacheServer = container "Cache Server" "Mutating admission webhook for pipeline step caching" "Go Webhook" "8443/HTTPS"
            persistenceAgent = container "Persistence Agent" "Synchronizes Tekton PipelineRun status to metadata store" "Go Agent"
            scheduledWorkflow = container "ScheduledWorkflow Controller" "Reconciles ScheduledWorkflow CRs for recurring runs" "Go Controller"
            viewerController = container "Viewer Controller" "Provisions visualization Deployments on demand" "Go Controller"
            vizServer = container "Visualization Server" "Renders pipeline output visualizations as HTML" "Python Service" "8888/TCP"
            metadataWriter = container "Metadata Writer" "Writes pipeline metadata to ML Metadata service" "Python Agent"
            pipelineLoops = container "Pipeline Loops Controller" "Implements looping semantics for Tekton pipelines" "Go Controller"
            cacheDeployer = container "Cache Deployer" "Provisions webhook configuration and TLS certificates" "Shell Job"
        }

        tekton = softwareSystem "Tekton Pipelines" "Kubernetes-native pipeline execution engine (v0.41.0)" "External"
        mysql = softwareSystem "MySQL" "Relational database for pipeline metadata, runs, experiments, and cache" "External"
        minio = softwareSystem "MinIO" "S3-compatible object storage for pipeline artifacts" "External"
        mlmd = softwareSystem "ML Metadata" "gRPC service for pipeline metadata lineage tracking" "External"
        k8s = softwareSystem "Kubernetes API" "Cluster API for resource management, RBAC, admission control" "External"
        istio = softwareSystem "Istio" "Service mesh for mTLS, traffic management, and authorization policies" "External"

        # User interactions
        user -> frontend "Manages pipelines via web UI" "HTTP/80"
        user -> apiserver "Submits pipelines via SDK" "gRPC/8887, REST/8888"
        admin -> k8s "Configures RBAC and namespaces" "HTTPS/6443"

        # Internal interactions
        frontend -> apiserver "REST API calls" "HTTP/8888"
        apiserver -> vizServer "Delegates visualization rendering" "HTTP/8888"
        persistenceAgent -> apiserver "Syncs run status" "HTTP/8888"
        cacheDeployer -> cacheServer "Provisions TLS certs and webhook config"

        # External interactions
        apiserver -> mysql "Stores pipeline metadata" "TCP/3306"
        apiserver -> minio "Stores pipeline artifacts" "HTTP/9000"
        apiserver -> k8s "Creates PipelineRun CRs, RBAC checks" "HTTPS/6443"
        apiserver -> tekton "Executes pipelines via PipelineRun CRDs"
        cacheServer -> mysql "Cache lookups in cachedb" "TCP/3306"
        k8s -> cacheServer "Admission webhook calls" "HTTPS/443"
        persistenceAgent -> k8s "Watches PipelineRun status" "HTTPS/6443"
        scheduledWorkflow -> k8s "Creates recurring PipelineRuns" "HTTPS/6443"
        metadataWriter -> mlmd "Writes lineage metadata" "gRPC/8080"
        dsp -> istio "Uses for mTLS and authorization" "Service mesh"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

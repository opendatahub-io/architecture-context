workspace {
    model {
        dataScientist = person "Data Scientist" "Builds and deploys ML pipelines using the Python SDK or Web UI"
        mlEngineer = person "ML Engineer" "Manages pipeline infrastructure and recurring runs"

        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines fork providing end-to-end ML workflow orchestration on OpenShift (v2.16.1)" {
            apiserver = container "API Server" "Central service managing pipeline definitions, runs, experiments, and recurring runs. Serves REST, gRPC, and admission webhooks." "Go Service" "8888/TCP HTTP, 8887/TCP gRPC, 8443/TCP Webhooks"
            driver = container "Driver" "V2 engine sidecar that resolves pipeline step inputs, computes pod spec patches, and manages platform configuration." "Go Sidecar"
            launcher = container "Launcher v2" "V2 engine init container that downloads input artifacts, invokes executor, and uploads output artifacts." "Go Init Container"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflow status and synchronizes run state back to the API server." "Go Controller"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages ScheduledWorkflow CRs for recurring pipeline runs on cron schedules." "Go Controller"
            cacheServer = container "Cache Server" "Mutating admission webhook enabling pipeline step caching based on input fingerprints." "Go Webhook"
            viewer = container "Viewer Controller" "Manages Viewer CRs to create TensorBoard and visualization deployments." "Go Controller"
            metadataGRPC = container "ML Metadata gRPC" "Artifact and execution lineage tracking store." "gRPC Service"
            metadataEnvoy = container "Metadata Envoy Proxy" "Envoy sidecar proxying gRPC metadata traffic." "Envoy Proxy"
            metadataWriter = container "Metadata Writer" "Watches Argo Workflow pods and writes execution metadata to MLMD." "Python Service"
            ui = container "ML Pipeline UI" "React-based web UI for pipeline management, run visualization, and artifact browsing." "React 19 / Node.js"
            vizServer = container "Visualization Server" "Renders pipeline output visualizations (HTML/static) on demand." "Python Service"
            cacheDeployer = container "Cache Deployer" "Bootstrap job creating TLS secrets and webhook configurations for cache server." "Go Job"
        }

        argo = softwareSystem "Argo Workflows" "Pipeline execution engine using Workflow CRDs (v3.7.14)" "External"
        mysql = softwareSystem "MySQL" "Pipeline metadata persistence (v8.4)" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Pipeline artifact storage (MinIO, AWS S3, etc.)" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API for resource management, RBAC checks" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and configures DSP instances per-namespace in RHOAI" "Internal Platform"
        notebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbenches for pipeline development" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "Traffic management and authorization policies" "External"

        # External interactions
        dataScientist -> dsp "Submits pipelines via Python SDK or Web UI"
        mlEngineer -> dsp "Manages pipeline infrastructure and schedules"

        # Container-level interactions
        dataScientist -> ui "Browses pipelines, runs, and artifacts" "HTTP/80"
        dataScientist -> apiserver "Uploads and manages pipelines" "REST/gRPC with Bearer Token"
        ui -> apiserver "Proxies API requests" "HTTP/8888"
        apiserver -> mysql "Persists pipeline metadata" "MySQL/3306"
        apiserver -> s3 "Stores pipeline artifacts" "HTTP/HTTPS"
        apiserver -> k8sApi "Creates Workflows, RBAC checks" "HTTPS/6443"
        persistenceAgent -> k8sApi "Watches Workflow status" "HTTPS/6443"
        persistenceAgent -> apiserver "Reports run state" "HTTP/8888"
        scheduledWorkflow -> k8sApi "Manages ScheduledWorkflow CRs" "HTTPS/6443"
        driver -> k8sApi "Resolves inputs, patches pod specs" "HTTPS/6443"
        launcher -> s3 "Downloads/uploads artifacts" "HTTP/HTTPS"
        launcher -> metadataGRPC "Writes execution metadata" "gRPC/8080"
        cacheServer -> mysql "Checks cache fingerprints" "MySQL/3306"
        metadataWriter -> metadataGRPC "Writes artifact metadata" "gRPC/8080"
        metadataEnvoy -> metadataGRPC "Proxies gRPC traffic" "gRPC/8080"
        metadataGRPC -> mysql "Persists metadata" "MySQL/3306"
        viewer -> k8sApi "Creates visualization deployments" "HTTPS/6443"

        # Platform interactions
        dsp -> argo "Uses for pipeline execution" "Workflow CRDs"
        dsp -> istio "Uses for traffic mgmt and AuthorizationPolicy" "Service mesh"
        prometheus -> apiserver "Scrapes metrics" "HTTP/8888"
        prometheus -> scheduledWorkflow "Scrapes metrics" "HTTP/9090"
        dspo -> dsp "Deploys and configures instances" "Kubernetes API"
        dsp -> notebooks "Creates notebook workbenches" "CRD CRUD"
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

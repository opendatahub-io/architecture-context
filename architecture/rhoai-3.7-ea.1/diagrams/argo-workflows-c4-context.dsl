workspace "Argo Workflows (RHOAI 3.7-ea.1)" "C4 context for the argo-workflows component as shipped in RHOAI" {
    model {
        dataScientist = person "Data Scientist" "Authors and runs Kubeflow pipelines in a Data Science Project"

        argo = softwareSystem "Argo Workflows" "Kubernetes-native workflow engine; execution backend for Data Science Pipelines (KFP v2)" {
            controller = container "workflow-controller" "Reconciles Workflow/CronWorkflow CRs; creates step pods, PDBs, ConfigMaps; artifact GC; TTLs. One per DSPA namespace (--namespaced). Metrics 9090/TCP TLS, healthz 6060/TCP" "Go controller"
            argoexec = container "argoexec" "Init/wait/emissary process in each step pod; artifact I/O; writes WorkflowTaskResult" "Go executable"
            agent = container "argoexec agent" "Executes HTTP and plugin templates from WorkflowTaskSets" "Go executable"
            argoServer = container "argo-server" "Upstream UI and gRPC/REST API on 2746/TCP. NOT shipped in RHOAI" "Go API server" "NotShipped"
        }

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys workflow-controller per DSPA, renders ConfigMap, Role, NetworkPolicy; supplies argoexec image" "Internal RHOAI"
        kfp = softwareSystem "KFP API Server / Persistence Agent" "Submits pipeline runs as Workflow CRs and syncs status" "Internal RHOAI"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus scraping controller metrics" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes API Server" "CRs, Pods, ConfigMaps, Secrets, PDBs, Leases, Events" "External"
        objectStore = softwareSystem "Object Storage" "S3/MinIO, GCS, Azure Blob, Alibaba OSS, HDFS - artifacts and logs" "External"
        git = softwareSystem "Git Remotes" "Git input artifacts" "External"
        httpEndpoints = softwareSystem "User HTTP Endpoints" "Targets of HTTP templates" "External"

        dataScientist -> kfp "Creates pipeline runs" "HTTPS"
        dspo -> controller "Deploys and configures" "Kubernetes API"
        dspo -> argoexec "Supplies executor image" "--executor-image"
        kfp -> k8s "Creates Workflow CRs, watches status" "HTTPS/6443"
        controller -> k8s "Watches CRs; creates Pods, PDBs, ConfigMaps, WorkflowTaskSets; Lease leader election" "HTTPS/WSS 6443"
        controller -> argoexec "Injects into step pods" "Pod spec"
        controller -> agent "Creates agent pod + WorkflowTaskSet" "Pod spec"
        controller -> objectStore "Artifact GC, archived log retrieval" "HTTPS/443"
        argoexec -> k8s "Creates/patches WorkflowTaskResult, reads Secrets" "HTTPS/6443"
        argoexec -> objectStore "Reads inputs, writes outputs and logs" "HTTPS/443"
        argoexec -> git "Clones Git artifacts" "HTTPS/443, SSH/22"
        agent -> httpEndpoints "Executes HTTP templates (TLS verify optional)" "HTTP/HTTPS"
        agent -> k8s "Patches WorkflowTaskSet status" "HTTPS/6443"
        monitoring -> controller "Scrapes /metrics (no auth, NetworkPolicy restricted)" "HTTPS/9090"
    }

    views {
        systemContext argo "SystemContext" {
            include *
            autoLayout
        }

        container argo "Containers" {
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
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "NotShipped" {
                background #eeeeee
                color #666666
                border dashed
            }
        }
    }
}

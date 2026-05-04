workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines via Dashboard or KFP SDK"
        platformAdmin = person "Platform Admin" "Deploys and configures DSPA instances"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Kubeflow Pipelines v2 stacks on OpenShift AI" {
            controller = container "DSPAReconciler" "Reconciles DSPA CRs; deploys all DSP sub-components" "Go Operator (controller-runtime)"
            apiServer = container "ds-pipeline-api-server" "KFP v2 REST/gRPC API for pipeline CRUD, runs, artifacts" "Go Service (8888/8887)"
            kubeRBACProxy = container "kube-rbac-proxy" "Authenticates external requests via SubjectAccessReview" "Sidecar (8443)"
            persistenceAgent = container "ds-pipeline-persistenceagent" "Syncs Argo Workflow status back to KFP database" "Go Service"
            scheduledWorkflow = container "ds-pipeline-scheduledworkflow" "Creates Argo Workflows from ScheduledWorkflow CRs on cron" "Go Service"
            workflowController = container "ds-pipeline-workflow-controller" "Argo Workflow controller — orchestrates pipeline steps" "Go Service"
            mlmdGRPC = container "ds-pipeline-metadata-grpc" "ML Metadata gRPC — experiment/artifact/execution lineage" "gRPC Service (8080)"
            mlmdEnvoy = container "ds-pipeline-metadata-envoy" "Envoy proxy fronting MLMD gRPC with kube-rbac-proxy" "Envoy (9090/8443)"
            webhook = container "ds-pipelines-webhook" "Admission webhook for PipelineVersion validation" "Go Service (8443)"
        }

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys DSPO" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing pipelines and experiments" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare / Ray" "Distributed compute scheduling" "Internal RHOAI"

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow orchestration engine" "External"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "TLS certificate provisioning" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        mariaDB = softwareSystem "MariaDB" "Pipeline metadata and MLMD storage" "External"
        s3Store = softwareSystem "S3 Object Store" "Pipeline artifact storage" "External"
        ociRegistry = softwareSystem "OCI Registry" "Managed pipelines image source" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster resource management" "External"

        # Relationships
        dataScientist -> dspo "Creates pipelines and runs via REST/gRPC" "HTTPS/443"
        platformAdmin -> dspo "Creates DataSciencePipelinesApplication CRs" "kubectl"
        rhodsOperator -> dspo "Deploys operator via kustomize overlays" "Kustomize"
        dashboard -> dspo "Pipeline management UI" "HTTPS/443"

        dspo -> mariaDB "Stores pipeline metadata and lineage" "MySQL/3306 TLS"
        dspo -> s3Store "Stores/retrieves pipeline artifacts" "HTTPS/443"
        dspo -> ociRegistry "Fetches managed pipeline manifests" "HTTPS/443"
        dspo -> k8sAPI "CRUD on all managed Kubernetes resources" "HTTPS/443"
        dspo -> openshiftServiceCA "Requests TLS certificates for services" "Annotation-based"
        dspo -> prometheus "Exposes metrics via ServiceMonitor" "HTTP/8888"

        dspo -> kserve "Pipeline steps can deploy InferenceService CRs" "Kubernetes API"
        dspo -> codeflare "Pipeline steps can create AppWrapper/Ray CRs" "Kubernetes API"

        # Internal container relationships
        controller -> apiServer "Deploys and manages" "Manifestival templates"
        controller -> persistenceAgent "Deploys" "Manifestival"
        controller -> scheduledWorkflow "Deploys" "Manifestival"
        controller -> workflowController "Deploys" "Manifestival"
        controller -> mlmdGRPC "Deploys" "Manifestival"
        controller -> mlmdEnvoy "Deploys" "Manifestival"
        controller -> webhook "Deploys (conditional)" "Manifestival"
        kubeRBACProxy -> apiServer "Proxies authenticated requests" "HTTP/8888"
        persistenceAgent -> apiServer "Syncs workflow status" "HTTP/8888"
        mlmdEnvoy -> mlmdGRPC "Proxies gRPC" "gRPC/8080 mTLS"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout
        }

        container dspo "Containers" {
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
            element "Person" {
                shape person
                background #4a90e2
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
        }
    }
}

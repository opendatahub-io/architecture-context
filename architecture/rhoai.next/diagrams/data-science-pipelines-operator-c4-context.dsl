workspace {
    model {
        // People
        datascientist = person "Data Scientist" "Creates pipelines, submits runs, queries lineage"
        platformadmin = person "Platform Admin" "Creates DSPA CRs, manages pipeline infrastructure"

        // Primary system
        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages lifecycle of Kubeflow Pipelines v2 stacks on OpenShift AI" {
            controller = container "DSPO Controller" "Reconciles DSPA CRs; deploys all DSP sub-components per namespace" "Go Operator (controller-runtime)"
            apiserver = container "ds-pipeline-api-server" "KFP v2 REST/gRPC API — pipeline CRUD, run management, artifact access" "Go Service" {
                tags "DSP Component"
            }
            kubeRbacProxyApi = container "kube-rbac-proxy (API)" "Authenticates external requests via SubjectAccessReview" "Sidecar" {
                tags "Auth"
            }
            persistenceAgent = container "ds-pipeline-persistenceagent" "Syncs Argo Workflow status back to KFP database" "Go Service" {
                tags "DSP Component"
            }
            scheduledWorkflow = container "ds-pipeline-scheduledworkflow" "Creates Argo Workflows from ScheduledWorkflow CRs on cron triggers" "Go Service" {
                tags "DSP Component"
            }
            workflowController = container "ds-pipeline-workflow-controller" "Argo Workflow controller — orchestrates pipeline step execution" "Go Service" {
                tags "DSP Component"
            }
            mlmdGrpc = container "ds-pipeline-metadata-grpc" "ML Metadata gRPC server — experiment/artifact/execution lineage" "Go Service" {
                tags "DSP Component"
            }
            mlmdEnvoy = container "ds-pipeline-metadata-envoy" "Envoy proxy fronting MLMD gRPC with kube-rbac-proxy sidecar" "Envoy + Sidecar" {
                tags "DSP Component"
            }
            webhook = container "ds-pipelines-webhook" "Admission webhook for PipelineVersion validation" "Go Service" {
                tags "DSP Component"
            }
        }

        // Internal platform dependencies
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Deploys DSPO with image refs and config" {
            tags "Internal ODH"
        }
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing pipelines and viewing runs" {
            tags "Internal ODH"
        }
        prometheus = softwareSystem "Prometheus / Monitoring" "Scrapes operator and API server metrics" {
            tags "Internal ODH"
        }

        // External dependencies
        argoWorkflows = softwareSystem "Argo Workflows" "Workflow orchestration engine" {
            tags "External"
        }
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines v2" "Upstream pipeline framework" {
            tags "External"
        }
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "TLS certificate provisioning for pod-to-pod encryption" {
            tags "External"
        }
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" {
            tags "External"
        }

        // External services
        mariadb = softwareSystem "MariaDB" "Pipeline metadata and MLMD database storage" {
            tags "External Service"
        }
        s3Storage = softwareSystem "S3-Compatible Object Store" "Pipeline artifact storage (MinIO, AWS S3, etc.)" {
            tags "External Service"
        }
        ociRegistry = softwareSystem "OCI Registry" "Managed pipelines image distribution" {
            tags "External Service"
        }

        // Integration targets
        kserve = softwareSystem "KServe" "Model serving — pipeline steps can deploy InferenceServices" {
            tags "Internal ODH"
        }
        ray = softwareSystem "Ray" "Distributed compute — pipeline steps can create Ray clusters" {
            tags "Internal ODH"
        }
        codeflare = softwareSystem "CodeFlare" "Batch workload scheduling via AppWrapper CRs" {
            tags "Internal ODH"
        }

        // Relationships — People
        platformadmin -> dspo "Creates DSPA CRs via kubectl/Dashboard"
        datascientist -> dspo "Submits pipeline runs, queries artifacts" "REST/gRPC over HTTPS"

        // Relationships — Platform
        rhodsOperator -> dspo "Deploys operator via kustomize overlays"
        dashboard -> dspo "UI pipeline management" "HTTPS/443"
        prometheus -> dspo "Scrapes /metrics" "HTTP/8888"

        // Relationships — Internal containers
        kubeRbacProxyApi -> apiserver "Authenticated proxy" "HTTP/8888"
        controller -> apiserver "Deploys and manages"
        controller -> workflowController "Deploys and manages"
        controller -> persistenceAgent "Deploys and manages"
        controller -> scheduledWorkflow "Deploys and manages"
        controller -> mlmdGrpc "Deploys and manages"
        controller -> mlmdEnvoy "Deploys and manages"
        controller -> webhook "Deploys and manages"
        persistenceAgent -> apiserver "Updates run status" "HTTP/8888"
        scheduledWorkflow -> workflowController "Creates Workflows"
        mlmdEnvoy -> mlmdGrpc "Proxies gRPC" "gRPC/8080"

        // Relationships — External
        dspo -> k8sApi "CRUD on managed resources" "HTTPS/443"
        dspo -> mariadb "Pipeline metadata and lineage storage" "MySQL/3306 TLS"
        dspo -> s3Storage "Pipeline artifact storage" "HTTPS/443"
        dspo -> ociRegistry "Fetch managed pipelines manifest" "HTTPS/443"
        dspo -> openshiftServiceCA "TLS certificate provisioning"
        dspo -> argoWorkflows "Workflow orchestration engine"

        // Relationships — Integration
        dspo -> kserve "Pipeline steps create InferenceService CRs"
        dspo -> ray "Pipeline steps create Ray cluster CRs"
        dspo -> codeflare "Pipeline steps create AppWrapper CRs"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #d4a017
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Auth" {
                background #e8935a
                color #ffffff
            }
            element "DSP Component" {
                background #5ba0d0
                color #ffffff
            }
        }
    }
}

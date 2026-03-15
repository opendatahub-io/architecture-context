workspace {
    model {
        # People
        platformAdmin = person "Platform Admin" "OpenShift cluster administrator who installs and configures RHOAI"
        dataScientist = person "Data Scientist" "End user who creates and deploys ML models using RHOAI components"

        # Main system
        rhodsOperator = softwareSystem "RHODS Operator" "Orchestrates and manages the lifecycle of Red Hat OpenShift AI data science platform components" {
            dscController = container "DataScienceCluster Controller" "Manages lifecycle of data science components" "Go Reconciler" {
                tags "Controller"
            }
            dsciController = container "DSCInitialization Controller" "Initializes platform prerequisites: namespaces, service mesh, monitoring" "Go Reconciler" {
                tags "Controller"
            }
            secretGenController = container "SecretGenerator Controller" "Auto-generates OAuth client secrets and credentials" "Go Reconciler" {
                tags "Controller"
            }
            featureFramework = container "Feature Framework" "Declarative system for deploying cross-component features" "Go Library" {
                tags "Library"
            }
            webhookServer = container "Webhook Server" "Validation and defaulting webhooks for DSC and DSCI resources" "Go Admission Controller" {
                tags "Webhook"
            }
        }

        # Managed RHOAI Components
        dashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI platform management" {
            tags "Managed Component"
        }
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments for data science work" {
            tags "Managed Component"
        }
        pipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflow orchestration" {
            tags "Managed Component"
        }
        kserve = softwareSystem "KServe" "Single-model serving platform with autoscaling" {
            tags "Managed Component"
        }
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving for efficient resource usage" {
            tags "Managed Component"
        }
        codeflare = softwareSystem "CodeFlare" "Distributed workload orchestration (MCAD, InstaScale)" {
            tags "Managed Component"
        }
        ray = softwareSystem "Ray" "Distributed compute framework for ML workloads" {
            tags "Managed Component"
        }
        trustyai = softwareSystem "TrustyAI" "Model monitoring and explainability service" {
            tags "Managed Component"
        }

        # External Platform Dependencies
        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration platform (1.25+)" {
            tags "External Platform"
        }
        openshift = softwareSystem "OpenShift Platform" "Extended Kubernetes with Routes, OAuth, Console (4.11+)" {
            tags "External Platform"
        }
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Istio-based networking for mTLS and traffic management (Optional)" {
            tags "External Optional"
        }
        prometheusOperator = softwareSystem "Prometheus Operator" "Provides monitoring CRDs (ServiceMonitor, PodMonitor)" {
            tags "External Optional"
        }
        certManager = softwareSystem "cert-manager" "Certificate provisioning and management" {
            tags "External Optional"
        }

        # Monitoring Stack
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting for RHOAI components" {
            tags "Monitoring"
        }
        alertmanager = softwareSystem "Alertmanager" "Alert routing and notification management" {
            tags "Monitoring"
        }

        # External Services
        imageRegistry = softwareSystem "Image Registries" "Container image storage (quay.io, registry.redhat.io)" {
            tags "External Service"
        }

        # Relationships - Users
        platformAdmin -> rhodsOperator "Creates DataScienceCluster and DSCInitialization CRs via kubectl"
        dataScientist -> dashboard "Accesses web UI to manage workbenches and models"
        dataScientist -> workbenches "Creates and runs Jupyter notebooks"
        dataScientist -> pipelines "Builds and runs ML pipelines"
        dataScientist -> kserve "Deploys inference services"

        # Relationships - Operator to Platform
        rhodsOperator -> kubernetes "Creates/updates cluster resources" "HTTPS/6443 TLS1.2+ (Service Account Token)"
        rhodsOperator -> openshift "Registers OAuth clients, creates Routes" "HTTPS/443 TLS1.2+"
        rhodsOperator -> serviceMesh "Configures service mesh membership and policies" "Kubernetes API (ServiceMeshMember CRs)"
        rhodsOperator -> prometheusOperator "Deploys ServiceMonitor and PodMonitor CRs" "Kubernetes API"
        rhodsOperator -> imageRegistry "Pulls container images for component deployments" "HTTPS/443 TLS1.2+"

        # Relationships - Operator to Managed Components
        dscController -> dashboard "Deploys and manages" "Kubernetes API (manifests from /opt/manifests)"
        dscController -> workbenches "Deploys and manages" "Kubernetes API"
        dscController -> pipelines "Deploys and manages" "Kubernetes API"
        dscController -> kserve "Deploys and manages" "Kubernetes API"
        dscController -> modelmesh "Deploys and manages" "Kubernetes API"
        dscController -> codeflare "Deploys and manages" "Kubernetes API"
        dscController -> ray "Deploys and manages" "Kubernetes API"
        dscController -> trustyai "Deploys and manages" "Kubernetes API"

        # Relationships - Initialization
        dsciController -> prometheus "Deploys monitoring stack to redhat-ods-monitoring namespace" "Kubernetes API"
        dsciController -> alertmanager "Deploys monitoring stack to redhat-ods-monitoring namespace" "Kubernetes API"

        # Relationships - Secret Generation
        secretGenController -> openshift "Creates OAuth clients with generated secrets" "OAuth API"

        # Relationships - Monitoring
        prometheus -> rhodsOperator "Scrapes /metrics endpoint" "HTTP/8080"
        prometheus -> dashboard "Scrapes component metrics" "HTTP (ServiceMonitor)"
        prometheus -> kserve "Scrapes component metrics" "HTTP (ServiceMonitor)"
        prometheus -> pipelines "Scrapes component metrics" "HTTP (ServiceMonitor)"

        # Relationships - Webhooks
        kubernetes -> webhookServer "Validates DataScienceCluster and DSCInitialization CRs" "HTTPS/9443 mTLS"

        # Relationships - Component Integration
        kserve -> serviceMesh "Uses for traffic routing and mTLS" "Istio APIs"
        modelmesh -> serviceMesh "Uses for traffic routing and mTLS" "Istio APIs"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram for RHODS Operator showing external dependencies and managed components"
        }

        container rhodsOperator "Containers" {
            include *
            autoLayout lr
            description "Container diagram showing internal components of RHODS Operator"
        }

        systemContext rhodsOperator "DeploymentView" {
            include platformAdmin
            include dataScientist
            include rhodsOperator
            include dashboard
            include workbenches
            include pipelines
            include kserve
            include modelmesh
            include codeflare
            include ray
            include trustyai
            include kubernetes
            include openshift
            autoLayout lr
            description "Simplified view showing managed RHOAI components and platform dependencies"
        }

        systemContext rhodsOperator "MonitoringView" {
            include rhodsOperator
            include prometheus
            include alertmanager
            include dashboard
            include kserve
            include pipelines
            include platformAdmin
            autoLayout lr
            description "Monitoring architecture showing metrics collection flows"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
            }
            element "Webhook" {
                background #f5a623
            }
            element "Library" {
                background #7ed321
            }
            element "Managed Component" {
                background #7ed321
            }
            element "External Platform" {
                background #999999
            }
            element "External Optional" {
                background #cccccc
            }
            element "External Service" {
                background #e8e8e8
            }
            element "Monitoring" {
                background #e6522c
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

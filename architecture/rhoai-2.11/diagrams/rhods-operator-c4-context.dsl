workspace {
    model {
        admin = person "Platform Administrator" "Manages RHOAI platform deployment and configuration"
        datascientist = person "Data Scientist" "Uses RHOAI components for ML workflows"

        rhodsOperator = softwareSystem "RHODS Operator" "Primary operator for Red Hat OpenShift AI that manages data science platform components" {
            dscController = container "DataScienceCluster Controller" "Manages component deployments and lifecycle" "Go Operator"
            dsciController = container "DSCInitialization Controller" "Initializes platform infrastructure" "Go Operator"
            secretGenerator = container "SecretGenerator Controller" "Generates secrets for components" "Go Operator"
            certGenerator = container "CertConfigmapGenerator Controller" "Generates certificate ConfigMaps" "Go Operator"
            manifestManager = container "Manifest Manager" "Fetches and applies component manifests" "Kustomize"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics" "HTTP Service"
        }

        k8s = softwareSystem "Kubernetes API Server" "Orchestration platform API" "External"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Service mesh for traffic management and mTLS" "External Platform"
        knative = softwareSystem "Knative Serving" "Serverless platform for autoscaling" "External Platform"
        authorino = softwareSystem "Authorino" "API authorization service" "External Platform"
        certManager = softwareSystem "cert-manager" "Certificate management" "External Platform"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring infrastructure operator" "External Platform"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for data science platform" "Internal ODH"
        kserve = softwareSystem "KServe" "Single model serving runtime" "Internal ODH"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving runtime" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal ODH"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments" "Internal ODH"
        codeflare = softwareSystem "CodeFlare" "Distributed compute orchestration" "Internal ODH"
        ray = softwareSystem "Ray" "Distributed Python runtime" "Internal ODH"
        kueue = softwareSystem "Kueue" "Job queueing for batch workloads" "Internal ODH"
        training = softwareSystem "Training Operator" "Distributed ML training" "Internal ODH"
        trustyai = softwareSystem "TrustyAI" "Model monitoring and explainability" "Internal ODH"

        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Monitoring"
        alertmanager = softwareSystem "Alertmanager" "Alert routing and management" "Monitoring"

        github = softwareSystem "GitHub Component Repos" "Source repositories for component manifests" "External"

        # Relationships - Admin
        admin -> rhodsOperator "Creates DSCInitialization and DataScienceCluster CRs via kubectl"
        admin -> prometheus "Views metrics and alerts via OpenShift Route" "HTTPS/443 OAuth"
        admin -> alertmanager "Manages alerts via OpenShift Route" "HTTPS/443 OAuth"

        # Relationships - Data Scientist
        datascientist -> dashboard "Accesses platform via web UI"
        datascientist -> workbenches "Creates and uses Jupyter notebooks"
        datascientist -> kserve "Deploys inference services"

        # Relationships - Operator to K8s
        rhodsOperator -> k8s "Reconciles all cluster resources" "HTTPS/6443"
        dscController -> k8s "Creates and updates component deployments" "HTTPS/6443"
        dsciController -> k8s "Initializes namespaces and RBAC" "HTTPS/6443"
        secretGenerator -> k8s "Generates secrets" "HTTPS/6443"
        certGenerator -> k8s "Creates certificate ConfigMaps" "HTTPS/6443"

        # Relationships - Operator to Platform Dependencies
        rhodsOperator -> serviceMesh "Configures Istio for KServe" "ServiceMeshControlPlane CRs"
        rhodsOperator -> prometheusOp "Configures monitoring" "ServiceMonitor/PrometheusRule CRs"
        rhodsOperator -> certManager "Requests TLS certificates" "Certificate CRs"
        rhodsOperator -> github "Fetches component manifests at build time" "HTTPS/443"

        # Relationships - Operator deploys components
        rhodsOperator -> dashboard "Deploys and manages"
        rhodsOperator -> kserve "Deploys and manages"
        rhodsOperator -> modelmesh "Deploys and manages"
        rhodsOperator -> pipelines "Deploys and manages"
        rhodsOperator -> workbenches "Deploys and manages"
        rhodsOperator -> codeflare "Deploys and manages"
        rhodsOperator -> ray "Deploys and manages"
        rhodsOperator -> kueue "Deploys and manages"
        rhodsOperator -> training "Deploys and manages"
        rhodsOperator -> trustyai "Deploys and manages"

        # Relationships - Operator to Monitoring
        rhodsOperator -> prometheus "Deploys and configures"
        rhodsOperator -> alertmanager "Deploys and configures"
        prometheus -> metricsEndpoint "Scrapes operator metrics" "HTTP/8080"
        prometheus -> dashboard "Scrapes component metrics"
        prometheus -> kserve "Scrapes component metrics"
        prometheus -> modelmesh "Scrapes component metrics"

        # Relationships - Component dependencies
        kserve -> serviceMesh "Uses for traffic routing and mTLS"
        kserve -> knative "Uses for autoscaling"
        kserve -> authorino "Uses for API authorization"

        # Deployment nodes
        deploymentEnvironment "Red Hat OpenShift AI" {
            deploymentNode "OpenShift Cluster" {
                deploymentNode "redhat-ods-operator namespace" {
                    containerInstance dscController
                    containerInstance dsciController
                    containerInstance secretGenerator
                    containerInstance certGenerator
                }

                deploymentNode "redhat-ods-monitoring namespace" {
                    softwareSystemInstance prometheus
                    softwareSystemInstance alertmanager
                }

                deploymentNode "redhat-ods-applications namespace" {
                    softwareSystemInstance dashboard
                    softwareSystemInstance kserve
                    softwareSystemInstance modelmesh
                    softwareSystemInstance workbenches
                }
            }
        }
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout lr
        }

        container rhodsOperator "Containers" {
            include *
            autoLayout lr
        }

        deployment rhodsOperator "Deployment" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Platform" {
                background #cccccc
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Monitoring" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

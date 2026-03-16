workspace {
    model {
        admin = person "Platform Administrator" "Manages RHOAI/ODH platform installation and configuration"
        developer = person "Data Scientist" "Uses deployed data science components"

        rhodsOperator = softwareSystem "rhods-operator" "Primary orchestration operator for RHOAI/ODH platform - deploys and manages all data science components" {
            operatorManager = container "Operator Manager" "Reconciles CRs and manages component lifecycle" "Go Operator" {
                dscController = component "DataScienceCluster Controller" "Deploys data science components" "Controller"
                dsciController = component "DSCInitialization Controller" "Initializes platform infrastructure" "Controller"
                secretGen = component "SecretGenerator Controller" "Generates dynamic secrets" "Controller"
                certGen = component "CertConfigmapGenerator Controller" "Generates certificate ConfigMaps" "Controller"
            }
            webhookServer = container "Webhook Server" "Validates and mutates DataScienceCluster CRs" "Go Service"
            authProxy = container "Auth Proxy" "Authenticates metrics requests" "kube-rbac-proxy"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API" "Infrastructure"
        github = softwareSystem "GitHub" "Component manifest repository (github.com)" "External"
        quayIO = softwareSystem "Quay.io" "Container image registry" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Monitoring"

        serviceMesh = softwareSystem "Service Mesh Operator" "Istio-based service mesh for model serving" "External Operator"
        serverless = softwareSystem "Serverless Operator" "Knative Serving for autoscaling" "External Operator"
        authorino = softwareSystem "Authorino Operator" "Authentication/authorization for model serving" "External Operator"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for data science platform" "ODH Component"
        kserve = softwareSystem "KServe" "Model serving infrastructure" "ODH Component"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving" "ODH Component"
        dsp = softwareSystem "Data Science Pipelines" "ML workflow orchestration" "ODH Component"
        codeflare = softwareSystem "CodeFlare Operator" "Distributed ML workloads" "ODH Component"
        kuberay = softwareSystem "KubeRay Operator" "Ray cluster management" "ODH Component"
        training = softwareSystem "Training Operator" "Distributed training jobs" "ODH Component"
        kueue = softwareSystem "Kueue" "Job queueing system" "ODH Component"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage" "ODH Component"
        trustyai = softwareSystem "TrustyAI Service" "Model monitoring and explainability" "ODH Component"

        # Relationships
        admin -> rhodsOperator "Creates DataScienceCluster and DSCInitialization CRs via kubectl"
        developer -> dashboard "Uses data science tools"
        developer -> kserve "Deploys models"
        developer -> dsp "Runs ML pipelines"

        rhodsOperator -> k8sAPI "Manages cluster resources via REST API" "HTTPS/6443, TLS 1.3, ServiceAccount Token"
        k8sAPI -> webhookServer "Validates/mutates CRs" "HTTPS/9443, mTLS"
        rhodsOperator -> github "Downloads component manifests" "HTTPS/443, TLS 1.2+"
        rhodsOperator -> quayIO "Pulls container images" "HTTPS/443, TLS 1.2+"
        prometheus -> authProxy "Scrapes operator metrics" "HTTPS/8443, Bearer Token"

        rhodsOperator -> serviceMesh "Depends on (for KServe)"
        rhodsOperator -> serverless "Depends on (for KServe)"
        rhodsOperator -> authorino "Depends on (for auth)"

        rhodsOperator -> dashboard "Deploys and manages"
        rhodsOperator -> kserve "Deploys and manages"
        rhodsOperator -> modelmesh "Deploys and manages"
        rhodsOperator -> dsp "Deploys and manages"
        rhodsOperator -> codeflare "Deploys and manages"
        rhodsOperator -> kuberay "Deploys and manages"
        rhodsOperator -> training "Deploys and manages"
        rhodsOperator -> kueue "Deploys and manages"
        rhodsOperator -> modelRegistry "Deploys and manages"
        rhodsOperator -> trustyai "Deploys and manages"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout
        }

        container rhodsOperator "Containers" {
            include *
            autoLayout
        }

        component operatorManager "Components" {
            include *
            autoLayout
        }

        styles {
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #cccccc
                color #000000
            }
            element "External Operator" {
                background #ffcc99
                color #000000
            }
            element "Monitoring" {
                background #6c8ebf
                color #ffffff
            }
            element "ODH Component" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
            element "Component" {
                shape Component
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}

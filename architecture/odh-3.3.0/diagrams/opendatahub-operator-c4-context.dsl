workspace {
    model {
        user = person "Data Scientist / Platform Admin" "Manages data science platform components and configurations"

        odh = softwareSystem "Open Data Hub Operator" "Central operator managing lifecycle of 20+ data science components including model serving, pipelines, workbenches, and MLOps tooling" {
            controllerManager = container "Controller Manager" "Reconciles DataScienceCluster and DSCInitialization resources" "Go Operator" {
                componentControllers = component "Component Controllers" "Individual reconcilers for Dashboard, KServe, Ray, Pipelines, etc." "Go"
                serviceControllers = component "Service Controllers" "Platform services: Auth, Gateway, Monitoring" "Go"
                manifestEngine = component "Manifest Engine" "Renders Kustomize and Helm templates" "Go"
            }
            webhookServer = container "Webhook Server" "Validates and mutates DSC/DSCI resources" "Go Admission Webhook"
            cloudManager = container "Cloud Manager" "Manages cloud-specific infrastructure (Azure, CoreWeave)" "Go Binary"
        }

        k8s = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External"
        olm = softwareSystem "Operator Lifecycle Manager (OLM)" "Manages operator installation and upgrades" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        serviceMesh = softwareSystem "Service Mesh (Istio/Sail)" "Service mesh for networking and security" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring and alerting platform" "External"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for platform management" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving platform" "Internal ODH"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (Kubeflow Pipelines)" "Internal ODH"
        ray = softwareSystem "Ray (Kuberay)" "Distributed computing framework" "Internal ODH"
        trainingOp = softwareSystem "Training Operator" "Distributed training jobs (TensorFlow, PyTorch)" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model versioning and metadata" "Internal ODH"
        trustyai = softwareSystem "TrustyAI" "AI explainability and governance" "Internal ODH"
        notebooks = softwareSystem "Notebook Controller" "Jupyter workbench management" "Internal ODH"
        modelController = softwareSystem "Model Controller" "Model deployment orchestration" "Internal ODH"

        registry = softwareSystem "Container Registry (Quay.io)" "Container image storage" "External"

        # User interactions
        user -> odh "Creates/updates DataScienceCluster and DSCInitialization via kubectl/OpenShift Console"

        # ODH Operator interactions
        odh -> k8s "Manages cluster resources via Kubernetes API" "HTTPS/443, mTLS"
        odh -> olm "Creates Subscription CRDs to install component operators" "In-cluster CRD"
        odh -> certManager "Configures Certificate and Issuer resources" "In-cluster CRD"
        odh -> serviceMesh "Configures Gateway and VirtualService for ingress" "In-cluster CRD"
        odh -> prometheusOp "Creates ServiceMonitor and PrometheusRule for monitoring" "In-cluster CRD"

        # Component deployment
        odh -> dashboard "Deploys manifests and configures web UI"
        odh -> kserve "Deploys KServe operator and configures model serving"
        odh -> dsp "Deploys Data Science Pipelines operator"
        odh -> ray "Deploys Kuberay operator for distributed compute"
        odh -> trainingOp "Deploys Training Operator for ML training"
        odh -> modelRegistry "Deploys Model Registry operator"
        odh -> trustyai "Deploys TrustyAI operator for explainability"
        odh -> notebooks "Deploys Notebook Controller for Jupyter workbenches"
        odh -> modelController "Deploys Model Controller for model orchestration"

        # External dependencies
        olm -> registry "Pulls operator images" "HTTPS/443"
        odh -> registry "Pulls component images" "HTTPS/443 (via pull secrets)"

        # Webhooks
        k8s -> webhookServer "Validates/mutates DSC and DSCI resources" "HTTPS/9443, TLS"
    }

    views {
        systemContext odh "ODHOperatorSystemContext" {
            include *
            autoLayout lr
        }

        container odh "ODHOperatorContainers" {
            include *
            autoLayout lr
        }

        component controllerManager "ControllerManagerComponents" {
            include *
            autoLayout tb
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

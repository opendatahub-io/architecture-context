workspace {
    model {
        admin = person "Platform Admin" "Configures and manages RHOAI/ODH platform"
        datascientist = person "Data Scientist" "Uses deployed data science components"

        rhodsOperator = softwareSystem "RHODS Operator" "Platform operator managing lifecycle of data science and AI/ML components" {
            operatorManager = container "Operator Manager" "Reconciles DataScienceCluster and component CRDs" "Go Controller Runtime" {
                dscController = component "DSC Controller" "Manages component lifecycle based on DSC configuration"
                dsciController = component "DSCI Controller" "Initializes platform-level configuration"
                dashboardController = component "Dashboard Controller" "Deploys ODH/RHOAI dashboard"
                kserveController = component "KServe Controller" "Deploys KServe operator"
                rayController = component "Ray Controller" "Deploys Ray operator"
                pipelinesController = component "Pipelines Controller" "Deploys Data Science Pipelines"
                trainingController = component "Training Controller" "Deploys Training Operator"
            }

            webhookServer = container "Webhook Server" "Validates and mutates platform CRs" "Go HTTPS Service"
            metricsServer = container "Metrics Server" "Exposes operator metrics" "HTTP Service"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Container orchestration control plane" "External"
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Service mesh for KServe and gateway" "External - Conditional"
        serverless = softwareSystem "OpenShift Serverless" "Serverless runtime for KServe" "External - Conditional"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring infrastructure" "External - Conditional"

        dashboard = softwareSystem "ODH Dashboard" "User interface for platform management" "Internal ODH"
        kserve = softwareSystem "KServe Operator" "Model serving infrastructure" "Internal ODH"
        pipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration" "Internal ODH"
        ray = softwareSystem "Ray Operator" "Distributed compute framework" "Internal ODH"
        training = softwareSystem "Kubeflow Training Operator" "Distributed training jobs" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "ML model versioning and registry" "Internal ODH"
        trustyai = softwareSystem "TrustyAI Service" "Model explainability and bias detection" "Internal ODH"

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "RHODS Monitoring"
        alertManager = softwareSystem "AlertManager" "Alert management and notification" "RHODS Monitoring"

        imageRegistry = softwareSystem "Image Registries" "Container image storage (quay.io, registry.redhat.io)" "External"

        # Relationships
        admin -> rhodsOperator "Creates DataScienceCluster and DSCInitialization CRs via kubectl/GitOps"
        datascientist -> dashboard "Uses UI to manage workbenches and models"

        rhodsOperator -> k8sAPI "Manages CRDs and Kubernetes resources" "HTTPS/6443"
        k8sAPI -> webhookServer "Validates/mutates CRs via admission webhooks" "HTTPS/9443"

        operatorManager -> k8sAPI "Reconciles resources" "HTTPS/6443"
        dscController -> dashboardController "Triggers component deployment"
        dscController -> kserveController "Triggers component deployment"
        dscController -> rayController "Triggers component deployment"
        dscController -> pipelinesController "Triggers component deployment"
        dscController -> trainingController "Triggers component deployment"

        rhodsOperator -> serviceMesh "Configures service mesh for KServe" "CRD API"
        rhodsOperator -> serverless "Configures Knative Serving for KServe" "CRD API"
        rhodsOperator -> prometheusOperator "Deploys ServiceMonitors and PrometheusRules" "CRD API"

        dashboardController -> dashboard "Deploys and manages"
        kserveController -> kserve "Deploys and manages"
        pipelinesController -> pipelines "Deploys and manages"
        rayController -> ray "Deploys and manages"
        trainingController -> training "Deploys and manages"

        rhodsOperator -> modelRegistry "Deploys and manages"
        rhodsOperator -> trustyai "Deploys and manages"

        prometheus -> metricsServer "Scrapes operator metrics" "HTTPS/8443"
        prometheus -> alertManager "Sends alerts"

        operatorManager -> imageRegistry "Pulls component images" "HTTPS/443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External - Conditional" {
                background #cccccc
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "RHODS Monitoring" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}

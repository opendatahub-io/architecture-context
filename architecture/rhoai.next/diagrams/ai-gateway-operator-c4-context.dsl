workspace {
    model {
        admin = person "Platform Admin" "Manages RHOAI platform components and configures AI Gateway"
        dataScientist = person "Data Scientist" "Submits batch inference jobs via LLMBatchGateway CRs"

        aiGatewayOperator = softwareSystem "AI Gateway Operator" "Module operator managing AI gateway sub-components for the ODH/RHOAI platform" {
            initContainer = container "Init Container (copy-manifests)" "Copies vendored kustomize manifests from image to emptyDir volume" "Container"
            manager = container "ai-gateway-operator Manager" "Reconciles AIGateway CRs, renders kustomize manifests, deploys sub-components" "Go (controller-runtime)"
            configVolume = container "ConfigMap Volume" "Platform configuration: platform-type, platform-version" "Kubernetes ConfigMap" "config"
            manifestsVolume = container "Manifests Volume" "Vendored kustomize manifests for sub-components" "EmptyDir" "storage"
        }

        batchGatewayOperator = softwareSystem "Batch Gateway Operator" "Sub-component that manages LLMBatchGateway CRs and deploys batch inference operands" {
            batchController = container "batch-gateway-operator Controller" "Reconciles LLMBatchGateway CRs" "Go Operator"
            apiServer = container "Batch Gateway API Server" "HTTP API for batch inference job submission" "Go Service"
            processor = container "Batch Gateway Processor" "Processes batch inference jobs against inference gateways" "Go Worker"
            gc = container "Batch Gateway GC" "Garbage collector for expired jobs and files" "Go Worker"
        }

        openDataHubOperator = softwareSystem "opendatahub-operator" "Platform operator that deploys and manages module operators" "Internal ODH"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, RBAC, leader election" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate lifecycle management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTP routing" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships
        admin -> openDataHubOperator "Configures platform components"
        openDataHubOperator -> aiGatewayOperator "Deploys via module handler and creates AIGateway CR"

        admin -> aiGatewayOperator "Sets batchGateway.managementState via AIGateway CR"
        dataScientist -> batchGatewayOperator "Creates LLMBatchGateway CRs via kubectl"

        manager -> kubernetesAPI "Watch CRs, CRUD resources" "HTTPS/443, TLS 1.2+, SA Token"
        manager -> configVolume "Reads platform config" "/etc/controller/config"
        initContainer -> manifestsVolume "Copies manifests" "/opt/manifests"
        manager -> manifestsVolume "Reads vendored manifests" "/opt/manifests"

        aiGatewayOperator -> batchGatewayOperator "Deploys when batchGateway=Managed" "Kustomize manifests"
        batchGatewayOperator -> kubernetesAPI "Watch CRs, CRUD resources" "HTTPS/443, TLS 1.2+, SA Token"
        batchGatewayOperator -> certManager "Creates Certificate CRs" "Kubernetes API"
        batchGatewayOperator -> gatewayAPI "Creates HTTPRoute CRs" "Kubernetes API"

        prometheus -> aiGatewayOperator "Scrapes metrics" "HTTPS/8443, Bearer Token"
        batchGatewayOperator -> prometheus "Creates ServiceMonitor/PodMonitor/PrometheusRule" "Kubernetes API"
    }

    views {
        systemContext aiGatewayOperator "SystemContext" {
            include *
            autoLayout
        }

        container aiGatewayOperator "AIGatewayContainers" {
            include *
            autoLayout
        }

        container batchGatewayOperator "BatchGatewayContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
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
            element "config" {
                shape cylinder
                background #fff2cc
                color #333333
            }
            element "storage" {
                shape cylinder
                background #fff2cc
                color #333333
            }
        }
    }
}

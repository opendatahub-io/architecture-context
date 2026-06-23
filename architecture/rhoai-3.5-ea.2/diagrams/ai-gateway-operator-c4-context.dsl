workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components via rhods-operator"
        dataScientist = person "Data Scientist" "Creates LLMBatchGateway resources for batch inference workloads"

        aiGatewayOperator = softwareSystem "AI Gateway Operator" "Module operator that manages AI gateway sub-components (batch-gateway) for RHOAI" {
            controller = container "ai-gateway-operator Controller" "Reconciles AIGateway CR, renders kustomize manifests, deploys sub-components" "Go (controller-runtime)"
            initContainer = container "copy-manifests Init Container" "Copies embedded manifests from image to /opt/manifests emptyDir volume" "Go"
            kustomizeEngine = container "Kustomize Rendering Engine" "Renders sub-component manifests with platform-specific overlays (ODH/RHOAI)" "opendatahub-operator framework"
        }

        batchGatewayOperator = softwareSystem "Batch Gateway Operator" "Manages LLMBatchGateway CRs for batch inference workloads (API server, processor, GC)" "Sub-component" {
            batchController = container "batch-gateway-operator Controller" "Reconciles LLMBatchGateway CRs, deploys batch workload components" "Go"
            apiServer = container "Batch API Server" "Handles batch inference API requests" "Go"
            processor = container "Batch Processor" "Processes batch inference requests" "Go"
            gc = container "Garbage Collector" "Cleans up completed batch jobs and resources" "Go"
        }

        rhodsOperator = softwareSystem "rhods-operator (opendatahub-operator)" "Platform operator that manages RHOAI module operators and creates AIGateway CR" "Internal RHOAI"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "Infrastructure"
        certManager = softwareSystem "cert-manager" "X.509 certificate management for Kubernetes" "External"
        gatewayApi = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTP routing (HTTPRoute, ReferenceGrant)" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages Prometheus monitoring resources (ServiceMonitor, PodMonitor, PrometheusRule)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships
        platformAdmin -> rhodsOperator "Configures RHOAI platform"
        rhodsOperator -> aiGatewayOperator "Creates AIGateway CR to trigger module deployment" "Kubernetes API / HTTPS 443"
        rhodsOperator -> k8sApi "Deploys ai-gateway-operator via module handler" "HTTPS/443, SA Token"

        aiGatewayOperator -> k8sApi "Watches AIGateway CRs, deploys sub-component resources" "HTTPS/443, TLS 1.2+, SA Token"
        aiGatewayOperator -> batchGatewayOperator "Deploys via kustomize manifests when managementState=Managed"

        dataScientist -> batchGatewayOperator "Creates LLMBatchGateway CRs via kubectl" "Kubernetes API"
        batchGatewayOperator -> k8sApi "Manages batch workload Deployments, Services, RBAC" "HTTPS/443, TLS 1.2+, SA Token"
        batchGatewayOperator -> certManager "Creates Certificate resources for TLS" "Kubernetes API"
        batchGatewayOperator -> gatewayApi "Creates HTTPRoute resources for ingress" "Kubernetes API"
        batchGatewayOperator -> prometheusOperator "Creates monitoring resources" "Kubernetes API"

        prometheus -> aiGatewayOperator "Scrapes /metrics endpoint" "HTTPS/8443, Bearer Token"
        prometheus -> batchGatewayOperator "Scrapes /metrics endpoint" "HTTPS/8443, Bearer Token"

        controller -> initContainer "Reads manifests from emptyDir volume"
        controller -> kustomizeEngine "Renders manifests with platform overlays"
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
            element "Internal RHOAI" {
                background #9b59b6
                color #ffffff
            }
            element "Infrastructure" {
                background #e8e8e8
                color #333333
            }
            element "Sub-component" {
                background #7ed321
                color #333333
            }
            element "Person" {
                shape Person
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

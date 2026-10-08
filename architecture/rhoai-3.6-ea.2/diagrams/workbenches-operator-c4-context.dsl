workspace {
    model {
        scientist = person "Data Scientist" "Creates and manages Notebook workbenches"

        workbenchesOperator = softwareSystem "Workbenches Operator" "Kubernetes operator that reconciles Workbenches CR and deploys notebook controller stack on OpenShift" {
            controller = container "WorkbenchesReconciler" "Reconciles Workbenches CR, renders kustomize manifests, applies operand resources via SSA" "Go Operator (controller-runtime)"
            connectionWebhook = container "Connection Webhook" "Injects connection secrets from annotation into Notebook pods as envFrom" "Mutating Admission Webhook"
            hardwareProfileWebhook = container "Hardware Profile Webhook" "Applies HardwareProfile resource limits, nodeSelector, tolerations, Kueue label to Notebook pods" "Mutating Admission Webhook"
            conversionWebhook = container "CRD Conversion Webhook" "Handles CRD version conversion for Notebook and Workspace resources" "Conversion Webhook"
            tlsAutoDetect = container "TLS Provider Auto-Detection" "Probes cluster APIs to detect and configure webhook TLS provider" "Runtime Subsystem"
            manifestRenderer = container "Manifest Renderer" "Reads committed kustomize manifests, overlays RELATED_IMAGE_* and CR params" "Kustomize/SSA"
        }

        platformOrchestrator = softwareSystem "Platform Orchestrator" "Creates Workbenches CR and projects platform state" "Internal RHOAI"
        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management and admission" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbench CRD and controller" "Internal RHOAI"
        hardwareProfile = softwareSystem "HardwareProfile" "Infrastructure resource profiles for workloads" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Certificate management for Kubernetes" "External"
        serviceCA = softwareSystem "OpenShift service-CA" "OpenShift certificate authority for service serving certs" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring and metrics collection" "External"
        imageStreams = softwareSystem "OpenShift Image Streams" "Container image management on OpenShift" "External"
        tlsSecurityProfile = softwareSystem "OpenShift TLS Security Profile" "Cluster-wide TLS cipher and version policy" "External"

        scientist -> workbenchesOperator "Creates Notebook CRs (intercepted by webhooks)" "kubectl / Dashboard"
        platformOrchestrator -> workbenchesOperator "Creates/updates Workbenches CR with platform state" "Kubernetes API"
        workbenchesOperator -> kubeAPI "CRUD operations, SSA, watches" "HTTPS/6443"
        workbenchesOperator -> kubeflowNotebooks "Creates/manages Notebook CRs; webhooks intercept mutations" "Kubernetes API"
        workbenchesOperator -> hardwareProfile "Reads HardwareProfile CRs for resource config" "Kubernetes API"
        workbenchesOperator -> certManager "Creates ClusterIssuer + Certificate (fallback TLS)" "Kubernetes API"
        workbenchesOperator -> serviceCA "Uses for webhook TLS cert provisioning (preferred)" "Annotation-based"
        workbenchesOperator -> prometheusOperator "Creates ServiceMonitor for metrics" "Kubernetes API"
        workbenchesOperator -> imageStreams "Manages ImageStream resources for notebook images" "Kubernetes API"
        workbenchesOperator -> tlsSecurityProfile "Reads cluster TLS profile for cipher config" "Kubernetes API"
    }

    views {
        systemContext workbenchesOperator "SystemContext" {
            include *
            autoLayout
        }

        container workbenchesOperator "Containers" {
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

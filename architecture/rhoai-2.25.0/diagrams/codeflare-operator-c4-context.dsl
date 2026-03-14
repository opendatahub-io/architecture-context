workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed ML workloads using Ray clusters"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages RayCluster and AppWrapper resources for distributed AI/ML workloads" {
            manager = container "Manager Pod" "Operator controller running reconciliation loops" "Go Operator" {
                rayController = component "RayCluster Controller" "Manages RayCluster lifecycle with OAuth, mTLS, networking" "Go Controller"
                appController = component "AppWrapper Controller" "Manages AppWrapper resources for batch scheduling" "Go Controller"
                mutatingWebhook = component "Mutating Webhook" "Modifies RayCluster and AppWrapper on CREATE/UPDATE" "Go Webhook"
                validatingWebhook = component "Validating Webhook" "Validates RayCluster and AppWrapper on CREATE/UPDATE" "Go Webhook"
                certController = component "Cert Controller" "Manages webhook TLS certificate rotation" "Go Component"
            }
            metricsService = container "Metrics Service" "Exposes Prometheus metrics" "ClusterIP Service :8080"
            webhookService = container "Webhook Service" "Serves admission webhook requests" "ClusterIP Service :443 TLS"
        }

        kuberay = softwareSystem "KubeRay Operator" "Provides RayCluster CRD and base Ray cluster management" "External Required"
        kueue = softwareSystem "Kueue" "Workload queueing and batch scheduling" "External Optional"
        certController = softwareSystem "cert-controller" "TLS certificate management and rotation" "External Required"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External Required"
        openshift = softwareSystem "OpenShift" "OAuth proxy integration and Route resources" "External Optional"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for creating and managing data science resources" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Reads DSCInitialization for configuration" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"

        # User interactions
        user -> codeflareOperator "Creates RayCluster and AppWrapper via kubectl/UI"
        user -> odhDashboard "Manages Ray clusters via web UI"
        odhDashboard -> codeflareOperator "Triggers RayCluster creation"

        # External dependencies
        codeflareOperator -> kuberay "Depends on RayCluster CRD and base cluster lifecycle"
        codeflareOperator -> kueue "Integrates for AppWrapper batch scheduling" "HTTPS/6443 TLS1.3"
        codeflareOperator -> certController "Uses for webhook TLS certificate rotation"
        codeflareOperator -> kubernetes "Manages resources via API" "HTTPS/6443 TLS1.3"
        codeflareOperator -> openshift "Creates Routes and OAuth proxies" "HTTPS/6443 TLS1.3"

        # Internal ODH dependencies
        codeflareOperator -> odhOperator "Reads DSCInitialization configuration" "HTTPS/6443 TLS1.3"
        prometheus -> codeflareOperator "Scrapes metrics" "HTTP/8080"

        # Internal component relationships
        rayController -> kubernetes "Creates Services, Routes, NetworkPolicies, Secrets"
        appController -> kubernetes "Creates wrapped resources"
        mutatingWebhook -> kubernetes "Mutates admission requests"
        validatingWebhook -> kubernetes "Validates admission requests"
        kubernetes -> webhookService "Sends admission requests" "HTTPS/9443 TLS1.2+ mTLS"
    }

    views {
        systemContext codeflareOperator "SystemContext" {
            include *
            autoLayout
        }

        container codeflareOperator "Containers" {
            include *
            autoLayout
        }

        component manager "Components" {
            include *
            autoLayout
        }

        styles {
            element "External Required" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
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
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

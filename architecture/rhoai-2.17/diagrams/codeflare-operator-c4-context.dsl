workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed AI/ML workloads using Ray clusters"
        mlEngineer = person "ML Engineer" "Orchestrates batch training jobs and manages resource quotas"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages lifecycle and security configuration for distributed AI/ML workloads using Ray clusters and AppWrapper orchestration" {
            operatorManager = container "Operator Manager" "Reconciles RayCluster and AppWrapper resources" "Go Operator" {
                rayController = component "RayCluster Controller" "Adds OAuth auth, mTLS, network policies, and ingress to Ray clusters" "Go Controller"
                appWrapperController = component "AppWrapper Controller" "Manages multi-resource workload units with gang scheduling" "Go Controller (Embedded)"
                webhookServer = component "Webhook Server" "Validates and mutates RayCluster and AppWrapper resources" "Go Admission Webhook"
                certController = component "Certificate Controller" "Rotates webhook TLS certificates" "Go Controller"
            }
        }

        kuberay = softwareSystem "KubeRay Operator" "Provides RayCluster CRD and manages Ray cluster lifecycle" "External Dependency"
        kueue = softwareSystem "Kueue" "Job queueing and resource quota management system" "External Dependency (Optional)"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API" "Platform"
        openShiftOAuth = softwareSystem "OpenShift OAuth Server" "Platform authentication service" "Platform (OpenShift only)"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"

        // User interactions
        dataScientist -> codeflareOperator "Creates RayCluster via kubectl"
        mlEngineer -> codeflareOperator "Creates AppWrapper for batch jobs via kubectl"
        dataScientist -> codeflareOperator "Accesses Ray dashboard via browser" "HTTPS/443"

        // Operator to external dependencies
        codeflareOperator -> kuberay "Watches RayCluster CRD availability" "Kubernetes API"
        codeflareOperator -> kueue "Creates and updates Workload resources" "Kubernetes API/6443, HTTPS, TLS 1.2+"
        codeflareOperator -> k8sAPI "Watches CRDs, creates/updates resources" "HTTPS/6443, TLS 1.2+"
        codeflareOperator -> openShiftOAuth "Validates user session tokens for dashboard access" "HTTPS/443, TLS 1.2+"
        prometheus -> codeflareOperator "Scrapes operator metrics" "HTTP/8080"

        // Internal component relationships
        rayController -> k8sAPI "Creates OAuth proxy, Routes, NetworkPolicies, Secrets"
        appWrapperController -> kueue "Submits workloads for scheduling"
        webhookServer -> k8sAPI "Called by API server on CR CREATE/UPDATE"
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

        component operatorManager "Components" {
            include *
            autoLayout
        }

        styles {
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #f5a623
                color #000000
            }
            element "Component" {
                background #bd10e0
                color #ffffff
            }
        }

        theme default
    }
}

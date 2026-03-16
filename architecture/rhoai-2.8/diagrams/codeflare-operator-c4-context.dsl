workspace {
    model {
        user = person "Data Scientist" "Submits distributed ML training jobs using CodeFlare SDK"

        codeflare = softwareSystem "CodeFlare Operator" "Manages distributed workload scheduling and auto-scaling for ML workloads" {
            manager = container "Manager Deployment" "Operator controller managing MCAD and InstaScale" "Go Operator" {
                mcad = component "MCAD Controller" "Multi-Cluster App Dispatcher for batch job queuing and scheduling" "Go Controller"
                instascale = component "InstaScale Controller" "Auto-scaling controller for compute resources (OpenShift only)" "Go Controller"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane" "External"
        kuberay = softwareSystem "KubeRay Operator" "Ray cluster management for distributed computing" "External"
        machineAPI = softwareSystem "OpenShift Machine API" "Machine and node provisioning (OpenShift only)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        codeflareSDK = softwareSystem "CodeFlare SDK" "Python SDK for distributed workload submission" "Internal ODH"

        # Relationships
        user -> codeflareSDK "Creates distributed jobs with"
        codeflareSDK -> k8sAPI "Creates AppWrapper CRs via" "kubectl/Python client"
        k8sAPI -> codeflare "Notifies of AppWrapper events via" "Watch API"

        codeflare -> k8sAPI "Manages resources via" "HTTPS/6443"
        codeflare -> kuberay "Creates RayCluster CRs in" "Kubernetes API"
        codeflare -> machineAPI "Scales MachineSets via" "Kubernetes API (OpenShift only)"
        prometheus -> codeflare "Scrapes metrics from" "HTTP/8080"

        mcad -> k8sAPI "Watches AppWrapper, manages Pods/Jobs/RayClusters"
        instascale -> k8sAPI "Creates/deletes MachineSets for scaling"
    }

    views {
        systemContext codeflare "SystemContext" {
            include *
            autoLayout
        }

        container codeflare "Containers" {
            include *
            autoLayout
        }

        component manager "Components" {
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
                color #000000
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

    configuration {
        scope softwaresystem
    }
}

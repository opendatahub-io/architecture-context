workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages distributed AI/ML workloads using CodeFlare SDK"

        codeflare = softwareSystem "CodeFlare Operator" "Manages distributed workload stack with MCAD queue scheduling and InstaScale auto-scaling for AI/ML workloads" {
            manager = container "Manager Deployment" "Hosts embedded controllers" "Go Operator" {
                mcad = component "MCAD Queue Controller" "Manages AppWrapper queueing, scheduling, and lifecycle" "Embedded v1.38.1"
                instascale = component "InstaScale Controller" "Auto-scales OpenShift MachineSets based on resource demands" "Optional"
            }
            metricsService = container "Metrics Service" "Exposes Prometheus metrics" "ClusterIP Service - 8080/TCP"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        kuberay = softwareSystem "KubeRay Operator" "Creates and manages Ray clusters for distributed computing" "Internal ODH"
        machineAPI = softwareSystem "OpenShift Machine API" "Manages cluster compute capacity via MachineSets" "External"
        cloudProvider = softwareSystem "Cloud Provider API" "Provisions/deprovisions VMs (AWS/Azure/GCP)" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"
        codeflareSdk = softwareSystem "CodeFlare SDK" "Python SDK for creating and managing CodeFlare resources" "Client Library"

        # User interactions
        user -> codeflareSdk "Uses to create AppWrappers and manage workloads" "Python API"
        codeflareSdk -> k8sAPI "Creates AppWrapper CRs via kubectl/client-go" "HTTPS/6443"
        user -> k8sAPI "Creates AppWrapper CRs directly" "kubectl/HTTPS/6443"

        # CodeFlare operator interactions
        k8sAPI -> mcad "Notifies of AppWrapper CR changes" "Watch"
        mcad -> k8sAPI "Manages AppWrappers, creates wrapped resources" "HTTPS/6443 - ServiceAccount Token"
        mcad -> kuberay "Creates RayCluster CRs for distributed workloads" "HTTPS/6443"

        k8sAPI -> instascale "Notifies of pending AppWrappers" "Watch"
        instascale -> machineAPI "Scales MachineSets when resources needed" "HTTPS/6443 - ServiceAccount Token"

        machineAPI -> cloudProvider "Provisions/deprovisions VMs" "HTTPS/443 - Cloud credentials"

        prometheus -> metricsService "Scrapes controller metrics" "HTTP/8080"

        # Deployment relationships
        manager -> mcad "Hosts"
        manager -> instascale "Hosts"
        manager -> metricsService "Exposes"
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
            element "Client Library" {
                background #50e3c2
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }

        theme default
    }
}

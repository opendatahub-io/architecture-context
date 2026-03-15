workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits distributed workloads (Ray clusters, PyTorch jobs) for training and batch processing"

        codeflare = softwareSystem "CodeFlare Operator" "Manages lifecycle of distributed workload scheduling and autoscaling components" {
            manager = container "CodeFlare Operator Manager" "Lifecycle management for MCAD and InstaScale" "Go Operator"
            mcad = container "MCAD Controller" "Queue-based workload scheduling and resource management" "Go Controller (embedded)"
            instascale = container "InstaScale Controller" "Dynamic cluster node scaling based on workload demands" "Go Controller (embedded, optional)"
            metrics = container "Metrics Server" "Prometheus metrics endpoint" "HTTP Server (port 8080)"
            health = container "Health Probe Server" "Kubernetes health check endpoints" "HTTP Server (port 8081)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "Kubernetes Core"
        kuberay = softwareSystem "KubeRay Operator" "Manages Ray cluster lifecycle" "Internal RHOAI Component"
        prometheus = softwareSystem "Prometheus" "Cluster monitoring and metrics collection" "Internal RHOAI Component"
        machineAPI = softwareSystem "OpenShift Machine API" "Manages cluster node provisioning" "OpenShift Core (Optional)"
        cloudProvider = softwareSystem "Cloud Provider API" "VM instance provisioning (AWS, GCP, Azure)" "External Cloud Service"

        # User interactions
        user -> codeflare "Creates AppWrapper CRs for distributed workloads via kubectl/oc"
        user -> k8sAPI "Submits workload definitions (AppWrapper, SchedulingSpec, QuotaSubtree)"

        # CodeFlare internal relationships
        manager -> mcad "Embeds and manages lifecycle"
        manager -> instascale "Embeds and manages lifecycle (optional)"
        manager -> metrics "Exposes Prometheus metrics"
        manager -> health "Exposes health probes"

        # CodeFlare to external systems
        mcad -> k8sAPI "Watches AppWrapper CRs and manages workload lifecycle" "HTTPS/6443 (TLS 1.2+)"
        mcad -> kuberay "Creates RayCluster CRs for Ray workloads" "HTTPS/6443 via K8s API"
        instascale -> k8sAPI "Watches AppWrappers and reads cluster nodes" "HTTPS/6443 (TLS 1.2+)"
        instascale -> machineAPI "Creates/deletes MachineSets for autoscaling" "HTTPS/6443 (TLS 1.2+)"
        metrics -> prometheus "Scraped for operator metrics" "HTTP/8080"

        # External system relationships
        kuberay -> k8sAPI "Creates Ray Head/Worker Pods" "HTTPS/6443"
        machineAPI -> cloudProvider "Provisions VM instances" "HTTPS/443 (TLS 1.2+)"
        prometheus -> metrics "Scrapes metrics via ServiceMonitor" "HTTP/8080"
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

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal RHOAI Component" {
                background #7ed321
                color #000000
            }
            element "External Cloud Service" {
                background #999999
                color #ffffff
            }
            element "Kubernetes Core" {
                background #326ce5
                color #ffffff
            }
            element "OpenShift Core (Optional)" {
                background #ee0000
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

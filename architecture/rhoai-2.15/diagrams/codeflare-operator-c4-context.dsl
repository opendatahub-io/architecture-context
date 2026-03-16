workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed Ray workloads for AI/ML training and inference"
        platformAdmin = person "Platform Admin" "Manages CodeFlare operator deployment and configuration"

        codeflare = softwareSystem "CodeFlare Operator" "Manages lifecycle of distributed workload components including RayClusters and AppWrappers with security enhancements" {
            rayController = container "RayCluster Controller" "Reconciles RayCluster CRs and manages networking, security resources" "Go Controller"
            appwrapperController = container "AppWrapper Controller" "Manages AppWrapper CRs for job queueing" "Go Controller"
            rayWebhook = container "RayCluster Webhook" "Validates and mutates RayCluster resources" "Go Webhook Server"
            appwrapperWebhook = container "AppWrapper Webhook" "Validates and mutates AppWrapper resources" "Go Webhook Server"
            certManager = container "Certificate Manager" "Manages webhook TLS certificates and CA certificates for mTLS" "Cert Rotator"
            metricsServer = container "Metrics Server" "Exposes operator metrics" "Prometheus Exporter"
        }

        kuberay = softwareSystem "KubeRay Operator" "Provides RayCluster CRD and base Ray operator functionality" "External"
        kueue = softwareSystem "Kueue" "Job queue management system for batch workloads" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "User authentication service" "External"
        serviceCa = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Platform operator managing OpenDataHub components" "Internal ODH"
        k8sApi = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "Platform"

        rayCluster = softwareSystem "Ray Cluster" "Distributed compute cluster for ML workloads" "Managed Resource" {
            rayHead = container "Ray Head Pod" "Ray cluster control plane with dashboard and client API" "Ray Head"
            rayWorkers = container "Ray Worker Pods" "Distributed compute workers" "Ray Workers"
            oauthProxy = container "OAuth Proxy" "Secure access to Ray dashboard on OpenShift" "OAuth Proxy Sidecar"
        }

        dataScientist -> codeflare "Creates RayCluster and AppWrapper CRs via kubectl/SDK"
        platformAdmin -> codeflare "Configures operator settings and monitors health"

        rayController -> k8sApi "Creates Services, Routes, NetworkPolicies, Secrets, ServiceAccounts" "HTTPS/6443"
        rayController -> kuberay "Watches RayCluster CRs" "K8s API"
        rayController -> rayCluster "Provisions and manages" "K8s API"
        rayController -> certManager "Uses for certificate management"

        appwrapperController -> k8sApi "Creates wrapped Kubernetes resources" "HTTPS/6443"
        appwrapperController -> kueue "Creates Workload CRs for queue management" "K8s API/6443"

        k8sApi -> rayWebhook "Validates/mutates RayCluster CRs" "HTTPS/9443 mTLS"
        k8sApi -> appwrapperWebhook "Validates/mutates AppWrapper CRs" "HTTPS/9443 mTLS"

        rayWebhook -> certManager "Uses TLS certificates"
        appwrapperWebhook -> certManager "Uses TLS certificates"

        prometheus -> metricsServer "Scrapes metrics via ServiceMonitor" "HTTPS/8080"

        oauthProxy -> oauthServer "Authenticates users" "HTTPS/443"
        oauthProxy -> rayHead "Proxies authenticated requests" "HTTP/8265"

        rayCluster -> serviceCa "Gets TLS certificates for OAuth service" "Service annotation"

        rayController -> odhOperator "Reads DSCInitialization for platform config" "K8s API"

        dataScientist -> rayCluster "Accesses Ray dashboard and submits jobs" "HTTPS/443"
        dataScientist -> rayHead "Connects Ray client" "mTLS/10001"

        rayHead -> rayWorkers "Distributes tasks" "Ray protocol with mTLS"
    }

    views {
        systemContext codeflare "SystemContext" {
            include *
            autoLayout
        }

        container codeflare "CodeFlareContainers" {
            include *
            autoLayout
        }

        container rayCluster "RayClusterContainers" {
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
            element "Platform" {
                background #f5a623
                color #000000
            }
            element "Managed Resource" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

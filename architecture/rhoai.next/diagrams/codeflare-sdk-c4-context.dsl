workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters and submits distributed computing jobs"

        codeflareSdk = softwareSystem "CodeFlare SDK" "Python SDK for Ray cluster and job lifecycle management on Kubernetes" {
            facade = container "Codeflare Facade" "Single entrypoint; client isolation via ContextVar" "Python"
            clusterHandler = container "ClusterHandler" "RayCluster CR lifecycle, ingress discovery, status display" "Python"
            jobHandler = container "JobHandler" "RayJob CR lifecycle, job submission via Ray client" "Python"
            authModule = container "Auth Module" "Kubernetes authentication via kube-authkit" "Python"
            kueueModule = container "Kueue Integration" "Queue discovery, priority validation, autoscaling gating" "Python"
            tlsGenerator = container "TLS Generator" "RSA-3072 / SHA-256 client certificate generation" "Python (cryptography)"
            kuberayClient = container "KubeRay Python Client" "Vendored client for RayCluster/RayJob CR CRUD" "Python"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Manages Ray cluster pods from RayCluster/RayJob CRs" "Internal Platform"
        kueue = softwareSystem "Kueue" "Workload queuing and quota-aware scheduling" "Internal Platform"
        openshiftRoutes = softwareSystem "OpenShift Route Controller" "Manages OpenShift Routes for service exposure" "External"
        gatewayAPI = softwareSystem "Kubernetes Gateway API" "HTTPRoute/Gateway for service exposure" "External"
        rhoaiPlatform = softwareSystem "RHOAI Platform" "DataScienceCluster and GatewayConfig management" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        rayHead = softwareSystem "Ray Head Node" "Distributed compute head node with dashboard" "Internal Platform"

        dataScientist -> codeflareSdk "Creates clusters, submits jobs" "Python API"

        facade -> clusterHandler "cf.clusters"
        facade -> jobHandler "cf.jobs"
        facade -> authModule "authenticates"
        clusterHandler -> kueueModule "validates queues"
        clusterHandler -> tlsGenerator "generates certs"
        jobHandler -> kuberayClient "CR operations"
        jobHandler -> kueueModule "validates queues"

        codeflareSdk -> kubernetesAPI "All API operations" "HTTPS/443"
        codeflareSdk -> kuberayOperator "Creates RayCluster/RayJob CRs" "HTTPS/443 via K8s API"
        codeflareSdk -> kueue "Reads LocalQueue, WorkloadPriorityClass" "HTTPS/443 via K8s API"
        codeflareSdk -> openshiftRoutes "Discovers dashboard URLs" "HTTPS/443 via K8s API"
        codeflareSdk -> gatewayAPI "Discovers dashboard URLs (fallback)" "HTTPS/443 via K8s API"
        codeflareSdk -> rhoaiPlatform "Checks Kueue state, resolves gateway hostname" "HTTPS/443 via K8s API"
        codeflareSdk -> certManager "Reads CA secrets (indirect)" "HTTPS/443 via K8s API"
        codeflareSdk -> rayHead "Job submission and status" "HTTP(S)/8265, TCP/6379"
    }

    views {
        systemContext codeflareSdk "SystemContext" {
            include *
            autoLayout
        }

        container codeflareSdk "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #000000
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

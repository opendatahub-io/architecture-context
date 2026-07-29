workspace {
    model {
        user = person "Data Scientist" "Creates and submits ML training/inference jobs via notebooks or scripts"

        codeflareSdk = softwareSystem "codeflare-sdk" "Python client SDK for CodeFlare/Ray cluster management and job submission on RHOAI" {
            authModule = container "Authentication Module" "Handles Kubernetes authentication via Bearer token, kubeconfig, or auto-detection" "Python (auth.py)"
            rayJobClient = container "RayJobClient" "Wraps Ray JobSubmissionClient for job lifecycle management" "Python (ray_jobs.py)"
            tlsResolver = container "TLS Certificate Resolver" "Resolves CA certificates from explicit path, env var, or OpenShift defaults" "Python (auth.py)"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for authentication and resource operations" "External"
        rayCluster = softwareSystem "Ray Cluster" "Distributed compute cluster managed by KubeRay operator" "Internal RHOAI"
        kubeRay = softwareSystem "KubeRay Operator" "Manages Ray cluster lifecycle on Kubernetes" "Internal RHOAI"
        openshift = softwareSystem "OpenShift" "Container platform providing Routes and OAuth" "External"

        user -> codeflareSdk "Imports SDK, authenticates, submits jobs" "Python API"
        codeflareSdk -> k8sApi "Authenticates, discovers cluster endpoints" "HTTPS/6443, Bearer/kubeconfig/SA"
        codeflareSdk -> rayCluster "Submits/manages jobs, retrieves logs" "HTTP(S)/8265"
        rayCluster -> kubeRay "Managed by" "Kubernetes API"
        codeflareSdk -> openshift "Discovers Ray dashboard via Routes" "route.openshift.io API"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

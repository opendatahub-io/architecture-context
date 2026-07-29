workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages Ray clusters, jobs, and services for ML workloads"
        admin = person "Platform Admin" "Manages KubeRay operator deployment and configuration"

        kuberay = softwareSystem "KubeRay" "Kubernetes operator for managing Ray clusters, jobs, and services on OpenShift" {
            operator = container "KubeRay Operator" "Reconciles RayCluster, RayJob, RayService, and RayCronJob CRs; manages pod lifecycle, networking, mTLS, and authentication" "Go / controller-runtime"
            apiserver = container "KubeRay API Server" "gRPC + HTTP gateway providing REST and gRPC management APIs for Ray resources; reverse-proxies to Kubernetes API" "Go / gRPC"
            securityProxy = container "Security Proxy" "Token-authenticated reverse proxy for HTTP and gRPC traffic to Ray head nodes" "Go"
            webhooks = container "Admission Webhooks" "Mutating and validating webhooks for RayCluster, RayJob, and RayService resources" "Go / controller-runtime"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics on port 8080" "Go / HTTP"
        }

        kubernetes = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform and API server" "External" {
            tags "External"
        }
        certManager = softwareSystem "cert-manager" "X.509 certificate management for Kubernetes" "External" {
            tags "External"
        }
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress routing" "External" {
            tags "External"
        }
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External" {
            tags "External"
        }
        openshiftConfig = softwareSystem "OpenShift Configuration" "Cluster-wide API server, authentication, and OAuth configuration" "External" {
            tags "External"
        }
        openshiftRoutes = softwareSystem "OpenShift Routes" "Route-based ingress for dashboard access" "External" {
            tags "External"
        }
        rayCluster = softwareSystem "Ray Cluster" "Distributed Ray head and worker pods running ML workloads" "Runtime" {
            tags "Runtime"
        }

        # User interactions
        datascientist -> kuberay "Creates RayCluster, RayJob, RayService CRs via kubectl"
        datascientist -> apiserver "Manages Ray resources via REST/gRPC API" "gRPC/8887, HTTP/8888"
        datascientist -> securityProxy "Accesses Ray dashboard and APIs" "HTTP/gRPC, Bearer Token"
        admin -> kubernetes "Deploys and configures KubeRay operator"

        # Operator interactions
        operator -> kubernetes "Watches CRDs, manages Pods, Services, Secrets, Jobs, NetworkPolicies" "HTTPS/6443, SA Token"
        operator -> certManager "Creates Certificate and Issuer CRs for mTLS" "Kubernetes API"
        operator -> gatewayAPI "Manages HTTPRoute and Gateway resources for service routing" "Kubernetes API"
        operator -> openshiftConfig "Reads APIServer, Authentication, OAuth configuration" "Kubernetes API"
        operator -> openshiftRoutes "Creates and manages Routes for dashboard access" "Kubernetes API"
        operator -> rayCluster "Creates and manages Ray head and worker pods" "Kubernetes API"

        # API server interactions
        apiserver -> kubernetes "Reverse-proxies to Kubernetes API" "HTTPS/6443, SA Token"

        # Security proxy interactions
        securityProxy -> rayCluster "Proxies authenticated requests to Ray head node" "HTTP/gRPC"

        # Webhooks
        kubernetes -> webhooks "Sends admission requests for Ray CRDs" "TLS"

        # Monitoring
        prometheus -> metricsServer "Scrapes /metrics endpoint" "HTTP/8080"
    }

    views {
        systemContext kuberay "SystemContext" {
            include *
            autoLayout
        }

        container kuberay "Containers" {
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
            element "Runtime" {
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

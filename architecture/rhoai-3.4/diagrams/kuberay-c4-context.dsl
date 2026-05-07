workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray distributed computing clusters, jobs, and serving deployments"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters, jobs, and serving deployments on Kubernetes via CRDs" {
            rayClusterReconciler = container "RayClusterReconciler" "Core cluster orchestration — creates head/worker pods, services, ingress/routes, RBAC, Redis cleanup" "Go Controller"
            rayJobReconciler = container "RayJobReconciler" "Job submission and lifecycle — creates RayClusters, submitter K8s Jobs, interacts with Ray Dashboard API" "Go Controller"
            rayServiceReconciler = container "RayServiceReconciler" "Ray Serve deployment — zero-downtime upgrades via active/pending cluster switching" "Go Controller"
            authController = container "AuthenticationController" "OAuth/OIDC auth infrastructure — HTTPRoutes, ReferenceGrants, kube-rbac-proxy ConfigMaps" "Go Controller"
            networkPolicyCtrl = container "NetworkPolicyController" "Network access control — creates NetworkPolicies for head and worker pods" "Go Controller"
            mtlsController = container "RayClusterMTLSController" "mTLS certificate management — cert-manager Issuers and Certificates with dynamic pod IP SANs" "Go Controller"
            webhook = container "Admission Webhooks" "Mutating: defaults OpenShift settings; Validating: DNS1035 name, worker group uniqueness" "Go Webhook Server"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing API server, scheduling, and resource management" "External"
        ray = softwareSystem "Ray Runtime" "Distributed computing framework running in head and worker pods managed by operator" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate management — provides CA issuers and pod certificates for mTLS" "External"
        gateway = softwareSystem "RHOAI Gateway" "Platform Gateway API endpoint (data-science-gateway) for HTTPRoute-based ingress" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OpenShift built-in OAuth server for IntegratedOAuth authentication mode" "External"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar for OIDC-based RBAC enforcement via TokenReview and SubjectAccessReview" "External"
        redis = softwareSystem "Redis" "Optional external storage for Ray GCS fault tolerance" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring platform" "External"
        volcano = softwareSystem "Volcano" "Optional batch scheduler for gang scheduling of Ray pods" "External"
        yunikorn = softwareSystem "YuniKorn" "Optional batch scheduler with task group annotations for gang scheduling" "External"
        schedulerPlugins = softwareSystem "scheduler-plugins" "Optional Kubernetes scheduler-plugins for coscheduling via PodGroups" "External"
        s3 = softwareSystem "Object Storage" "Model and artifact storage (S3-compatible) accessed by Ray workloads" "External"

        user -> kuberay "Creates RayCluster, RayJob, RayService via kubectl" "HTTPS/443"
        kuberay -> kubernetes "CRD CRUD, pod/service/secret management, leader election" "HTTPS/443"
        kuberay -> ray "Manages lifecycle, submits jobs, updates serve configs" "HTTP/8265"
        kuberay -> certManager "Creates Issuer and Certificate CRs for mTLS" "HTTPS/443"
        kuberay -> gateway "Creates HTTPRoutes for per-cluster dashboard access" "Gateway API"
        kuberay -> openshiftOAuth "Reads cluster auth configuration, delegates via oauth-proxy" "HTTPS/443"
        kuberay -> kubeRbacProxy "Injects sidecar for RBAC enforcement" "HTTPS/8443"
        kuberay -> redis "GCS fault tolerance storage, cleanup on deletion" "Redis/6379"
        kuberay -> volcano "Creates PodGroup CRs for gang scheduling" "HTTPS/443"
        kuberay -> yunikorn "Adds task group annotations for gang scheduling" "Pod Annotations"
        kuberay -> schedulerPlugins "Creates PodGroup CRs for coscheduling" "HTTPS/443"
        prometheus -> kuberay "Scrapes operator and cluster metrics" "HTTP/8080"
        ray -> s3 "Downloads model artifacts and data" "HTTPS/443"
        user -> gateway "Accesses Ray Dashboard via authenticated gateway" "HTTPS/443"

        rayClusterReconciler -> kubernetes "Creates pods, services, secrets, RBAC" "HTTPS/443"
        rayJobReconciler -> ray "Submits jobs, polls status" "HTTP/8265"
        rayJobReconciler -> kubernetes "Creates submitter K8s Jobs" "HTTPS/443"
        rayServiceReconciler -> ray "Updates serve configs, health checks" "HTTP/8265"
        authController -> gateway "Creates HTTPRoutes, ReferenceGrants" "Gateway API"
        authController -> kubernetes "Creates ServiceAccounts, ConfigMaps" "HTTPS/443"
        mtlsController -> certManager "Creates Issuer and Certificate CRs" "HTTPS/443"
        networkPolicyCtrl -> kubernetes "Creates NetworkPolicies" "HTTPS/443"
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

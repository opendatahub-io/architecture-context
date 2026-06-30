workspace {
    model {
        user = person "Data Scientist / Platform Operator" "Creates and manages Ray clusters, jobs, and serving deployments"
        extUser = person "External User" "Accesses Ray Dashboard via authenticated Gateway"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator managing Ray cluster lifecycle, jobs, and serving deployments on OpenShift" {
            rcController = container "RayCluster Controller" "Reconciles RayCluster CRs into head/worker pods, services, ingress, RBAC" "Go (controller-runtime)"
            rjController = container "RayJob Controller" "Manages Ray job submission via K8s Jobs or HTTP, retries, suspension, deletion" "Go (controller-runtime)"
            rsController = container "RayService Controller" "Zero-downtime Ray Serve upgrades via pending cluster promotion" "Go (controller-runtime)"
            authController = container "Authentication Controller" "Manages OAuth/OIDC — HTTPRoutes, ReferenceGrants, kube-rbac-proxy injection" "Go (controller-runtime)"
            npController = container "NetworkPolicy Controller" "Creates head and worker NetworkPolicies for annotation-enabled clusters" "Go (controller-runtime)"
            mtlsController = container "mTLS Controller" "Manages cert-manager Issuers and Certificates for Ray cluster mutual TLS" "Go (controller-runtime)"
            mutatingWebhook = container "Mutating Webhook" "Defaults secure-trusted-network annotation, enforces enableIngress=false on OpenShift" "Go (admission webhook)" "9443/TCP HTTPS"
            validatingWebhook = container "Validating Webhook" "Validates RayCluster name format and worker group uniqueness" "Go (admission webhook)" "9443/TCP HTTPS"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource CRUD, authentication, authorization" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management — mTLS cert chain for Ray clusters" "External"
        gatewayApi = softwareSystem "data-science-gateway" "Gateway API Gateway CR in openshift-ingress for external dashboard routing" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "OIDC auth enforcement sidecar injected into Ray head pods" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth/OIDC" "Identity provider configuration discovery" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Webhook TLS certificate provisioning" "External"
        redis = softwareSystem "External Redis" "Optional GCS fault tolerance external storage" "External"
        volcano = softwareSystem "Volcano / Yunikorn / scheduler-plugins" "Optional batch scheduler for gang scheduling" "External"
        codeflare = softwareSystem "CodeFlare Operator" "Peer component — webhooks intercept RayCluster CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Peer component — webhooks intercept RayCluster CRDs, managedBy support" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI / ODH Operator" "Deploys KubeRay operator via kustomize manifests" "Internal RHOAI"

        # User interactions
        user -> kuberay "Creates RayCluster, RayJob, RayService CRs" "kubectl / API"
        extUser -> gatewayApi "Accesses Ray Dashboard" "HTTPS/443"

        # Core dependencies
        kuberay -> k8sApi "CRUD for pods, services, secrets, CRDs, RBAC" "HTTPS/443 TLS 1.2+"
        kuberay -> certManager "Creates Issuers and Certificates for mTLS" "CRD Watch + Create"
        kuberay -> gatewayApi "Creates HTTPRoutes and ReferenceGrants" "Gateway API"
        kuberay -> kubeRbacProxy "Injects as sidecar for dashboard auth" "Container injection"
        kuberay -> openshiftOAuth "Reads authentication/oauth config" "HTTPS/443"
        kuberay -> serviceCa "Webhook TLS cert provisioning" "Annotation-based"

        # Optional dependencies
        kuberay -> redis "GCS fault tolerance storage" "TCP/6379"
        kuberay -> volcano "Gang scheduling for Ray pods" "Scheduler plugin"

        # Peer component interactions
        codeflare -> kuberay "Mutating/validating webhooks on RayCluster" "Admission webhooks"
        kueue -> kuberay "Mutating/validating webhooks on RayCluster, managedBy" "Admission webhooks"
        rhoaiOperator -> kuberay "Deploys operator via kustomize" "Kustomize manifests"

        # Internal container flows
        rcController -> k8sApi "Creates head/worker pods, services" "HTTPS/443"
        rjController -> k8sApi "Creates K8s Jobs for submission" "HTTPS/443"
        authController -> k8sApi "Creates ServiceAccounts, ConfigMaps" "HTTPS/443"
        mtlsController -> certManager "Creates cert-manager resources" "CRD API"
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

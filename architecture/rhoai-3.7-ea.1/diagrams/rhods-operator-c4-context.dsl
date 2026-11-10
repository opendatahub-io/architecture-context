workspace "rhods-operator" "RHOAI 3.7-ea.1 platform operator" {
    model {
        admin = person "Platform Administrator" "Configures DataScienceCluster, DSCInitialization, Auth and GatewayConfig"
        user = person "Data Scientist / API Client" "Accesses RHOAI UIs and APIs through the platform Gateway"

        rhods = softwareSystem "rhods-operator" "RHOAI platform operator: reconciles DSC/DSCI/Platform and service CRs, orchestrates built-in module operators, owns platform ingress and authentication" {
            manager = container "Manager" "DSC, DSCI, Platform, Kueue, module, gateway, auth, certconfigmapgenerator and HardwareProfile controllers; metrics 8443/TCP HTTPS" "Go, controller-runtime v0.25.1"
            webhook = container "Webhook Server" "Validating/mutating webhooks for DSC, DSCI, GatewayConfig, profiles, Prometheus monitors; Platform conversion; 9443/TCP HTTPS" "Go, controller-runtime"
            cloudmanager = container "cloudmanager" "Reconciles AWS/Azure/CoreWeave KubernetesEngine CRs; installs XKS prerequisite charts" "Go, Cobra"
            kubeAuthProxy = container "kube-auth-proxy" "Gateway ext_authz backend and OAuth/OIDC login handler; 8443/TCP HTTPS" "Go, oauth2-proxy fork"
            gateway = container "data-science-gateway" "Gateway API Gateway in openshift-ingress; 443/TCP HTTPS TLS Terminate; EnvoyFilter ext_authz + Lua" "Istio / OSSM Envoy"
            dashboardRedirect = container "dashboard-redirect" "Legacy dashboard URL 301 redirects; 8080/TCP HTTP" "nginx (ubi9/nginx-126)"
        }

        k8s = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        olm = softwareSystem "OLM" "Installs and upgrades the operator from CSV rhods-operator" "External"
        router = softwareSystem "OpenShift Router" "Route-based external exposure (reencrypt / edge)" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Issues webhook, metrics, gateway and proxy certificates" "External"
        oauth = softwareSystem "OpenShift OAuth Server" "OAuth mode identity provider" "External"
        oidc = softwareSystem "External OIDC Issuer" "OIDC mode identity provider" "External"
        istio = softwareSystem "OpenShift Service Mesh / Istio" "Implements GatewayClass and EnvoyFilter" "External"
        xksPrereqs = softwareSystem "XKS Prerequisites" "Gateway API, LWS, Sail, RHCL, cert-manager" "External"

        modules = softwareSystem "Built-in Module Operators" "dashboard, kserve, aipipelines, workbenches, ray, trainer, trustyai, mlflow, spark, ogx, aigateway, aihub, data, databaseservice, mcplifecycle, monitoring" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "In-tree component: workload queueing" "Internal RHOAI"
        backends = softwareSystem "Platform Backends" "Dashboard and model APIs behind the Gateway" "Internal RHOAI"
        monitoring = softwareSystem "Monitoring Stack" "Prometheus in redhat-ods-monitoring" "Internal RHOAI"
        maas = softwareSystem "Models-as-a-Service / Kuadrant" "Receives admin-group RoleBindings" "Internal RHOAI"

        admin -> k8s "Creates DSC / DSCI / Auth / GatewayConfig" "HTTPS/6443"
        olm -> manager "Installs and upgrades"
        k8s -> webhook "Admission and conversion requests" "HTTPS 443->9443, caBundle"
        manager -> k8s "Watches CRs, server-side applies modules, CRDs, RBAC" "HTTPS/6443, SA token"
        cloudmanager -> k8s "Reconciles engine CRs, applies charts" "HTTPS/6443, SA token"
        cloudmanager -> xksPrereqs "Installs via Helm"
        manager -> modules "Renders and deploys module operators, reads status" "Helm / Kustomize via SSA"
        manager -> kueue "Manages Kueue CR"
        manager -> gateway "Creates GatewayClass, Gateway, EnvoyFilter, DestinationRule, HTTPRoute"
        manager -> kubeAuthProxy "Deploys and configures"
        manager -> dashboardRedirect "Deploys"
        manager -> maas "Creates admin-group RoleBindings"
        manager -> serviceCa "Requests certificates via annotations"
        gateway -> istio "Implemented by"

        user -> router "Accesses platform" "HTTPS/443"
        router -> gateway "Forwards" "HTTPS/443 reencrypt"
        router -> dashboardRedirect "Legacy URLs" "HTTP/8080"
        gateway -> kubeAuthProxy "ext_authz /oauth2/auth" "HTTPS/8443, cert not verified"
        kubeAuthProxy -> oauth "OAuth2 code flow" "HTTPS/443"
        kubeAuthProxy -> oidc "OIDC login" "HTTPS/443"
        kubeAuthProxy -> k8s "TokenReview" "HTTPS/6443"
        gateway -> backends "Forwards with Bearer user token" "HTTPS/HTTP"
        monitoring -> manager "Scrapes /metrics" "HTTPS/8443, Bearer"
    }

    views {
        systemContext rhods "SystemContext" {
            include *
            autoLayout
        }

        container rhods "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}

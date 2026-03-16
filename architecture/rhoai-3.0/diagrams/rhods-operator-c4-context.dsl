workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages data science workloads, notebooks, pipelines, and model deployments"
        admin = person "Platform Administrator" "Configures and manages RHOAI platform via DataScienceCluster and DSCInitialization CRs"

        rhodsOperator = softwareSystem "RHODS Operator (OpenDataHub Operator)" "Central control plane for Red Hat OpenShift AI and Open Data Hub platforms. Manages lifecycle of data science components and infrastructure services." {
            manager = container "Operator Manager" "Main operator process managing reconciliation loops" "Go, controller-runtime" {
                dscController = component "DataScienceCluster Controller" "Manages component enablement/removal" "Go Reconciler"
                dsciController = component "DSCInitialization Controller" "Platform initialization and configuration" "Go Reconciler"
                gatewayController = component "Gateway Service Controller" "Deploys Gateway API infrastructure" "Go Reconciler"
                componentControllers = component "Component Controllers" "Dashboard, Workbenches, Pipelines, KServe, Ray, etc." "Go Reconcilers"
            }
            webhooks = container "Webhook Server" "Validates and mutates DSC, DSCI, and component CRs" "Go HTTPS Service"
        }

        gatewayInfra = softwareSystem "Gateway API Infrastructure" "Platform ingress gateway for all RHOAI components" "RHOAI 3.x Core" {
            gateway = container "Gateway (data-science-gateway)" "HTTPS/443 ingress endpoint" "Gateway API v1"
            envoyFilter = container "EnvoyFilter (authn-filter)" "ext_authz authentication filter" "Istio EnvoyFilter"
            kubeAuthProxy = container "kube-auth-proxy" "OAuth2/OIDC authentication proxy" "OAuth2-proxy"
        }

        componentWorkloads = softwareSystem "Data Science Components" "Deployed and managed data science workloads" "RHOAI Components" {
            dashboard = container "ODH Dashboard" "Web UI for data science platform" "React, Node.js"
            notebooks = container "Jupyter Notebooks (Workbenches)" "Interactive development environments" "JupyterLab"
            pipelines = container "Data Science Pipelines" "ML pipeline orchestration" "Kubeflow Pipelines, Argo"
            kserve = container "KServe" "Model serving inference platform" "KServe Operator"
            ray = container "Ray" "Distributed computing framework" "Kuberay Operator"
            modelRegistry = container "Model Registry" "ML model metadata and versioning" "Model Registry Service"
        }

        k8s = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External"
        ingressController = softwareSystem "OpenShift Ingress Controller" "Manages cluster ingress and TLS certificates" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "User authentication (IntegratedOAuth mode)" "External"
        oidcProvider = softwareSystem "External OIDC Provider" "User authentication (ROSA/OIDC mode)" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring stack management" "External"
        istio = softwareSystem "Istio / OpenShift Service Mesh" "Service mesh for EnvoyFilter integration" "External (Optional)"
        registries = softwareSystem "Container Registries" "quay.io, registry.redhat.io" "External"
        clusterMonitoring = softwareSystem "OpenShift Cluster Monitoring" "Cluster-wide metrics and alerting" "External"

        // User interactions
        user -> dashboard "Creates notebooks, pipelines, deploys models via Web UI" "HTTPS/443"
        user -> notebooks "Develops ML models in Jupyter notebooks" "HTTPS/443"
        admin -> rhodsOperator "Configures platform via DataScienceCluster CR" "kubectl/OpenShift Console"

        // Operator core flows
        rhodsOperator -> k8s "Manages CRDs, deployments, services, RBAC" "Kubernetes API (HTTPS/6443)"
        rhodsOperator -> gatewayInfra "Deploys and configures gateway infrastructure" "Kubernetes API"
        rhodsOperator -> componentWorkloads "Deploys and manages component lifecycle" "Kubernetes API"
        rhodsOperator -> registries "Pulls component container images" "HTTPS/443"

        // Gateway infrastructure
        gatewayInfra -> ingressController "Provisions gateway endpoint and TLS certs" "Kubernetes API"
        gatewayInfra -> oauthServer "Authenticates users (IntegratedOAuth)" "OAuth 2.0 (HTTPS/443)"
        gatewayInfra -> oidcProvider "Authenticates users (OIDC mode)" "OIDC (HTTPS/443)"
        gatewayInfra -> istio "Uses EnvoyFilter for ext_authz" "Service Mesh Integration"

        // Component workloads
        componentWorkloads -> gatewayInfra "Receives user requests via HTTPRoutes" "HTTPS/443"
        componentWorkloads -> k8s "Create workload-specific resources" "Kubernetes API"

        // Monitoring
        rhodsOperator -> prometheusOperator "Creates ServiceMonitors, PrometheusRules" "Kubernetes API"
        rhodsOperator -> clusterMonitoring "Federates metrics to cluster monitoring" "Prometheus Federation (HTTPS/9091)"
        componentWorkloads -> clusterMonitoring "Expose metrics for scraping" "Prometheus scrape"

        // External user access flow
        user -> gatewayInfra "Access RHOAI services" "HTTPS/443"
        gatewayInfra -> componentWorkloads "Route authenticated requests" "HTTPRoute"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout
        }

        container rhodsOperator "RHODSOperatorContainers" {
            include *
            autoLayout
        }

        container gatewayInfra "GatewayInfrastructure" {
            include *
            autoLayout
        }

        container componentWorkloads "ComponentWorkloads" {
            include *
            autoLayout
        }

        dynamic rhodsOperator "ComponentDeployment" "Component enablement via DataScienceCluster" {
            admin -> rhodsOperator "1. Create DataScienceCluster CR (enable Dashboard, Workbenches, KServe)"
            rhodsOperator -> k8s "2. Validate CR via webhook server"
            rhodsOperator -> k8s "3. Create component-specific CRs (Dashboard, Workbenches, Kserve)"
            rhodsOperator -> registries "4. Pull component container images"
            rhodsOperator -> componentWorkloads "5. Deploy component manifests (Deployments, Services, HTTPRoutes)"
            componentWorkloads -> gatewayInfra "6. Register HTTPRoutes with platform gateway"
            autoLayout
        }

        dynamic gatewayInfra "UserAuthentication" "External user authentication flow (RHOAI 3.x)" {
            user -> gateway "1. HTTPS request to *.apps.<cluster-domain>"
            gateway -> envoyFilter "2. ext_authz check for all requests"
            envoyFilter -> kubeAuthProxy "3. Validate session cookie"
            kubeAuthProxy -> oauthServer "4. If no session: redirect to OAuth/OIDC login"
            oauthServer -> kubeAuthProxy "5. OAuth code / OIDC tokens returned"
            kubeAuthProxy -> user "6. Set httpOnly, secure session cookie"
            envoyFilter -> componentWorkloads "7. If valid session: route to backend via HTTPRoute"
            autoLayout
        }

        styles {
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "RHOAI 3.x Core" {
                background #7ed321
                color #000000
            }
            element "RHOAI Components" {
                background #50e3c2
                color #000000
            }
            element "External (Optional)" {
                background #cccccc
                color #000000
            }
        }

        theme default
    }
}

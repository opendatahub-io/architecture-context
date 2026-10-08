workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Configures the RHOAI platform via DataScienceCluster and DSCInitialization CRs"
        dataScientist = person "Data Scientist" "Uses AI/ML platform services deployed by the operator"

        rhodsOperator = softwareSystem "rhods-operator" "Central control-plane operator that installs, configures, and lifecycle-manages the RHOAI platform and its ~16 AI/ML components" {
            manager = container "manager" "Primary operator binary — runs all platform controllers, webhooks, and component reconcilers" "Go controller-runtime" "Operator"
            cloudmanager = container "cloudmanager" "Cloud infrastructure controller for AWS/Azure/CoreWeave Kubernetes engine CRDs (RHAII mode)" "Go" "Operator"
            kubeAuthProxy = container "kube-auth-proxy" "OIDC authentication proxy for platform Gateway API ingress" "Go" "Proxy"
            webhookServer = container "Webhook Server" "Validates, mutates, and converts platform CRDs (singleton enforcement, field validation, version conversion)" "Go controller-runtime webhook" "Webhook"
            gatewayController = container "Gateway Controller" "Manages Gateway API stack: HTTPRoutes, EnvoyFilters, DestinationRules, kube-auth-proxy, and legacy redirect Routes" "Go" "Controller"
            componentHandlers = container "Component Handlers" "~16 module handlers rendering kustomize manifests for managed components (Dashboard, KServe, Ray, Kueue, Model Registry, TrustyAI, Workbenches, Pipelines, etc.)" "Go" "Handler"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource CRUD, watch, and admission" "External"
        openshiftPlatform = softwareSystem "OpenShift Platform" "OpenShift-specific services: Router, Console, OAuth, APIServer config, service-ca" "External"
        gatewayAPI = softwareSystem "Gateway API" "Gateway API resources (Gateway, HTTPRoute, DestinationRule, EnvoyFilter)" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring CRD management (PodMonitor, PrometheusRule)" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator subscriptions and upgrades" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management (conditional)" "External"

        # Managed AI/ML components
        dashboard = softwareSystem "ODH Dashboard" "Web UI for the AI/ML platform" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving and inference" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing system" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata registry" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI explainability and fairness" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments" "Internal RHOAI"
        pipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"

        # Cloud providers (RHAII)
        awsEKS = softwareSystem "AWS EKS" "AWS Kubernetes Engine" "Cloud Provider"
        azureAKS = softwareSystem "Azure AKS" "Azure Kubernetes Engine" "Cloud Provider"
        coreweave = softwareSystem "CoreWeave" "CoreWeave Kubernetes Engine" "Cloud Provider"

        # Relationships
        clusterAdmin -> rhodsOperator "Creates DataScienceCluster & DSCInitialization CRs" "kubectl / HTTPS"
        dataScientist -> kubeAuthProxy "Accesses platform services" "HTTPS/443 OIDC"

        manager -> kubernetesAPI "CRUD all resources, watches, status updates" "HTTPS/6443 SA token"
        manager -> openshiftPlatform "Reads TLS profile, ingress domain, creates Routes/ConsoleLinks" "HTTPS/6443"
        manager -> gatewayAPI "Manages Gateway, HTTPRoute, DestinationRule lifecycle" "HTTPS/6443"
        manager -> prometheusOperator "Manages PodMonitor and PrometheusRule" "HTTPS/6443"
        manager -> olm "Reads/patches OLM subscriptions" "HTTPS/6443"
        manager -> certManager "Watches Certificate CRs (conditional)" "HTTPS/6443"

        gatewayController -> kubeAuthProxy "Deploys and manages" "Kubernetes API"
        componentHandlers -> dashboard "Deploys via kustomize manifests"
        componentHandlers -> kserve "Deploys via kustomize manifests"
        componentHandlers -> ray "Deploys via kustomize manifests"
        componentHandlers -> kueue "Deploys via kustomize manifests"
        componentHandlers -> modelRegistry "Deploys via kustomize manifests"
        componentHandlers -> trustyai "Deploys via kustomize manifests"
        componentHandlers -> workbenches "Deploys via kustomize manifests"
        componentHandlers -> pipelines "Deploys via kustomize manifests"

        cloudmanager -> awsEKS "Provisions EKS clusters" "HTTPS"
        cloudmanager -> azureAKS "Provisions AKS clusters" "HTTPS"
        cloudmanager -> coreweave "Provisions CoreWeave clusters" "HTTPS"

        kubeAuthProxy -> kubernetesAPI "TokenReview validation" "HTTPS/6443 SA token"

        kubernetesAPI -> webhookServer "Admission requests" "HTTPS/443→9443"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout
        }

        container rhodsOperator "Containers" {
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
            element "Cloud Provider" {
                background #f5a623
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Proxy" {
                background #50e3c2
                color #333333
            }
            element "Webhook" {
                background #bd10e0
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Handler" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

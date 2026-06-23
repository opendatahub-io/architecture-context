workspace {
    model {
        admin = person "Platform Admin" "Installs and configures the RHOAI platform"
        sre = person "SRE Engineer" "Monitors and responds to platform alerts (managed service)"

        odhDeployer = softwareSystem "odh-deployer" "Bootstraps the RHOAI platform by creating namespaces, KfDef CRs, monitoring stack, network policies, RBAC, and dashboard resources" {
            deployScript = container "deploy.sh" "Main deployment orchestrator — creates namespaces, applies KfDef CRs, configures monitoring, network policies, RBAC, and dashboard resources" "Bash Script (Init Container)"
            kfdefManifests = container "KfDef Manifests" "Define component installations: dashboard, notebook controller, model mesh, monitoring, notebooks, DSPO, anaconda" "YAML CRs"
            prometheusStack = container "Prometheus Stack" "Monitors RHOAI platform with SLO burn-rate alerting, federation from OpenShift Prometheus, and OAuth-protected endpoints" "Prometheus + Alertmanager + Blackbox Exporter"
            networkPolicies = container "Network Policies" "Define namespace-scoped ingress rules for applications, monitoring, and operator namespaces" "YAML Manifests"
            dashboardResources = container "Dashboard Resources" "CRDs (OdhApplication, OdhDocument, OdhQuickStart, OdhDashboardConfig), ISV tiles, and ConsoleLink" "YAML CRDs + Kustomize"
        }

        rhodsOperator = softwareSystem "rhods-operator" "Reconciles KfDef CRs to install platform components" "Internal RHOAI"
        odhDashboard = softwareSystem "odh-dashboard" "RHOAI Dashboard UI for data scientists" "Internal RHOAI"
        notebookController = softwareSystem "odh-notebook-controller" "Manages Jupyter notebook lifecycle" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving platform" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages ML pipeline workflows" "Internal RHOAI"
        rhodsNotebooks = softwareSystem "rhods-notebooks" "Notebook image streams" "Internal RHOAI"
        anaconda = softwareSystem "Anaconda CE" "Anaconda Community Edition integration" "Internal RHOAI"

        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes/OpenShift API for cluster operations" "External"
        openshiftProm = softwareSystem "OpenShift Prometheus" "Cluster-level Prometheus for metrics federation" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OAuth provider for proxy sidecar authentication" "External"
        openshiftCertSigner = softwareSystem "OpenShift Serving Cert Signer" "Auto-provisions TLS certificates via annotations" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with application launcher" "External"

        pagerduty = softwareSystem "PagerDuty" "Critical alert notification service for SRE" "External SaaS"
        deadmanssnitch = softwareSystem "Dead Man's Snitch" "Alerting pipeline liveness heartbeat" "External SaaS"
        smtpRelay = softwareSystem "SMTP Relay" "Email relay for user-facing notifications" "External SaaS"

        # Relationships
        admin -> odhDeployer "Triggers platform bootstrap via operator installation"
        sre -> prometheusStack "Monitors via Prometheus/Alertmanager Routes"

        deployScript -> openshiftAPI "Creates namespaces, KfDef CRs, manifests, RBAC" "HTTPS/443, SA Bearer Token"
        deployScript -> kfdefManifests "Applies KfDef CRs to cluster"
        deployScript -> prometheusStack "Deploys monitoring stack manifests"
        deployScript -> networkPolicies "Applies namespace network policies"
        deployScript -> dashboardResources "Installs CRDs, ISV tiles, ConsoleLink"

        kfdefManifests -> rhodsOperator "KfDef CRs reconciled by operator" "Kubernetes API"
        rhodsOperator -> odhDashboard "Installs dashboard via KfDef"
        rhodsOperator -> notebookController "Installs notebook controller via KfDef"
        rhodsOperator -> modelMesh "Installs ModelMesh via KfDef"
        rhodsOperator -> dspo "Installs DSPO via KfDef"
        rhodsOperator -> rhodsNotebooks "Installs notebook images via KfDef"
        rhodsOperator -> anaconda "Installs Anaconda CE via KfDef"

        prometheusStack -> openshiftProm "Federates cluster metrics" "HTTPS/9091, Bearer Token"
        prometheusStack -> notebookController "Scrapes metrics" "HTTP/8080"
        prometheusStack -> modelMesh "Scrapes metrics" "HTTP/8080"
        prometheusStack -> dspo "Scrapes metrics" "HTTP/8080"
        prometheusStack -> rhodsOperator "Scrapes metrics" "HTTP/8383"
        prometheusStack -> odhDashboard "Health check probes" "HTTPS/8443"
        prometheusStack -> pagerduty "Critical SRE alerts" "HTTPS/443, Service Key"
        prometheusStack -> deadmanssnitch "Liveness heartbeat" "HTTPS/443, URL token"
        prometheusStack -> smtpRelay "User notification emails" "SMTP/TLS, Credentials"
        prometheusStack -> openshiftOAuth "OAuth proxy authentication" "HTTPS"

        dashboardResources -> openshiftConsole "Adds ConsoleLink to app launcher"
        openshiftCertSigner -> prometheusStack "Auto-provisions TLS certificates"
    }

    views {
        systemContext odhDeployer "SystemContext" {
            include *
            autoLayout
        }

        container odhDeployer "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External SaaS" {
                background #f8cecc
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #333333
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #333333
            }
        }
    }
}

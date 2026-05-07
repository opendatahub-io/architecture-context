workspace {
    model {
        clusterAdmin = person "Cluster Administrator" "Installs and manages the RHODS/RHOAI platform on OpenShift"
        sreTeam = person "SRE Team" "Monitors platform health via PagerDuty and alerting (managed service)"

        odhDeployer = softwareSystem "odh-deployer" "Containerized Bash deployer that bootstraps RHODS platform components by creating namespaces, KfDef CRs, monitoring stack, network policies, and dashboard configuration" {
            deployScript = container "deploy.sh" "Main deployment orchestrator script" "Bash Script"
            kfdefManifests = container "KfDef Manifests" "KfDef CRs for dashboard, notebooks, model mesh, DSPO, monitoring" "YAML"
            prometheusStack = container "Prometheus Stack" "Prometheus + Alertmanager + Blackbox Exporter with SLO burn rate alerts" "Prometheus/Alertmanager"
            networkPolicies = container "Network Policies" "Namespace-scoped ingress policies for applications, monitoring, operator namespaces" "Kubernetes NetworkPolicy"
            dashboardConfig = container "Dashboard Configuration" "CRDs (OdhApplication, OdhDocument, OdhQuickStart, OdhDashboardConfig), ISV tiles, ServingRuntime templates" "Kustomize"
        }

        odhOperator = softwareSystem "ODH Operator (KfDef Controller)" "Watches KfDef CRs and installs platform components from odh-manifests" "Internal ODH"
        rhodsDashboard = softwareSystem "RHODS Dashboard" "Web UI for managing data science projects, notebooks, and model serving" "Internal ODH"
        notebookController = softwareSystem "ODH Notebook Controller" "Manages Jupyter notebook lifecycle" "Internal ODH"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving infrastructure" "Internal ODH"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages data science pipeline workflows" "Internal ODH"
        modelController = softwareSystem "ODH Model Controller" "Manages model serving resources" "Internal ODH"

        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes/OpenShift control plane" "External"
        clusterPrometheus = softwareSystem "OpenShift Cluster Prometheus" "Platform-level metrics collection in openshift-monitoring" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with Application Launcher" "External"

        pagerduty = softwareSystem "PagerDuty" "Incident alerting for critical SLO violations" "External"
        dms = softwareSystem "Dead Man's Snitch" "Monitoring pipeline liveness verification" "External"
        smtpServer = softwareSystem "SMTP Server" "Email notification delivery" "External"
        osdAddon = softwareSystem "OSD Addon Framework" "Manages addon parameters and catalog for managed service" "External"

        # Relationships
        clusterAdmin -> odhDeployer "Triggers deployment via operator"
        sreTeam -> pagerduty "Receives critical alerts"

        deployScript -> openshiftAPI "Creates namespaces, applies CRs and configs" "oc apply / HTTPS 443"
        deployScript -> kfdefManifests "Reads and applies"
        deployScript -> prometheusStack "Deploys and configures"
        deployScript -> networkPolicies "Applies to namespaces"
        deployScript -> dashboardConfig "Applies CRDs, ISV tiles, configs"

        kfdefManifests -> odhOperator "KfDef CRs watched by operator" "Kubernetes API / TLS 1.2+"
        odhOperator -> rhodsDashboard "Installs via KfDef"
        odhOperator -> notebookController "Installs via KfDef"
        odhOperator -> modelMesh "Installs via KfDef"
        odhOperator -> dspo "Installs via KfDef"

        prometheusStack -> clusterPrometheus "Federates metrics" "HTTPS/9091 TLS"
        prometheusStack -> rhodsDashboard "Probes availability" "HTTPS/8443"
        prometheusStack -> notebookController "Scrapes metrics" "HTTP/8080"
        prometheusStack -> modelController "Scrapes metrics" "HTTP/8080"
        prometheusStack -> modelMesh "Scrapes metrics" "HTTP/8080"
        prometheusStack -> dspo "Scrapes metrics" "HTTP/8080"
        prometheusStack -> pagerduty "Sends critical alerts" "HTTPS/443"
        prometheusStack -> dms "Sends watchdog heartbeat" "HTTPS/443"
        prometheusStack -> smtpServer "Sends email notifications" "SMTP/STARTTLS"

        dashboardConfig -> rhodsDashboard "Configures UI features and ISV tiles" "Kubernetes API"
        deployScript -> openshiftConsole "Creates ConsoleLink CR" "Kubernetes API"
        deployScript -> osdAddon "Reads addon parameters secret" "Kubernetes API"
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
            element "Internal ODH" {
                background #7ed321
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

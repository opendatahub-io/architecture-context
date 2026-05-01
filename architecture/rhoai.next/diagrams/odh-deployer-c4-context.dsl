workspace {
    model {
        admin = person "Cluster Admin" "Installs and manages RHODS platform on OpenShift"
        dataScientist = person "Data Scientist" "Uses RHODS dashboard, notebooks, model serving"
        sre = person "SRE Engineer" "Monitors platform health, responds to alerts (managed service)"

        odhDeployer = softwareSystem "odh-deployer" "Init container that bootstraps the RHODS platform by creating KfDef CRs, CRDs, monitoring stack, network policies, and dashboard configuration" {
            deployScript = container "deploy.sh" "Main entrypoint that orchestrates entire RHODS setup via oc CLI commands" "Shell Script (Bash)"
            kfdefManifests = container "KfDef Manifests" "8 KfDef custom resource definitions for individual RHODS components" "YAML"
            monitoringManifests = container "Monitoring Manifests" "Prometheus, Alertmanager, Blackbox Exporter deployment manifests with SLO rules" "YAML"
            dashboardConfig = container "Dashboard Config" "CRDs, ISV tiles, OdhDashboardConfig, serving runtime templates" "YAML + Kustomize"
            networkManifests = container "Network Manifests" "NetworkPolicies for applications, monitoring, and operator namespaces" "YAML"
        }

        rhodsOperator = softwareSystem "rhods-operator" "OpenDataHub operator that watches KfDef CRs and deploys RHODS component workloads from bundled manifests" "Internal RHOAI"
        rhodsDashboard = softwareSystem "RHODS Dashboard" "Web UI for data science workflows, notebook management, and model serving" "Internal RHOAI"
        notebookController = softwareSystem "ODH Notebook Controller" "Manages Jupyter notebook pod lifecycle" "Internal RHOAI"
        modelController = softwareSystem "ODH Model Controller" "Manages model serving infrastructure" "Internal RHOAI"
        modelmeshController = softwareSystem "ModelMesh Controller" "Multi-model serving controller for inference services" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages data science pipeline workflows" "Internal RHOAI"

        prometheus = softwareSystem "RHODS Prometheus" "Dedicated Prometheus instance for RHODS SLO monitoring with oauth-proxy" "Monitoring"
        alertmanager = softwareSystem "RHODS Alertmanager" "Alert routing for SLO violations with oauth-proxy" "Monitoring"
        blackboxExporter = softwareSystem "Blackbox Exporter" "HTTP probe for dashboard availability SLO" "Monitoring"

        clusterPrometheus = softwareSystem "Cluster Prometheus" "OpenShift built-in monitoring in openshift-monitoring namespace" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API server for cluster operations" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "OpenShift web console with Application Launcher" "External"

        pagerduty = softwareSystem "PagerDuty" "Incident management for critical alerts (managed service only)" "External"
        deadMansSnitch = softwareSystem "Dead Man's Snitch" "Monitoring liveness heartbeat service (managed service only)" "External"
        smtpServer = softwareSystem "SMTP Server" "Email delivery for user-facing notifications (managed service only)" "External"
        osdAddonFramework = softwareSystem "OSD Addon Framework" "Provisions addon secrets and parameters on OpenShift Dedicated" "External"

        # Deployer relationships
        admin -> odhDeployer "Triggers via operator installation"
        odhDeployer -> openshiftAPI "Creates namespaces, CRDs, KfDef CRs, NetworkPolicies, RBAC" "HTTPS/443, SA token"
        odhDeployer -> rhodsOperator "Creates KfDef CRs that trigger component deployment" "Kubernetes API"
        odhDeployer -> openshiftConsole "Creates ConsoleLink CR for dashboard access" "Kubernetes API"

        # Operator relationships
        rhodsOperator -> rhodsDashboard "Deploys from KfDef manifests" "Kubernetes API"
        rhodsOperator -> notebookController "Deploys from KfDef manifests" "Kubernetes API"
        rhodsOperator -> modelController "Deploys from KfDef manifests" "Kubernetes API"
        rhodsOperator -> modelmeshController "Deploys from KfDef manifests" "Kubernetes API"
        rhodsOperator -> dspo "Deploys from KfDef manifests" "Kubernetes API"

        # Monitoring relationships
        prometheus -> clusterPrometheus "Federated metrics scraping" "HTTPS/9091, Bearer token"
        prometheus -> notebookController "Scrape metrics" "HTTP/8080"
        prometheus -> modelController "Scrape metrics" "HTTP/8080"
        prometheus -> modelmeshController "Scrape metrics" "HTTP/8080"
        prometheus -> dspo "Scrape metrics" "HTTP/8080"
        prometheus -> rhodsOperator "Scrape metrics" "HTTP/8383"
        prometheus -> blackboxExporter "Probe requests" "HTTP/9115"
        blackboxExporter -> rhodsDashboard "HTTP availability probe" "HTTPS/8443"
        prometheus -> alertmanager "Fire SLO alerts"
        alertmanager -> pagerduty "Critical alerts" "HTTPS/443, Service key"
        alertmanager -> deadMansSnitch "Heartbeat" "HTTPS/443"
        alertmanager -> smtpServer "User notification emails" "SMTP/TLS"

        # User relationships
        dataScientist -> rhodsDashboard "Uses for ML workflows" "HTTPS/8443"
        sre -> prometheus "Monitors SLOs" "HTTPS/9091, OAuth"
        sre -> alertmanager "Manages alerts" "HTTPS/443, OAuth"

        # Addon framework
        osdAddonFramework -> odhDeployer "Provisions secrets (PagerDuty, SMTP, DMS)" "Kubernetes Secrets"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Monitoring" {
                background #e6522c
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
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

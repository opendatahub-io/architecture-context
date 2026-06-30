workspace {
    model {
        sre = person "SRE / Platform Admin" "Manages RHODS platform deployment and monitoring"
        dataScientist = person "Data Scientist" "Consumes RHODS platform services"

        odhDeployer = softwareSystem "odh-deployer" "Bootstrap container that deploys RHODS platform components by creating KfDef CRs and configuring monitoring, networking, and dashboard resources" {
            deployScript = container "deploy.sh" "Main entry point - creates namespaces, applies CRDs, deploys KfDef CRs, configures monitoring stack" "Bash Script"
            kfdefManifests = container "KfDef Manifests" "KfDef custom resources that trigger opendatahub operator to deploy platform components" "YAML Manifests"
            monitoringManifests = container "Monitoring Stack" "Prometheus, Alertmanager, Blackbox Exporter deployment manifests and configuration" "YAML Manifests"
            dashboardConfig = container "Dashboard Config" "CRDs, ISV application tiles, dashboard config, serving runtime templates" "YAML Manifests"
            networkManifests = container "Network & RBAC" "NetworkPolicies and SCC RoleBindings" "YAML Manifests"
        }

        odhOperator = softwareSystem "opendatahub operator" "Watches KfDef CRs and deploys platform components from odh-manifests" "Internal RHOAI"
        rhodsDashboard = softwareSystem "RHODS Dashboard" "Web UI for managing data science projects, notebooks, and model serving" "Internal RHOAI"
        notebookController = softwareSystem "ODH Notebook Controller" "Manages Jupyter notebook lifecycle on OpenShift" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh Controller" "Multi-model serving controller for model inference" "Internal RHOAI"
        modelController = softwareSystem "ODH Model Controller" "Manages model serving resources" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages ML pipeline deployments" "Internal RHOAI"

        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes/OpenShift API for resource management" "External"
        clusterPrometheus = softwareSystem "OpenShift Prometheus" "Cluster-level monitoring and metrics" "External"
        pagerduty = softwareSystem "PagerDuty" "Critical alert notification service" "External"
        deadMansSnitch = softwareSystem "Dead Man's Snitch" "Heartbeat/watchdog monitoring service" "External"
        smtpServer = softwareSystem "SMTP Server" "Email notification delivery" "External"

        sre -> odhDeployer "Triggers deployment via operator"
        dataScientist -> rhodsDashboard "Accesses RHODS dashboard"

        deployScript -> openshiftAPI "Creates namespaces, applies CRDs, KfDef CRs, monitoring" "HTTPS/443 - SA Token"
        deployScript -> kfdefManifests "Reads and applies"
        deployScript -> monitoringManifests "Reads and applies"
        deployScript -> dashboardConfig "Reads and applies"
        deployScript -> networkManifests "Reads and applies"

        kfdefManifests -> odhOperator "KfDef CRs trigger component deployment"
        odhOperator -> rhodsDashboard "Deploys"
        odhOperator -> notebookController "Deploys"
        odhOperator -> modelMesh "Deploys"
        odhOperator -> modelController "Deploys"
        odhOperator -> dspo "Deploys"

        monitoringManifests -> clusterPrometheus "Federates metrics" "HTTPS/9091 - Bearer Token"
        monitoringManifests -> rhodsDashboard "Probes endpoint" "HTTPS/8443"
        monitoringManifests -> notebookController "Scrapes metrics" "HTTP/8080"
        monitoringManifests -> modelMesh "Scrapes metrics" "HTTP/8080"
        monitoringManifests -> modelController "Scrapes metrics" "HTTP/8080"
        monitoringManifests -> dspo "Scrapes metrics" "HTTP/8080"
        monitoringManifests -> pagerduty "Sends critical alerts" "HTTPS/443 - Service Key"
        monitoringManifests -> deadMansSnitch "Sends heartbeat" "HTTPS/443 - URL Token"
        monitoringManifests -> smtpServer "Sends email alerts" "SMTP - STARTTLS"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

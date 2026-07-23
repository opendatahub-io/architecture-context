workspace {
    model {
        sreEngineer = person "SRE Engineer" "Monitors RHODS platform health via Prometheus/Alertmanager dashboards"
        dataScientist = person "Data Scientist" "Uses RHODS platform components (Dashboard, Notebooks, Model Serving)"

        odhDeployer = softwareSystem "odh-deployer" "Init container that bootstraps RHODS platform components by creating KfDef CRs, CRDs, monitoring stack, network policies, and dashboard configurations" {
            deployScript = container "deploy.sh" "Main deployment orchestrator creating namespaces, CRDs, KfDef CRs, monitoring, and network policies" "Bash Script"
            containerImage = container "Container Image" "UBI8-minimal image packaging deploy.sh with embedded oc CLI and openssl" "Docker/UBI8-minimal"
            kfdefManifests = container "KfDef Manifests" "KfDef custom resources referencing odh-manifests.tar.gz for operator-managed component installation" "Kubernetes CRs"
            monitoringStack = container "Monitoring Stack" "Prometheus, Alertmanager, Blackbox Exporter with oauth-proxy sidecars and TLS serving certs" "Prometheus/Alertmanager"
            dashboardCRDs = container "Dashboard CRDs" "OdhApplication, OdhDocument, OdhQuickStart, OdhDashboardConfig CRDs and ISV application tiles" "Kubernetes CRDs"
            networkPolicies = container "Network Policies" "Ingress policies for operator, applications, and monitoring namespaces" "NetworkPolicy"
        }

        rhodsOperator = softwareSystem "rhods-operator" "Watches KfDef CRs and reconciles component installations" "Internal RHOAI"
        odhDashboard = softwareSystem "odh-dashboard" "RHODS Dashboard providing UI for data science workflows" "Internal RHOAI"
        notebookController = softwareSystem "odh-notebook-controller" "Manages Jupyter notebook lifecycle" "Internal RHOAI"
        modelController = softwareSystem "odh-model-controller" "Manages model serving lifecycle" "Internal RHOAI"
        modelmeshController = softwareSystem "modelmesh-controller" "Multi-model serving platform controller" "Internal RHOAI"
        dspOperator = softwareSystem "data-science-pipelines-operator" "Manages data science pipeline deployments" "Internal RHOAI"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes/OpenShift control plane API" "External"
        clusterPrometheus = softwareSystem "Cluster Prometheus" "OpenShift built-in cluster monitoring Prometheus" "External"
        pagerduty = softwareSystem "PagerDuty" "Incident management platform for SRE alerting" "External"
        deadMansSnitch = softwareSystem "Dead Man's Snitch" "Heartbeat monitoring service" "External"
        smtpServer = softwareSystem "SMTP Server" "Email delivery for user notifications" "External"

        deployScript -> openshiftAPI "Creates namespaces, CRDs, KfDef CRs, Secrets, ConfigMaps" "HTTPS/6443, SA Token"
        deployScript -> kfdefManifests "Creates KfDef custom resources"
        deployScript -> monitoringStack "Deploys Prometheus, Alertmanager, Blackbox Exporter"
        deployScript -> dashboardCRDs "Applies CRDs and ISV tiles"
        deployScript -> networkPolicies "Applies NetworkPolicies per namespace"

        rhodsOperator -> kfdefManifests "Watches KfDef CRs, reconciles component installations"

        monitoringStack -> notebookController "Scrapes /metrics" "HTTP/8080"
        monitoringStack -> modelController "Scrapes /metrics" "HTTP/8080"
        monitoringStack -> modelmeshController "Scrapes /metrics" "HTTP/8080"
        monitoringStack -> dspOperator "Scrapes /metrics" "HTTP/8080"
        monitoringStack -> rhodsOperator "Scrapes operator metrics" "HTTP/8383"
        monitoringStack -> clusterPrometheus "Federates metrics" "HTTPS/9091, Bearer Token"
        monitoringStack -> odhDashboard "Health probes" "HTTPS/8443"
        monitoringStack -> pagerduty "Critical alert escalation" "HTTPS/443, Service Key"
        monitoringStack -> deadMansSnitch "Watchdog heartbeat" "HTTPS/443, URL Secret"
        monitoringStack -> smtpServer "User email notifications" "SMTP/STARTTLS"

        sreEngineer -> monitoringStack "Views dashboards, manages alerts" "HTTPS via OpenShift Route"
        dataScientist -> odhDashboard "Uses RHODS platform" "HTTPS via OpenShift Route"
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
                color #000000
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

workspace {
    model {
        sre = person "SRE / Platform Admin" "Manages RHODS installation and monitors platform health"
        datascientist = person "Data Scientist" "Uses RHODS platform for ML workflows"

        odhDeployer = softwareSystem "odh-deployer" "Init container that bootstraps RHODS platform components by creating KfDef CRs, CRDs, monitoring stack, network policies, and dashboard configurations" {
            deployScript = container "deploy.sh" "Main deployment orchestrator - creates namespaces, applies CRDs, creates KfDef CRs, configures monitoring" "Bash Script"
            containerImage = container "Container Image" "UBI8-minimal based image with deploy.sh, oc CLI, openssl, KfDef manifests, monitoring configs" "Docker"
            kfdefManifests = container "KfDef Manifests" "KfDef CRs referencing odh-manifests.tar.gz for component installation" "YAML"
            monitoringStack = container "Monitoring Stack" "Prometheus, Alertmanager, Blackbox Exporter with oauth-proxy sidecars" "Prometheus"
            dashboardCRDs = container "Dashboard CRDs" "OdhApplication, OdhDocument, OdhQuickStart, OdhDashboardConfig" "CRDs"
            networkPolicies = container "Network Policies" "Ingress policies for operator, applications, and monitoring namespaces" "NetworkPolicy"
        }

        rhodsOperator = softwareSystem "rhods-operator" "Watches KfDef CRs and reconciles component installations" "Internal RHODS"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for RHODS platform" "Internal RHODS"
        notebookController = softwareSystem "ODH Notebook Controller" "Manages notebook pod lifecycle" "Internal RHODS"
        modelController = softwareSystem "ODH Model Controller" "Manages model serving resources" "Internal RHODS"
        modelmesh = softwareSystem "ModelMesh" "Multi-model serving platform" "Internal RHODS"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages ML pipeline infrastructure" "Internal RHODS"

        openshift = softwareSystem "OpenShift Cluster" "Target Kubernetes/OpenShift cluster" "External"
        clusterPrometheus = softwareSystem "Cluster Prometheus" "OpenShift built-in monitoring stack" "External"
        pagerduty = softwareSystem "PagerDuty" "Incident alerting for critical alerts (managed service)" "External"
        deadmanssnitch = softwareSystem "Dead Man's Snitch" "Heartbeat monitoring for alerting liveness" "External"
        smtpServer = softwareSystem "SMTP Server" "Email notifications for user-facing alerts" "External"

        sre -> odhDeployer "Triggers deployment via operator installation"
        datascientist -> odhDashboard "Uses RHODS platform features"

        deployScript -> openshift "Creates namespaces, CRDs, KfDef CRs, monitoring stack via oc CLI" "HTTPS/6443"
        deployScript -> kfdefManifests "Applies KfDef CRs"
        deployScript -> monitoringStack "Deploys Prometheus, Alertmanager, Blackbox Exporter"
        deployScript -> dashboardCRDs "Applies Dashboard CRDs and ISV tiles"
        deployScript -> networkPolicies "Applies network ingress policies"

        rhodsOperator -> kfdefManifests "Watches KfDef CRs and reconciles" "KfDef Watch"
        monitoringStack -> notebookController "Scrapes metrics" "HTTP/8080"
        monitoringStack -> modelController "Scrapes metrics" "HTTP/8080"
        monitoringStack -> modelmesh "Scrapes metrics" "HTTP/8080"
        monitoringStack -> dspo "Scrapes metrics" "HTTP/8080"
        monitoringStack -> clusterPrometheus "Federates metrics" "HTTPS/9091"
        monitoringStack -> pagerduty "Sends critical alerts" "HTTPS/443"
        monitoringStack -> deadmanssnitch "Sends heartbeat" "HTTPS/443"
        monitoringStack -> smtpServer "Sends email notifications" "SMTP/STARTTLS"
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
            element "Internal RHODS" {
                background #7ed321
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

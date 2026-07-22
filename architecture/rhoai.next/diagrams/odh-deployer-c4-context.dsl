workspace {
    model {
        sreAdmin = person "SRE / Cluster Admin" "Manages and monitors the RHODS platform"
        dataScientist = person "Data Scientist" "Uses RHODS platform for ML workloads"

        odhDeployer = softwareSystem "odh-deployer" "Deployment container that bootstraps RHODS platform components via KfDef CRs, monitoring, and network policies" {
            deployScript = container "deploy.sh" "Main deployment orchestrator - creates namespaces, applies KfDef CRs, configures monitoring" "Bash Script (Init Container)"
            kfdefManifests = container "KfDef Manifests" "KfDef custom resources that trigger component installation" "YAML CRs"
            prometheus = container "Prometheus" "Metrics collection with federation and SLO alerting" "Prometheus 9091/TCP"
            alertmanager = container "Alertmanager" "Alert routing to PagerDuty, SMTP, Dead Man's Snitch" "Alertmanager 443/TCP"
            blackboxExporter = container "Blackbox Exporter" "HTTP probe checks for endpoint SLO monitoring" "Blackbox Exporter 9114/TCP"
            networkPolicies = container "Network Policies" "Namespace-level ingress restrictions" "Kubernetes NetworkPolicy"
            dashboardISVs = container "Dashboard ISV Tiles" "OdhApplication, OdhDocument, OdhQuickStart resources" "Dashboard CRDs"
        }

        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes/OpenShift control plane" "External"
        odhOperator = softwareSystem "opendatahub Operator" "Watches KfDef CRs and deploys platform components" "Internal RHOAI"
        rhodsDashboard = softwareSystem "RHODS Dashboard" "Web UI for data science workflows" "Internal RHOAI"
        notebookController = softwareSystem "ODH Notebook Controller" "Manages notebook pod lifecycle" "Internal RHOAI"
        modelController = softwareSystem "ODH Model Controller" "Manages model serving resources" "Internal RHOAI"
        modelmeshController = softwareSystem "ModelMesh Controller" "Multi-model serving orchestration" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "Pipeline workflow orchestration" "Internal RHOAI"
        rhodsOperator = softwareSystem "RHODS Operator" "Platform lifecycle operator" "Internal RHOAI"
        clusterPrometheus = softwareSystem "Cluster Prometheus" "OpenShift built-in monitoring stack" "External"
        pagerduty = softwareSystem "PagerDuty" "Incident management and alert escalation" "External SaaS"
        deadMansSnitch = softwareSystem "Dead Man's Snitch" "Monitoring liveness heartbeat service" "External SaaS"
        smtpServer = softwareSystem "SMTP Server" "Email delivery for alert notifications" "External"

        # Deployment-time flows
        deployScript -> openshiftAPI "Creates namespaces, applies KfDef CRs, monitoring manifests, network policies" "HTTPS/6443 TLS 1.2+ SA token"
        deployScript -> kfdefManifests "Applies KfDef custom resources"
        odhOperator -> openshiftAPI "Watches KfDef CRs, deploys components" "HTTPS/6443 TLS 1.2+"

        # Monitoring flows
        prometheus -> clusterPrometheus "Federates HAProxy, controller_runtime, kubelet metrics" "HTTPS/9091 TLS service-ca Bearer token"
        prometheus -> notebookController "Scrapes /metrics" "HTTP/8080 Plaintext"
        prometheus -> modelController "Scrapes /metrics" "HTTP/8080 Plaintext"
        prometheus -> modelmeshController "Scrapes /metrics" "HTTP/8080 Plaintext"
        prometheus -> dspo "Scrapes /metrics" "HTTP/8080 Plaintext"
        prometheus -> rhodsOperator "Scrapes operator metrics" "HTTP/8383 Plaintext"
        prometheus -> blackboxExporter "Scrapes probe results" "HTTP/9115"
        blackboxExporter -> rhodsDashboard "HTTP probes for SLO" "HTTPS/8443 Bearer token"
        prometheus -> alertmanager "Fires alerts"

        # Alert routing
        alertmanager -> pagerduty "Critical alert escalation (managed only)" "HTTPS/443 TLS 1.2+ Service key"
        alertmanager -> deadMansSnitch "Watchdog heartbeat (managed only)" "HTTPS/443 TLS 1.2+ Webhook URL"
        alertmanager -> smtpServer "Email notifications" "SMTP STARTTLS User/pass"

        # User access
        sreAdmin -> prometheus "Views metrics and dashboards" "HTTPS/9091 OAuth proxy"
        sreAdmin -> alertmanager "Manages alerts" "HTTPS/443 OAuth proxy"
        dataScientist -> rhodsDashboard "Accesses platform via dashboard" "HTTPS/8443"
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
                background #e8944a
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

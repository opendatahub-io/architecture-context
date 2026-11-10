workspace "workbenches-operator" "C4 context for the RHOAI 3.7-ea.1 Workbenches module operator" {
    model {
        user = person "Data Scientist" "Creates and updates workbenches (Notebook CRs) via ODH Dashboard or kubectl"

        orchestrator = softwareSystem "Platform Orchestrator" "rhods-operator / opendatahub-operator: renders the Helm chart and creates/projects the default-workbenches CR" "Internal ODH"

        wbo = softwareSystem "workbenches-operator" "Module operator that reconciles the singleton Workbenches CR, deploys the notebook controller stack, and serves Notebook mutating webhooks" {
            manager = container "manager" "Single binary hosting reconciler, webhook server, TLS ensurer, metrics, probes" "Go 1.26 / controller-runtime v0.23.3"
            reconciler = container "WorkbenchesReconciler" "Renders bundled Kustomize manifests (krusty) and applies them via Server-Side Apply; manages status, finalizer, cleanup" "Go Controller"
            connWebhook = container "NotebookWebhook" "Injects connection Secrets as envFrom after per-user SubjectAccessReview" "Mutating webhook, HTTPS 9443"
            hwpWebhook = container "HardwareProfile Injector" "Applies HardwareProfile resources, nodeSelector, tolerations, Kueue label, DRA resourceClaims" "Mutating webhook, HTTPS 9443"
            tlsEnsurer = container "Webhook TLS Ensurer" "Detects service-CA / cert-manager and maintains webhook serving certs every 30s" "Go runnable"
            manifests = container "Bundled Operand Manifests" "/opt/manifests/workbenches: kf-notebook-controller, odh-notebook-controller, notebooks, workspaces-controller, workspacekinds" "Kustomize trees"
        }

        kubeApi = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        notebookControllers = softwareSystem "Notebook Controllers" "Kubeflow + ODH notebook-controllers (deployed operands)" "Internal ODH"
        workspacesController = softwareSystem "Workbenches v2 workspaces-controller" "Optional operand when workbenchesV2 is Managed" "Internal ODH"
        hardwareProfiles = softwareSystem "HardwareProfile API" "infrastructure.opendatahub.io hardware settings" "Internal ODH"
        kueue = softwareSystem "Kueue" "Job queueing; consumes kueue.x-k8s.io/queue-name label" "External"
        serviceCa = softwareSystem "OpenShift service-CA" "Issues webhook serving cert and injects CA bundle" "External"
        certManager = softwareSystem "cert-manager" "Fallback webhook certificate provider" "External"
        prometheus = softwareSystem "Prometheus" "Cluster / user-workload monitoring" "External"

        user -> kubeApi "Creates/updates Notebook" "HTTPS/6443, Bearer token"
        orchestrator -> kubeApi "Creates default-workbenches CR, projects platform fields" "HTTPS/6443"
        kubeApi -> connWebhook "AdmissionReview /workbenches-connection-notebook" "HTTPS 443->9443, TLS"
        kubeApi -> hwpWebhook "AdmissionReview /workbenches-hardware-profile" "HTTPS 443->9443, TLS"
        reconciler -> manifests "Reads and renders"
        reconciler -> kubeApi "Watches + Server-Side Apply operands, status updates" "HTTPS/6443, SA token"
        connWebhook -> kubeApi "Get Secrets, create SubjectAccessReview" "HTTPS/6443, SA token"
        hwpWebhook -> kubeApi "Get HardwareProfile / ResourceClaimTemplate, create Event" "HTTPS/6443, SA token"
        tlsEnsurer -> serviceCa "Annotates webhook Service and MWC"
        tlsEnsurer -> certManager "Creates ClusterIssuer + Certificate (fallback)" "HTTPS/6443"
        manager -> reconciler "Hosts"
        manager -> connWebhook "Hosts"
        manager -> hwpWebhook "Hosts"
        manager -> tlsEnsurer "Hosts"
        wbo -> notebookControllers "Deploys via SSA"
        wbo -> workspacesController "Deploys via SSA (optional)"
        hwpWebhook -> hardwareProfiles "Reads profile"
        hwpWebhook -> kueue "Sets queue-name label on Notebook"
        prometheus -> manager "Scrapes /metrics" "HTTPS/8443, Bearer token"
    }

    views {
        systemContext wbo "SystemContext" {
            include *
            autoLayout
        }

        container wbo "Containers" {
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
                background #6fa8dc
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal ODH" {
                background #7ed321
            }
        }
    }
}

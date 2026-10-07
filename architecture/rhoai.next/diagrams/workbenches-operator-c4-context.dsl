workspace {
    model {
        dataScientist = person "Data Scientist" "Creates Notebooks and workbenches for ML experiments"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and Workbenches CR"

        workbenchesOperator = softwareSystem "Workbenches Operator" "Reconciles the Workbenches CR to deploy and manage the notebook controller stack on OpenShift" {
            reconciler = container "WorkbenchesReconciler" "Watches Workbenches CR, renders manifests via Krusty, applies via SSA" "Go controller-runtime"
            krustyEngine = container "Krusty Manifest Renderer" "Renders Kustomize manifests with platform overlays and image substitution" "sigs.k8s.io/kustomize"
            hwProfileWebhook = container "Hardware Profile Webhook" "Injects HardwareProfile settings (resources, nodeSelector, tolerations, Kueue) into Notebooks" "Mutating Admission Webhook :9443"
            connectionWebhook = container "Connection Notebook Webhook" "Injects connection secrets into Notebooks based on opendatahub.io/connections annotation" "Mutating Admission Webhook :9443"
            conversionWebhook = container "Conversion Webhook" "CRD conversion for multi-version Notebook/WorkspaceKind support" "Conversion Webhook :9443"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint secured by TokenReview + SubjectAccessReview" "HTTPS :8443"
            bakedManifests = container "Baked Manifests" "Committed upstream operand manifests for hermetic builds" "/opt/manifests"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook CRD and lifecycle management" "Internal ODH"
        hardwareProfiles = softwareSystem "HardwareProfile CRDs" "Resource and scheduling profiles for workbenches" "Internal ODH"
        certManager = softwareSystem "cert-manager" "TLS certificate management (auto-detected)" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Cluster TLS security profile configuration" "External"
        kueue = softwareSystem "Kueue" "Job scheduling and queue management" "External"
        openshiftImageStreams = softwareSystem "OpenShift Image Streams" "Container image management for notebook images" "External"
        platformConfigMap = softwareSystem "Platform ConfigMap" "odh-workbenches-config for platform version context" "Internal ODH"

        platformAdmin -> workbenchesOperator "Creates/updates Workbenches CR via kubectl" "HTTPS/6443"
        dataScientist -> kubeflowNotebooks "Creates Notebook CRs" "HTTPS/6443"

        reconciler -> krustyEngine "Requests manifest rendering" "In-process"
        krustyEngine -> bakedManifests "Reads baked manifests" "Filesystem"
        reconciler -> kubernetesAPI "CRUD + SSA + watches" "HTTPS/6443 TLS 1.2+"
        hwProfileWebhook -> kubernetesAPI "Reads HardwareProfile CRs, creates Events" "HTTPS/6443 TLS 1.2+"
        connectionWebhook -> kubernetesAPI "Reads Secrets, SubjectAccessReview" "HTTPS/6443 TLS 1.2+"

        kubernetesAPI -> hwProfileWebhook "Admission webhook call" "HTTPS/443→9443 TLS"
        kubernetesAPI -> connectionWebhook "Admission webhook call" "HTTPS/443→9443 TLS"
        kubernetesAPI -> conversionWebhook "CRD conversion call" "HTTPS/443→9443 TLS"

        workbenchesOperator -> kubeflowNotebooks "Creates and manages Notebook CRs" "HTTPS/6443"
        workbenchesOperator -> hardwareProfiles "Reads HardwareProfile CRs" "HTTPS/6443"
        workbenchesOperator -> certManager "Creates ClusterIssuer + Certificate when detected" "HTTPS/6443"
        workbenchesOperator -> prometheusOperator "Creates ServiceMonitor for metrics" "HTTPS/6443"
        workbenchesOperator -> openshiftAPIServer "Reads TLS security profile" "HTTPS/6443"
        workbenchesOperator -> openshiftImageStreams "Manages ImageStream resources" "HTTPS/6443"
        workbenchesOperator -> platformConfigMap "Watches odh-workbenches-config" "HTTPS/6443"
        hwProfileWebhook -> kueue "Injects Kueue queue label on Notebooks" "Label injection"

        prometheusOperator -> metricsServer "Scrapes metrics" "HTTPS/8443 TLS 1.2+"
    }

    views {
        systemContext workbenchesOperator "SystemContext" {
            include *
            autoLayout
        }

        container workbenchesOperator "Containers" {
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

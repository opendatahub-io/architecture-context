workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages Jupyter/VS Code workbenches for ML experimentation"
        clusteradmin = person "Cluster Admin" "Configures platform and HardwareProfiles"

        workbenchesOperator = softwareSystem "Workbenches Operator" "Manages lifecycle of notebook workbench stack via kustomize SSA" {
            controller = container "Workbenches Controller" "Reconciles Workbenches CR, renders kustomize manifests, applies via SSA" "Go (controller-runtime)"
            manifestRenderer = container "Manifest Renderer" "In-process kustomize rendering with parameter injection" "kustomize API"
            connectionWebhook = container "Connection Webhook" "Injects connection secrets into Notebook pods" "Mutating Admission Webhook"
            hardwareProfileWebhook = container "HardwareProfile Webhook" "Applies resource requirements, nodeSelectors, tolerations to Notebooks" "Mutating Admission Webhook"
            tlsBootstrap = container "TLS Config" "Aligns operator TLS with OpenShift cluster profile" "SecurityProfileWatcher"
        }

        orchestrator = softwareSystem "RHODS Operator / ODH Operator" "Platform orchestrator that creates and manages component CRs" "Internal RHOAI"
        kfNotebookController = softwareSystem "KF Notebook Controller" "Upstream Kubeflow controller managing Notebook StatefulSets" "Deployed by Operator"
        odhNotebookController = softwareSystem "ODH Notebook Controller" "Creates HTTPRoutes, NetworkPolicies, kube-rbac-proxy sidecars per Notebook" "Deployed by Operator"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for all resource operations" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Cluster TLS security profile configuration" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection" "External"

        # Relationships
        clusteradmin -> orchestrator "Configures platform via DSCInitialization/DataScienceCluster"
        datascientist -> k8sAPI "Creates Notebook CRs via kubectl/Dashboard"
        orchestrator -> workbenchesOperator "Creates Workbenches CR with platform config" "HTTPS/443"
        workbenchesOperator -> k8sAPI "CRUD operations on CRDs, Deployments, RBAC, ConfigMaps" "HTTPS/443, TLS 1.2+, SA token"
        workbenchesOperator -> openshiftAPIServer "Reads cluster TLS security profile" "HTTPS/443, TLS 1.2+"
        workbenchesOperator -> kfNotebookController "Deploys via kustomize SSA" "Server-Side Apply"
        workbenchesOperator -> odhNotebookController "Deploys via kustomize SSA" "Server-Side Apply"
        k8sAPI -> workbenchesOperator "Admission webhook calls for Notebook CREATE/UPDATE" "HTTPS/9443, TLS (service-CA)"
        prometheus -> workbenchesOperator "Scrapes metrics" "HTTPS/8443, Bearer Token"

        controller -> manifestRenderer "Triggers manifest rendering"
        controller -> tlsBootstrap "Configures TLS on startup"
        k8sAPI -> connectionWebhook "Notebook admission request" "HTTPS/9443"
        k8sAPI -> hardwareProfileWebhook "Notebook admission request" "HTTPS/9443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Deployed by Operator" {
                background #9b59b6
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

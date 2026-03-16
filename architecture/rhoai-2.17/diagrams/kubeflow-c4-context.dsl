workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages Jupyter notebook instances for ML/AI development and experimentation"
        admin = person "Platform Administrator" "Manages notebook controller and OpenShift platform configurations"

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Extends Kubeflow Notebook controller with OpenShift-specific capabilities including OAuth proxy injection, route management, and network policy enforcement" {
            reconciler = container "OpenshiftNotebookReconciler" "Reconciles Notebook resources and manages OpenShift-specific resources (Routes, Services, NetworkPolicies, RBAC)" "Go Controller" {
                tags "Controller"
            }
            webhook = container "NotebookWebhook" "Intercepts Notebook CREATE/UPDATE operations to inject OAuth proxy sidecar and modify pod spec" "Go Mutating Admission Webhook" {
                tags "Webhook"
            }
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics on port 8080 for monitoring controller operations" "HTTP Service" {
                tags "Monitoring"
            }
        }

        kubeflowController = softwareSystem "Kubeflow Notebook Controller" "Primary controller that defines Notebook CRD and creates StatefulSets for notebook instances" "External Kubeflow"

        osRouter = softwareSystem "OpenShift Router/Ingress" "Provides external ingress to notebooks via Routes with TLS edge termination" "External OpenShift"

        oauthServer = softwareSystem "OpenShift OAuth Server" "Authenticates users and issues OAuth tokens for notebook access when OAuth injection is enabled" "External OpenShift"

        serviceCA = softwareSystem "OpenShift Service CA Operator" "Automatically provisions and rotates TLS certificates for webhook and OAuth services" "External OpenShift"

        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane API for resource management" "External Kubernetes"

        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Provides pipeline orchestration capabilities for notebooks via Elyra integration" "Internal ODH"

        serviceMesh = softwareSystem "Service Mesh (Istio)" "Optional service mesh for mTLS and traffic management of notebook workloads" "Internal ODH"

        prometheus = softwareSystem "Prometheus" "Scrapes metrics from controller for operational monitoring" "External Monitoring"

        // User interactions
        datascientist -> odhNotebookController "Creates and manages Notebook custom resources" "kubectl/oc CLI, YAML"
        datascientist -> osRouter "Accesses Jupyter notebooks via browser" "HTTPS/443"
        admin -> odhNotebookController "Configures controller settings and monitors operations" "kubectl/oc CLI"

        // Controller interactions with external systems
        odhNotebookController -> k8sAPI "Watches Notebook CRs, manages Routes, Services, Secrets, NetworkPolicies, RBAC" "gRPC/HTTPS/443"
        odhNotebookController -> kubeflowController "Extends via webhook mutation and resource creation; Kubeflow creates StatefulSets" "CRD Co-management"
        odhNotebookController -> osRouter "Creates and manages Routes for notebook external access" "Route API"
        odhNotebookController -> serviceCA "Requests TLS certificates via service annotations" "service.beta.openshift.io/serving-cert"
        odhNotebookController -> dspa "Creates RoleBindings for pipeline access if DSPA Role exists" "RBAC API (Optional)"
        odhNotebookController -> serviceMesh "Detects service mesh annotation to skip OAuth NetworkPolicy" "Annotation Detection (Optional)"

        // Webhook callback
        k8sAPI -> odhNotebookController "Calls mutating webhook for Notebook admission" "HTTPS/8443 (mTLS)"

        // OAuth flow (runtime)
        osRouter -> oauthServer "Redirects users for authentication when OAuth enabled" "OAuth 2.0/HTTPS/443"
        webhook -> oauthServer "OAuth proxy sidecar authenticates users via OAuth server" "OAuth 2.0/HTTPS/443"

        // Monitoring
        prometheus -> metricsServer "Scrapes controller metrics" "HTTP/8080"

        // Router to notebooks
        osRouter -> kubeflowController "Routes traffic to notebook StatefulSets (via Services)" "HTTP/HTTPS"
    }

    views {
        systemContext odhNotebookController "SystemContext" {
            include *
            autoLayout lr
            title "ODH Notebook Controller - System Context Diagram"
            description "System context showing ODH Notebook Controller and its interactions with users, OpenShift platform, Kubeflow, and ODH components"
        }

        container odhNotebookController "Containers" {
            include *
            include datascientist
            include admin
            include k8sAPI
            include kubeflowController
            include oauthServer
            include serviceCA
            include prometheus
            autoLayout lr
            title "ODH Notebook Controller - Container Diagram"
            description "Internal container architecture of ODH Notebook Controller showing reconciler, webhook, and metrics components"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External Kubeflow" {
                background #999999
                color #ffffff
            }
            element "External OpenShift" {
                background #cc0000
                color #ffffff
            }
            element "External Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "External Monitoring" {
                background #e6522c
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #f5a623
                color #ffffff
            }
            element "Monitoring" {
                background #e6522c
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

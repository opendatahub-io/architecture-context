workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebooks for ML development"
        admin = person "Platform Administrator" "Manages ODH platform and notebook infrastructure"

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Extends Kubeflow notebooks with OpenShift-native ingress and OAuth authentication" {
            reconciler = container "OpenshiftNotebookReconciler" "Main controller that watches Notebook CRDs and creates OpenShift resources" "Go/Kubebuilder"
            webhook = container "Notebook Webhook" "Mutating admission webhook that injects OAuth proxy and CA bundles" "Go/Kubernetes Admission Controller"
            routeReconciler = container "Route Reconciler" "Creates and manages OpenShift Routes for external notebook access" "Go Function"
            oauthReconciler = container "OAuth Reconciler" "Creates ServiceAccount, Service, Secret, and Route for OAuth integration" "Go Function"
            networkPolicyReconciler = container "NetworkPolicy Reconciler" "Creates NetworkPolicies to control ingress traffic" "Go Function"
            caBundleManager = container "CA Bundle Manager" "Manages trusted CA certificate ConfigMaps for notebooks" "Go Function"
        }

        kubeflowNotebookController = softwareSystem "Kubeflow Notebook Controller" "Upstream controller that creates StatefulSet and Service for Jupyter notebooks" "External - Kubeflow"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Provides authentication and authorization for OpenShift cluster" "OpenShift Platform"
        openshiftIngress = softwareSystem "OpenShift Ingress Controller" "Processes Routes to expose services externally" "OpenShift Platform"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Automatically provisions TLS certificates for services" "OpenShift Platform"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "Kubernetes Platform"
        imageStreamAPI = softwareSystem "ImageStream API" "OpenShift image registry and ImageStream resources" "OpenShift Platform"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science workloads" "Internal ODH"
        notebookPod = softwareSystem "Notebook Pod" "Running Jupyter notebook with optional OAuth proxy sidecar" "Workload"

        # User interactions
        user -> odhDashboard "Creates notebooks via web UI"
        user -> notebookPod "Accesses Jupyter notebook via browser" "HTTPS/443"
        admin -> kubernetesAPI "Manages cluster resources"

        # Dashboard interaction
        odhDashboard -> kubernetesAPI "Creates Notebook CRs" "HTTPS/443"

        # ODH Notebook Controller interactions
        reconciler -> kubernetesAPI "Watches Notebook CRDs, creates OpenShift resources" "HTTPS/443"
        webhook -> kubernetesAPI "Intercepts Notebook CREATE/UPDATE, mutates spec" "HTTPS/8443 mTLS"
        webhook -> imageStreamAPI "Resolves notebook images from ImageStreams" "HTTPS/443"
        routeReconciler -> openshiftIngress "Creates Routes for external access" "HTTPS/443"
        oauthReconciler -> openshiftOAuth "Integrates OAuth proxy with OpenShift auth" "HTTPS/443"
        networkPolicyReconciler -> kubernetesAPI "Creates NetworkPolicies for traffic control" "HTTPS/443"
        caBundleManager -> kubernetesAPI "Manages CA certificate ConfigMaps" "HTTPS/443"

        # Kubeflow Notebook Controller
        kubeflowNotebookController -> kubernetesAPI "Creates StatefulSet and Service for notebooks" "HTTPS/443"

        # OpenShift platform services
        openshiftIngress -> notebookPod "Routes external traffic to notebook pods" "HTTPS/443"
        openshiftServiceCA -> odhNotebookController "Provisions TLS certificates via annotations" "HTTPS/443"

        # Notebook pod authentication
        notebookPod -> openshiftOAuth "OAuth proxy authenticates users" "HTTPS/443"
        notebookPod -> kubernetesAPI "OAuth proxy performs SubjectAccessReview (SAR)" "HTTPS/443"

        # Dependencies between ODH components
        odhNotebookController -> kubeflowNotebookController "Depends on Notebook CRD definition"
    }

    views {
        systemContext odhNotebookController "SystemContext" {
            include *
            autoLayout
        }

        container odhNotebookController "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External - Kubeflow" {
                background #999999
                color #ffffff
            }
            element "OpenShift Platform" {
                background #e00000
                color #ffffff
            }
            element "Kubernetes Platform" {
                background #326ce5
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Workload" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape Component
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}

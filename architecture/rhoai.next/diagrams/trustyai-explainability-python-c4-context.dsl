workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Uses trustyai SDK in Jupyter notebooks or Python applications to explain and audit ML models"

        trustyaiPython = softwareSystem "trustyai-explainability-python" "Python SDK providing ML model explainability (LIME, SHAP, Counterfactual), fairness metrics, and language detoxification via Java bridge" {
            coreModules = container "Core Modules" "Explainers, metrics, model wrappers, visualizations" "Python"
            jpypeBridge = container "JPype JVM Bridge" "Python-to-Java bridge running embedded JVM within Python process" "JPype1 / JNI"
            javaLibrary = container "TrustyAI Java Library" "Core explainability algorithms (LIME, SHAP, Counterfactual via OptaPlanner, PDP, fairness metrics)" "Java JAR (explainability-arrow)"
            arrowIPC = container "Arrow IPC Layer" "Zero-copy data transfer between Python DataFrames and Java PredictionInputs" "Apache Arrow"
            apiClient = container "Kubernetes API Client" "Optional module for TrustyAI Service interaction and metric management" "Python (optional [api] extra)"
            tmarco = container "TMaRCo Detoxification" "Text detoxification using HuggingFace expert/anti-expert models" "Python (optional [detoxify] extra)"
            tyrusDashboard = container "Tyrus Dashboard" "Interactive Bokeh-based explainability visualization" "Python / Bokeh"
        }

        trustyaiService = softwareSystem "TrustyAI Service" "Server-side ML model fairness monitoring and metric scheduling service deployed on RHOAI" "Internal RHOAI"
        thanosQuerier = softwareSystem "Thanos Querier" "Time-series metric storage and PromQL query endpoint in openshift-monitoring" "Internal OpenShift"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API with OpenShift Route extensions for service discovery" "Internal OpenShift"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Pre-trained model repository for TMaRCo expert/anti-expert language models" "External"
        pypi = softwareSystem "PyPI" "Python Package Index for library distribution" "External"
        userModel = softwareSystem "User ML Model" "scikit-learn, XGBoost, or custom Python model being explained" "User-Provided"

        # User relationships
        dataScientist -> trustyaiPython "Explains models, computes fairness metrics, visualizes results"
        dataScientist -> userModel "Trains and provides ML model"

        # Internal relationships
        coreModules -> jpypeBridge "Calls Java algorithms via JNI"
        jpypeBridge -> javaLibrary "Executes explainability algorithms in embedded JVM"
        coreModules -> arrowIPC "Serializes data for high-performance Java transfer"
        arrowIPC -> javaLibrary "Zero-copy Arrow IPC data exchange"
        apiClient -> trustyaiService "Uploads data, queries metrics" "HTTPS/443, Bearer Token"
        apiClient -> thanosQuerier "Queries time-series metrics" "HTTPS/443, Bearer Token"
        apiClient -> openshiftAPI "Discovers service routes" "HTTPS/443, kubeconfig"
        tmarco -> huggingFaceHub "Downloads pretrained models" "HTTPS/443"
        coreModules -> userModel "Wraps and evaluates model predictions" "In-process Python"

        # External
        trustyaiPython -> pypi "Distributed as pip package" "HTTPS/443"
    }

    views {
        systemContext trustyaiPython "SystemContext" {
            include *
            autoLayout
        }

        container trustyaiPython "Containers" {
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
            element "Internal OpenShift" {
                background #4a90e2
                color #ffffff
            }
            element "User-Provided" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

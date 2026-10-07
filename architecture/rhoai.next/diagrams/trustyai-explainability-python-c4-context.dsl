workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and analyzes their fairness, explainability, and bias"

        trustyaiPython = softwareSystem "trustyai-explainability-python" "Python SDK providing ML explainability (LIME, SHAP, Counterfactual), fairness metrics, and language detoxification via JPype JVM bridge" {
            modelModule = container "trustyai.model" "Wraps Python ML models (sklearn, XGBoost) for Java interop via PredictionProvider interface" "Python Module"
            explainersModule = container "trustyai.explainers" "LIME, SHAP, Counterfactual, and PDP explainers" "Python Module"
            metricsModule = container "trustyai.metrics" "Fairness metrics (SPD, DIR, AOD), language distance metrics" "Python Module"
            detoxifyModule = container "trustyai.language.detoxify" "TMaRCo text detoxification using expert/anti-expert models" "Python Module (optional)"
            apiClient = container "trustyai.utils.api" "REST client for TrustyAI Service and Thanos Querier" "Python Module (optional)"
            visualizations = container "trustyai.visualizations" "Matplotlib and Bokeh visualization of explanation results" "Python Module"
            tyrusDashboard = container "trustyai.utils.tyrus" "Interactive Bokeh dashboard combining LIME, SHAP, and CF results" "Python Module"
            jpypeBridge = container "JPype1 Bridge" "Python-to-Java bridge running embedded JVM" "JPype1 1.5.0"
            arrowIPC = container "Arrow IPC Layer" "High-performance zero-copy data transfer between Python and Java" "pyarrow 17.0.0"
            javaCore = container "TrustyAI Java Core" "Core explainability algorithms (LIME, SHAP, Counterfactual, fairness)" "Java JAR (explainability-arrow)"
        }

        trustyaiService = softwareSystem "TrustyAI Service" "Deployed service for centralized fairness metrics and model monitoring" "Internal RHOAI"
        thanosQuerier = softwareSystem "Thanos Querier" "Time-series metric aggregation and PromQL query engine" "Internal OpenShift"
        openshiftAPI = softwareSystem "OpenShift API" "Kubernetes and Route API for service discovery" "Internal OpenShift"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Model repository for pretrained TMaRCo models" "External"
        jupyterNotebook = softwareSystem "Jupyter Notebook" "Interactive Python environment for data science" "Internal RHOAI"
        userMLModel = softwareSystem "User ML Model" "sklearn, XGBoost, or custom Python model being analyzed" "User-provided"

        # Person relationships
        dataScientist -> trustyaiPython "Imports library and calls explainability/fairness APIs" "Python API"
        dataScientist -> jupyterNotebook "Runs analysis in notebooks" "Web UI"

        # System context relationships
        trustyaiPython -> trustyaiService "Uploads data, queries metrics" "HTTPS/443, Bearer Token"
        trustyaiPython -> thanosQuerier "Queries time-series metrics via PromQL" "HTTPS/443, Bearer Token"
        trustyaiPython -> openshiftAPI "Discovers service routes" "HTTPS/443, kubeconfig"
        trustyaiPython -> huggingFaceHub "Downloads TMaRCo models" "HTTPS/443"
        trustyaiPython -> userMLModel "Wraps and evaluates for explanations" "In-process Python"
        jupyterNotebook -> trustyaiPython "import trustyai" "Python import"

        # Container relationships
        modelModule -> jpypeBridge "Converts Python models to Java PredictionProvider" "JPype JNI"
        modelModule -> arrowIPC "Serializes DataFrames for Java transfer" "Arrow IPC"
        explainersModule -> jpypeBridge "Invokes Java explainability algorithms" "JPype JNI"
        metricsModule -> jpypeBridge "Invokes Java fairness metric computations" "JPype JNI"
        jpypeBridge -> javaCore "Loads and calls TrustyAI Java library" "JNI"
        arrowIPC -> javaCore "Zero-copy data path for predictions" "Arrow IPC bytes"
        explainersModule -> visualizations "Sends explanation results for rendering" "Python API"
        visualizations -> tyrusDashboard "Populates interactive dashboard" "Python API"
        apiClient -> trustyaiService "REST calls for data upload, metric scheduling" "HTTPS/443"
        apiClient -> thanosQuerier "PromQL queries for metric time-series" "HTTPS/443"
        apiClient -> openshiftAPI "Route discovery" "HTTPS/443"
        detoxifyModule -> huggingFaceHub "Downloads expert/anti-expert models" "HTTPS/443"
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
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Internal OpenShift" {
                background #82b366
            }
            element "User-provided" {
                background #4a90e2
            }
        }
    }
}

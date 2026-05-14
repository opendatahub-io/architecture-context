workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and serves ML models via RHOAI"

        openvino = softwareSystem "OpenVINO Toolkit" "Intel's open-source deep learning inference optimization and execution framework (C++ library)" {
            runtime = container "OpenVINO Runtime" "Model loading, compilation, device management, inference scheduling" "C++ Library (libopenvino.so)"
            core = container "OpenVINO Core" "Graph representation (ov::Model), 200+ ops across opsets 1-13" "C++ Library"
            transforms = container "Transformation Pipeline" "Constant folding, precision conversion, op fusion, INT8/INT4 quantization, kernel code generation" "C++ Library"

            onnxFrontend = container "ONNX Frontend" "Reads ONNX models via protobuf" "C++ Library"
            tfFrontend = container "TensorFlow Frontend" "Reads SavedModel/frozen graphs (37 proto definitions)" "C++ Library"
            tfliteFrontend = container "TensorFlow Lite Frontend" "Reads TFLite models via flatbuffers" "C++ Library"
            pytorchFrontend = container "PyTorch Frontend" "Converts PyTorch models to IR" "C++ Library"
            paddleFrontend = container "PaddlePaddle Frontend" "Reads PaddlePaddle models" "C++ Library"
            irFrontend = container "IR Frontend" "Reads native OpenVINO IR (XML+bin)" "C++ Library"

            cpuPlugin = container "Intel CPU Plugin" "CPU inference via oneDNN, AVX2/AVX-512/AMX, xbyak JIT" "C++ Plugin (.so)"
            gpuPlugin = container "Intel GPU Plugin" "GPU inference via OpenCL, oneDNN GPU" "C++ Plugin (.so)"
            autoPlugin = container "Auto Plugin" "Automatic device selection, multi-device scheduling" "C++ Plugin (.so)"
            autoBatchPlugin = container "Auto Batch Plugin" "On-the-fly request batching for throughput" "C++ Plugin (.so)"
            heteroPlugin = container "Hetero Plugin" "Splits model layers across multiple devices" "C++ Plugin (.so)"

            pythonBindings = container "Python Bindings" "Python API via pybind11, packaged as openvino wheel" "Python (pybind11)"
            capi = container "C API" "C-compatible API for non-C++ environments" "C Library"
            jsBindings = container "JavaScript Bindings" "Node.js addon with TypeScript definitions" "Node.js Addon"
            ovc = container "Model Converter (OVC)" "CLI tool for model format conversion to IR" "Python Tool"
        }

        ovms = softwareSystem "OpenVINO Model Server (OVMS)" "Serves ML model inference via gRPC/REST, links OpenVINO as shared library" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform, manages OVMS deployments" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage" "S3/PVC/local storage for ML model artifacts" "External"
        intelCPU = softwareSystem "Intel CPU Hardware" "x86_64 CPU with AVX2/AVX-512/AMX instruction sets" "Hardware"
        intelGPU = softwareSystem "Intel GPU Hardware" "Intel HD/Iris/discrete GPU via OpenCL" "Hardware"

        # Relationships
        datascientist -> kserve "Deploys InferenceService"
        kserve -> ovms "Manages OVMS pods"
        ovms -> openvino "Links shared libraries (build-time dependency)" "C++ API (in-process)"
        ovms -> modelStorage "Downloads model artifacts" "HTTPS/S3 API"

        # Internal OpenVINO relationships
        runtime -> core "Delegates graph construction"
        runtime -> onnxFrontend "Loads ONNX models"
        runtime -> tfFrontend "Loads TensorFlow models"
        runtime -> tfliteFrontend "Loads TFLite models"
        runtime -> pytorchFrontend "Loads PyTorch models"
        runtime -> paddleFrontend "Loads PaddlePaddle models"
        runtime -> irFrontend "Loads IR models"
        core -> transforms "Applies graph optimizations"
        runtime -> cpuPlugin "Compiles for CPU execution" "Plugin API"
        runtime -> gpuPlugin "Compiles for GPU execution" "Plugin API"
        runtime -> autoPlugin "Automatic device selection" "Plugin API"
        autoPlugin -> cpuPlugin "Delegates to CPU"
        autoPlugin -> gpuPlugin "Delegates to GPU"
        cpuPlugin -> intelCPU "Executes compute kernels" "oneDNN / xbyak JIT"
        gpuPlugin -> intelGPU "Executes compute kernels" "OpenCL API"

        pythonBindings -> runtime "Wraps C++ API"
        capi -> runtime "Wraps C++ API"
        jsBindings -> runtime "Wraps C++ API"
    }

    views {
        systemContext openvino "SystemContext" {
            include *
            autoLayout
            description "OpenVINO in the RHOAI platform context - a build-time library dependency of OVMS"
        }

        container openvino "Containers" {
            include *
            autoLayout
            description "OpenVINO internal architecture: frontends, core, transformations, and device plugins"
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
            element "Hardware" {
                background #dddddd
                color #333333
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}

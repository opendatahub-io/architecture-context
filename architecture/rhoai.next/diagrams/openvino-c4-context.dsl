workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference on RHOAI"

        openvino = softwareSystem "OpenVINO Toolkit" "Intel's open-source inference optimization and execution framework (C++ library)" {
            runtime = container "OpenVINO Runtime" "Model loading, compilation, inference scheduling, device plugin management" "C++ Library (libopenvino.so)"
            core = container "OpenVINO Core" "Graph representation (ov::Model), 200+ operations (opsets 1-13), graph construction" "C++ Library"
            transformations = container "Transformation Pipeline" "Constant folding, precision conversion, op fusion, INT8/INT4 quantization (LPT), JIT kernel generation (Snippets)" "C++ Library"

            onnxFrontend = container "ONNX Frontend" "Parses ONNX models via protobuf" "C++ Library"
            tfFrontend = container "TensorFlow Frontend" "Parses TF SavedModel/frozen graphs (37 proto defs)" "C++ Library"
            pytorchFrontend = container "PyTorch Frontend" "Converts PyTorch models to IR" "C++ Library"
            paddleFrontend = container "PaddlePaddle Frontend" "Parses PaddlePaddle models" "C++ Library"
            tfliteFrontend = container "TF Lite Frontend" "Parses TFLite models via flatbuffers" "C++ Library"
            irFrontend = container "IR Frontend" "Reads OpenVINO native IR (XML+bin)" "C++ Library"

            cpuPlugin = container "Intel CPU Plugin" "Inference via oneDNN, AVX2/AVX-512/AMX, xbyak JIT" "C++ Plugin (.so)"
            gpuPlugin = container "Intel GPU Plugin" "Inference via OpenCL for Intel GPUs" "C++ Plugin (.so)"
            autoPlugin = container "Auto/Hetero/Batch Plugins" "Automatic device selection, multi-device split, auto-batching" "C++ Plugins (.so)"

            pythonBindings = container "Python Bindings" "Python API via pybind11, packaged as openvino wheel" "Python/C++"
            cApi = container "C API" "C-compatible API for non-C++ environments" "C Library"
            ovc = container "Model Converter (OVC)" "CLI tool for model format conversion" "Python Tool"
        }

        ovms = softwareSystem "OpenVINO Model Server (OVMS)" "Serves ML inference via gRPC/REST, links against OpenVINO" "RHOAI Component"
        modelStorage = softwareSystem "Model Storage" "S3, PVC, or local filesystem containing trained model files" "External"
        intelCpu = softwareSystem "Intel CPU" "x86_64 processor with AVX2/AVX-512/AMX instruction sets" "Hardware"
        intelGpu = softwareSystem "Intel GPU" "Intel HD/Iris/Discrete GPU with OpenCL support" "Hardware"
        rhoaiPlatform = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI platform operator and dashboard" "RHOAI"

        # Relationships
        dataScientist -> ovms "Sends inference requests" "gRPC/REST"
        ovms -> openvino "Links against as C++ shared library" "In-process API"
        openvino -> modelStorage "Reads model files" "File I/O"
        openvino -> intelCpu "Executes inference kernels" "oneDNN/ISA"
        openvino -> intelGpu "Offloads compute" "OpenCL"
        rhoaiPlatform -> ovms "Manages deployment" "Kubernetes API"

        # Internal relationships
        runtime -> core "Uses for graph representation"
        runtime -> transformations "Applies optimization passes"
        runtime -> cpuPlugin "Dispatches CPU inference"
        runtime -> gpuPlugin "Dispatches GPU inference"
        runtime -> autoPlugin "Auto device selection"

        onnxFrontend -> core "Produces ov::Model"
        tfFrontend -> core "Produces ov::Model"
        pytorchFrontend -> core "Produces ov::Model"
        paddleFrontend -> core "Produces ov::Model"
        tfliteFrontend -> core "Produces ov::Model"
        irFrontend -> core "Produces ov::Model"

        pythonBindings -> runtime "Wraps C++ API"
        cApi -> runtime "Wraps C++ API"
        ovc -> runtime "Uses for model conversion"
    }

    views {
        systemContext openvino "SystemContext" {
            include *
            autoLayout
            description "OpenVINO in the RHOAI ecosystem — a C++ library consumed by OVMS"
        }

        container openvino "Containers" {
            include *
            autoLayout
            description "OpenVINO internal architecture: frontends, core, transformations, and device plugins"
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Hardware" {
                background #775599
                color #ffffff
            }
            element "RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "RHOAI Component" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

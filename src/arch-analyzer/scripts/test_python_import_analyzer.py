"""Tests for python_import_analyzer.py."""
import json
import os
import pathlib
import textwrap

import pytest

from python_import_analyzer import (
    analyze,
    collect_imports,
    detect_grpc,
    discover_deps,
    import_names,
    is_test_path,
    match_pkg,
    normalize,
)


@pytest.fixture
def tmp_component(tmp_path):
    """Helper to build a component directory for testing."""
    def _make(files):
        for rel_path, content in files.items():
            path = tmp_path / rel_path
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(textwrap.dedent(content))
        return tmp_path
    return _make


class TestNormalize:
    def test_hyphens(self):
        assert normalize("scikit-learn") == "scikit-learn"

    def test_underscores(self):
        assert normalize("scikit_learn") == "scikit-learn"

    def test_dots(self):
        assert normalize("ruamel.yaml") == "ruamel-yaml"

    def test_mixed(self):
        assert normalize("My_Package.Name") == "my-package-name"


class TestImportNames:
    def test_known_mapping(self):
        assert import_names("grpcio") == ["grpc"]

    def test_known_multi(self):
        assert import_names("attrs") == ["attr", "attrs"]

    def test_dotted_mapping(self):
        assert import_names("google-cloud-storage") == ["google.cloud.storage"]

    def test_default_normalization(self):
        assert import_names("some-package") == ["some_package"]

    def test_case_insensitive(self):
        assert import_names("PyYAML") == ["yaml"]


class TestIsTestPath:
    def test_tests_dir(self):
        assert is_test_path("tests/test_foo.py")

    def test_test_prefix(self):
        assert is_test_path("src/test_utils.py")

    def test_test_suffix(self):
        assert is_test_path("src/utils_test.py")

    def test_conftest(self):
        assert is_test_path("src/conftest.py")

    def test_shipped_code(self):
        assert not is_test_path("src/main.py")

    def test_examples_dir(self):
        assert is_test_path("examples/demo.py")

    def test_demo_notebooks(self):
        assert is_test_path("demo-notebooks/foo.py")

    def test_nested_shipped(self):
        assert not is_test_path("src/mypackage/utils.py")


class TestDiscoverDeps:
    def test_pep621(self, tmp_component):
        root = tmp_component({
            "pyproject.toml": """\
                [project]
                name = "myapp"
                dependencies = ["fastapi>=0.100", "grpcio>=1.50"]

                [project.optional-dependencies]
                test = ["pytest", "httpx"]
                gpu = ["torch>=2.0"]
            """,
        })
        required, optional = discover_deps(root)
        assert sorted(required) == ["fastapi", "grpcio"]
        assert sorted(optional["test"]) == ["httpx", "pytest"]
        assert optional["gpu"] == ["torch"]

    def test_poetry(self, tmp_component):
        root = tmp_component({
            "pyproject.toml": """\
                [tool.poetry.dependencies]
                python = "^3.11"
                fastapi = ">=0.100"
                grpcio = {version = ">=1.50", optional = true}

                [tool.poetry.group.dev.dependencies]
                pytest = "^7.0"
                black = "^23.0"
            """,
        })
        required, optional = discover_deps(root)
        assert sorted(required) == ["fastapi", "grpcio"]
        assert sorted(optional["dev"]) == ["black", "pytest"]

    def test_requirements_fallback(self, tmp_component):
        root = tmp_component({
            "requirements.txt": """\
                fastapi>=0.100
                grpcio>=1.50
                # comment
                -e ./local-package
            """,
        })
        required, optional = discover_deps(root)
        assert sorted(required) == ["fastapi", "grpcio"]
        assert optional == {}

    def test_no_deps_found(self, tmp_component):
        root = tmp_component({"README.md": "# Hello"})
        required, optional = discover_deps(root)
        assert required == []
        assert optional == {}


class TestCollectImports:
    def test_basic_imports(self, tmp_component):
        root = tmp_component({
            "app/main.py": """\
                import os
                import grpc
                from fastapi import FastAPI
            """,
        })
        shipped, test = collect_imports(root)
        assert "os" in shipped
        assert "grpc" in shipped
        assert "fastapi" in shipped
        assert "fastapi.FastAPI" in shipped
        assert len(test) == 0

    def test_test_classification(self, tmp_component):
        root = tmp_component({
            "src/main.py": "import fastapi\n",
            "tests/test_main.py": "import pytest\n",
        })
        shipped, test = collect_imports(root)
        assert "fastapi" in shipped
        assert "pytest" in test
        assert "pytest" not in shipped
        assert "fastapi" not in test

    def test_skips_pb2_files(self, tmp_component):
        root = tmp_component({
            "proto/service_pb2.py": "import grpc\n",
            "proto/service_pb2_grpc.py": "import grpc\n",
            "src/main.py": "import fastapi\n",
        })
        shipped, test = collect_imports(root)
        assert "fastapi" in shipped
        assert "grpc" not in shipped

    def test_skips_relative_imports(self, tmp_component):
        root = tmp_component({
            "pkg/__init__.py": "",
            "pkg/main.py": "from . import utils\nfrom .config import Settings\n",
        })
        shipped, test = collect_imports(root)
        # Relative imports should not appear
        for key in shipped:
            assert not key.startswith(".")

    def test_dotted_imports(self, tmp_component):
        root = tmp_component({
            "app/main.py": """\
                from opentelemetry.sdk import trace
                from google.protobuf import descriptor
            """,
        })
        shipped, _ = collect_imports(root)
        assert "opentelemetry.sdk" in shipped
        assert "opentelemetry.sdk.trace" in shipped
        assert "google.protobuf" in shipped
        assert "google.protobuf.descriptor" in shipped

    def test_conftest_is_test(self, tmp_component):
        root = tmp_component({
            "src/conftest.py": "import pytest\n",
            "src/main.py": "import fastapi\n",
        })
        shipped, test = collect_imports(root)
        assert "pytest" in test
        assert "pytest" not in shipped


class TestDetectGrpc:
    def test_sync_server(self, tmp_component):
        root = tmp_component({
            "server.py": """\
                import grpc
                server = grpc.server(thread_pool)
            """,
        })
        has_server, regs = detect_grpc(root)
        assert has_server
        assert regs == []

    def test_async_server(self, tmp_component):
        root = tmp_component({
            "server.py": """\
                from grpc import aio
                server = aio.server(options=options)
            """,
        })
        has_server, regs = detect_grpc(root)
        assert has_server

    def test_servicer_registration(self, tmp_component):
        root = tmp_component({
            "server.py": """\
                import grpc
                server = grpc.server(pool)
                inference_pb2_grpc.add_InferenceServiceServicer_to_server(servicer, server)
                health_pb2_grpc.add_HealthServicer_to_server(health, server)
            """,
        })
        has_server, regs = detect_grpc(root)
        assert has_server
        assert len(regs) == 2
        names = [r["servicer"] for r in regs]
        assert "InferenceServiceServicer" in names
        assert "HealthServicer" in names
        assert all("server.py:" in r["source"] for r in regs)

    def test_no_grpc(self, tmp_component):
        root = tmp_component({
            "app.py": "from fastapi import FastAPI\napp = FastAPI()\n",
        })
        has_server, regs = detect_grpc(root)
        assert not has_server
        assert regs == []

    def test_test_dir_excluded(self, tmp_component):
        root = tmp_component({
            "tests/test_server.py": """\
                import grpc
                server = grpc.server(pool)
                add_TestServicer_to_server(servicer, server)
            """,
        })
        has_server, regs = detect_grpc(root)
        assert not has_server
        assert regs == []


class TestMatchPkg:
    def test_exact_match(self):
        modules = {"grpc": "main.py:1"}
        assert match_pkg("grpcio", modules)

    def test_prefix_match(self):
        modules = {"grpc.aio": "server.py:5"}
        assert match_pkg("grpcio", modules)

    def test_dotted_package(self):
        modules = {"opentelemetry.sdk": "trace.py:1"}
        assert match_pkg("opentelemetry-sdk", modules)

    def test_no_match(self):
        modules = {"numpy": "main.py:1"}
        assert not match_pkg("pandas", modules)

    def test_no_false_prefix(self):
        modules = {"opentelemetry": "main.py:1"}
        assert not match_pkg("opentelemetry-sdk", modules)

    def test_namespace_no_cross_match(self):
        modules = {"google.protobuf": "main.py:1"}
        assert not match_pkg("google-cloud-storage", modules)
        assert match_pkg("protobuf", modules)


class TestAnalyzeIntegration:
    def test_used_dependency(self, tmp_component):
        root = tmp_component({
            "pyproject.toml": """\
                [project]
                name = "myapp"
                dependencies = ["fastapi>=0.100", "numpy"]
            """,
            "app/main.py": """\
                from fastapi import FastAPI
                app = FastAPI()
            """,
        })
        result = analyze(root)
        used_pkgs = [u["package"] for u in result["used"]]
        assert "fastapi" in used_pkgs
        assert "numpy" in result["declared_unused"]

    def test_test_only_dependency(self, tmp_component):
        root = tmp_component({
            "pyproject.toml": """\
                [project]
                name = "myapp"
                dependencies = ["fastapi", "pytest"]
            """,
            "app/main.py": "from fastapi import FastAPI\n",
            "tests/test_app.py": "import pytest\n",
        })
        result = analyze(root)
        used_pkgs = [u["package"] for u in result["used"]]
        assert "fastapi" in used_pkgs
        assert "pytest" in result["test_only"]

    def test_optional_group_classification(self, tmp_component):
        root = tmp_component({
            "pyproject.toml": """\
                [project]
                name = "myapp"
                dependencies = ["grpcio"]

                [project.optional-dependencies]
                runtime-grpc = ["grpcio-health-checking", "grpcio-reflection"]
                dev = ["pytest", "black"]
            """,
            "app/server.py": """\
                import grpc
                from grpc_health.v1.health import HealthServicer
            """,
        })
        result = analyze(root)
        grpc_group = result["optional_groups"]["runtime-grpc"]
        assert "grpcio-health-checking" in grpc_group["used"]
        assert "grpcio-reflection" in grpc_group["unused"]
        dev_group = result["optional_groups"]["dev"]
        assert dev_group["used"] == []
        assert sorted(dev_group["unused"]) == ["black", "pytest"]

    def test_grpc_integration(self, tmp_component):
        root = tmp_component({
            "pyproject.toml": """\
                [project]
                name = "myapp"
                dependencies = ["grpcio"]
            """,
            "app/server.py": """\
                import grpc
                from concurrent.futures import ThreadPoolExecutor
                server = grpc.server(ThreadPoolExecutor(max_workers=10))
                inference_pb2_grpc.add_InferenceServiceServicer_to_server(svc, server)
            """,
        })
        result = analyze(root)
        assert result["grpc_server"] is True
        assert len(result["grpc_registrations"]) == 1
        assert result["grpc_registrations"][0]["servicer"] == "InferenceServiceServicer"

    def test_no_dependencies(self, tmp_component):
        root = tmp_component({"README.md": "# Hello"})
        result = analyze(root)
        assert result.get("status") == "no_dependencies_found"

    def test_pyproject_not_proof_of_usage(self, tmp_component):
        """Declaring a dependency in pyproject.toml must not count as evidence
        of runtime usage without a matching import."""
        root = tmp_component({
            "pyproject.toml": """\
                [project]
                name = "myapp"
                dependencies = ["ray", "kubernetes", "torch"]
            """,
            "app/main.py": "print('hello')\n",
        })
        result = analyze(root)
        assert result["used"] == []
        assert sorted(result["declared_unused"]) == ["kubernetes", "ray", "torch"]

    def test_optional_extras_not_conflated(self, tmp_component):
        """Optional extras must not be treated as required dependencies."""
        root = tmp_component({
            "pyproject.toml": """\
                [project]
                name = "myapp"
                dependencies = ["click"]

                [project.optional-dependencies]
                gpu = ["torch>=2.0"]
            """,
            "app/cli.py": "import click\n",
        })
        result = analyze(root)
        used_pkgs = [u["package"] for u in result["used"]]
        assert "click" in used_pkgs
        gpu = result["optional_groups"]["gpu"]
        assert gpu["used"] == []
        assert gpu["unused"] == ["torch"]

    def test_proto_without_registration(self, tmp_component):
        """Proto definitions alone must not produce gRPC registration evidence."""
        root = tmp_component({
            "pyproject.toml": """\
                [project]
                name = "myapp"
                dependencies = ["grpcio", "protobuf"]
            """,
            "proto/service.proto": """\
                syntax = "proto3";
                service MyService { rpc Predict(Request) returns (Response); }
            """,
            "app/client.py": """\
                import grpc
                channel = grpc.insecure_channel("localhost:50051")
            """,
        })
        result = analyze(root)
        assert result["grpc_server"] is False
        assert result["grpc_registrations"] == []

    def test_source_reference_included(self, tmp_component):
        root = tmp_component({
            "pyproject.toml": """\
                [project]
                name = "myapp"
                dependencies = ["fastapi"]
            """,
            "app/main.py": "from fastapi import FastAPI\n",
        })
        result = analyze(root)
        assert result["used"][0]["source"].startswith("app/main.py:")

    def test_poetry_with_grpc(self, tmp_component):
        root = tmp_component({
            "pyproject.toml": """\
                [tool.poetry.dependencies]
                python = "^3.11"
                grpcio = ">=1.50"
                fastapi = ">=0.100"

                [tool.poetry.group.dev.dependencies]
                pytest = "^7.0"
            """,
            "app/server.py": """\
                from grpc import aio
                from fastapi import FastAPI
                server = aio.server()
                inference_pb2_grpc.add_ModelServiceServicer_to_server(svc, server)
            """,
        })
        result = analyze(root)
        used_pkgs = [u["package"] for u in result["used"]]
        assert "grpcio" in used_pkgs
        assert "fastapi" in used_pkgs
        assert result["grpc_server"] is True
        assert result["grpc_registrations"][0]["servicer"] == "ModelServiceServicer"
        assert "pytest" in result["optional_groups"]["dev"]["unused"]

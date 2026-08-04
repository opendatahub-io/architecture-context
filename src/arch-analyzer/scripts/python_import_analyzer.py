#!/usr/bin/env python3
"""Static analysis of Python imports against declared dependencies.

Usage: python3 python_import_analyzer.py <component_path>

Parses pyproject.toml to discover declared dependencies (PEP 621 and Poetry
formats), walks Python source files using ast to verify which dependencies
are actually imported in shipped (non-test) code, and detects gRPC server
registration patterns. Falls back to requirements.txt if no pyproject.toml.

Outputs JSON to stdout.
"""
import ast
import json
import os
import pathlib
import re
import sys
import tomllib

PYPI_TO_IMPORT = {
    "alchemy-config": ["aconfig"],
    "alchemy-logging": ["alog"],
    "attrs": ["attr", "attrs"],
    "beautifulsoup4": ["bs4"],
    "click-option-group": ["click_option_group"],
    "docstring-parser": ["docstring_parser"],
    "google-api-core": ["google.api_core"],
    "google-auth": ["google.auth"],
    "google-cloud-storage": ["google.cloud.storage"],
    "grpcio": ["grpc"],
    "grpcio-health-checking": ["grpc_health"],
    "grpcio-reflection": ["grpc_reflection"],
    "grpcio-tools": ["grpc_tools"],
    "importlib-metadata": ["importlib_metadata"],
    "importlib-resources": ["importlib_resources"],
    "kfp-pipeline-spec": ["kfp.pipeline_spec"],
    "kfp-server-api": ["kfp_server_api"],
    "kube-authkit": ["kube_authkit"],
    "nvidia-ml-py": ["pynvml"],
    "openshift-client": ["openshift"],
    "opentelemetry-api": ["opentelemetry"],
    "opentelemetry-exporter-otlp": ["opentelemetry.exporter.otlp"],
    "opentelemetry-exporter-otlp-proto-grpc": [
        "opentelemetry.exporter.otlp.proto.grpc",
    ],
    "opentelemetry-instrumentation-fastapi": ["opentelemetry.instrumentation.fastapi"],
    "opentelemetry-instrumentation-grpc": ["opentelemetry.instrumentation.grpc"],
    "opentelemetry-sdk": ["opentelemetry.sdk"],
    "pillow": ["PIL"],
    "protobuf": ["google.protobuf"],
    "py-grpc-prometheus": ["py_grpc_prometheus"],
    "py-to-proto": ["py_to_proto"],
    "pydantic-settings": ["pydantic_settings"],
    "python-dateutil": ["dateutil"],
    "python-dotenv": ["dotenv"],
    "python-multipart": ["multipart"],
    "pyyaml": ["yaml"],
    "requests-toolbelt": ["requests_toolbelt"],
    "scikit-learn": ["sklearn"],
    "setuptools": ["pkg_resources", "setuptools"],
    "sse-starlette": ["sse_starlette"],
    "starlette-exporter": ["starlette_exporter"],
    "typing-extensions": ["typing_extensions"],
}

_NORM_RE = re.compile(r"[-_.]+")
_REQ_RE = re.compile(r"^([A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?)")
_SERVICER_RE = re.compile(r"\badd_(\w+Servicer)_to_server\s*\(")
_GRPC_SERVER_RE = re.compile(
    r"\b(?:grpc\s*\.(?:\s*aio\s*\.)?\s*server|aio\s*\.\s*server)\s*\("
)

SKIP_DIRS = frozenset({
    ".git", ".hg", ".svn", ".venv", "venv", "env", "site-packages",
    "node_modules", "vendor", "dist", "build", "target", "__pycache__",
    ".claude", ".github", ".tox",
})

TEST_DIRS = frozenset({
    "tests", "test", "testing", "examples", "example",
    "benchmarks", "benchmark", "docs", "doc", "dev",
    "demo-notebooks", "demos", "ui-tests",
})


def normalize(name):
    return _NORM_RE.sub("-", name).lower().strip()


def import_names(package):
    canonical = normalize(package)
    if canonical in PYPI_TO_IMPORT:
        return PYPI_TO_IMPORT[canonical]
    return [canonical.replace("-", "_")]


def is_test_path(relative):
    parts = pathlib.PurePosixPath(relative).parts
    for part in parts[:-1]:
        if part.lower() in TEST_DIRS:
            return True
    name = parts[-1].lower() if parts else ""
    return (name.startswith("test_") or name.endswith("_test.py")
            or name == "conftest.py")


def extract_name(spec):
    spec = spec.split(";")[0].strip()
    if not spec or spec.startswith("-") or "${" in spec:
        return None
    match = _REQ_RE.match(spec)
    return match.group(1) if match else None


def discover_deps(root):
    required, optional = [], {}
    pyproject = root / "pyproject.toml"
    if pyproject.is_file():
        try:
            with open(pyproject, "rb") as f:
                data = tomllib.load(f)
        except Exception:
            data = {}

        proj = data.get("project", {})
        for dep in proj.get("dependencies", []):
            if n := extract_name(dep):
                required.append(n)
        for group, deps in proj.get("optional-dependencies", {}).items():
            names = [n for d in deps if (n := extract_name(d))]
            if names:
                optional[group] = names

        poetry = data.get("tool", {}).get("poetry", {})
        if not required:
            for name in poetry.get("dependencies", {}):
                if name.lower() != "python":
                    required.append(name)
        for gname, gdata in poetry.get("group", {}).items():
            names = list(gdata.get("dependencies", {}).keys())
            if names:
                optional[gname] = names

    if not required:
        for pattern in ("requirements.txt", "requirements.in"):
            req = root / pattern
            if req.is_file():
                for line in req.read_text(errors="replace").splitlines():
                    line = line.split("#")[0].strip()
                    if line and not line.startswith("-"):
                        if n := extract_name(line):
                            required.append(n)
                break

    return required, optional


def collect_imports(root):
    shipped, test = {}, {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d.lower() not in SKIP_DIRS)
        for filename in sorted(filenames):
            if not filename.endswith(".py"):
                continue
            if filename.endswith(("_pb2.py", "_pb2_grpc.py")):
                continue
            fp = pathlib.Path(dirpath) / filename
            try:
                if fp.stat().st_size > 2_097_152:
                    continue
                source = fp.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            try:
                tree = ast.parse(source, filename=filename)
            except SyntaxError:
                continue

            rel = fp.relative_to(root).as_posix()
            target = test if is_test_path(rel) else shipped

            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        target.setdefault(alias.name, f"{rel}:{node.lineno}")
                elif (
                    isinstance(node, ast.ImportFrom)
                    and node.module
                    and node.level == 0
                ):
                    ref = f"{rel}:{node.lineno}"
                    target.setdefault(node.module, ref)
                    for alias in node.names:
                        target.setdefault(f"{node.module}.{alias.name}", ref)

    return shipped, test


def detect_grpc(root):
    has_server = False
    registrations = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(
            d for d in dirnames
            if d.lower() not in SKIP_DIRS and d.lower() not in TEST_DIRS
        )
        for filename in sorted(filenames):
            if not filename.endswith(".py"):
                continue
            if filename.endswith(("_pb2.py", "_pb2_grpc.py")):
                continue
            fp = pathlib.Path(dirpath) / filename
            try:
                source = fp.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            rel = fp.relative_to(root).as_posix()
            if _GRPC_SERVER_RE.search(source):
                has_server = True
            for m in _SERVICER_RE.finditer(source):
                lineno = source[: m.start()].count("\n") + 1
                registrations.append({
                    "servicer": m.group(1),
                    "source": f"{rel}:{lineno}",
                })

    return has_server, registrations


def match_pkg(package, modules):
    matches = []
    for iname in import_names(package):
        for mod, ref in modules.items():
            if mod == iname or mod.startswith(iname + "."):
                matches.append(ref)
    return matches


def analyze(root):
    required, optional = discover_deps(root)
    if not required and not optional:
        return {"status": "no_dependencies_found"}

    shipped, test = collect_imports(root)
    grpc_server, grpc_regs = detect_grpc(root)

    all_pkgs = set(required)
    for deps in optional.values():
        all_pkgs.update(deps)

    used, test_only, unused = [], [], []
    for pkg in sorted(all_pkgs, key=lambda s: s.lower()):
        shipped_refs = match_pkg(pkg, shipped)
        if shipped_refs:
            used.append({
                "package": pkg,
                "imports": import_names(pkg),
                "source": shipped_refs[0],
            })
        elif match_pkg(pkg, test):
            test_only.append(pkg)
        else:
            unused.append(pkg)

    opt_result = {}
    for group, deps in sorted(optional.items()):
        g_used, g_unused = [], []
        for pkg in deps:
            if match_pkg(pkg, shipped):
                g_used.append(pkg)
            else:
                g_unused.append(pkg)
        opt_result[group] = {"used": g_used, "unused": g_unused}

    return {
        "used": used,
        "test_only": test_only,
        "declared_unused": unused,
        "optional_groups": opt_result,
        "grpc_server": grpc_server,
        "grpc_registrations": grpc_regs,
    }


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <component_path>", file=sys.stderr)
        sys.exit(1)
    root = pathlib.Path(sys.argv[1]).resolve()
    if not root.is_dir():
        print(f"Error: {root} is not a directory", file=sys.stderr)
        sys.exit(1)
    result = analyze(root)
    json.dump(result, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()

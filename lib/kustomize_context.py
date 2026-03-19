"""Kustomize overlay context extraction from operator source."""

import re
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass


@dataclass
class KustomizeContext:
    """RHOAI kustomize deployment context extracted from operator source."""

    component_key: str
    overlay_paths: Dict[str, str]   # platform/name -> overlay path
    image_params: Dict[str, str]    # param name -> RELATED_IMAGE env var
    params_env: Dict[str, str]      # key -> value from params.env
    params_env_path: str            # relative path to params.env file used
    kustomize_vars: Dict[str, str]  # computed kustomize variables


# Map manifest key -> operator component directory when they differ
_COMPONENT_DIR_MAP = {
    'maas': 'modelsasservice',
}

# Components that have no kustomize overlay context
_SKIP_COMPONENTS = {'operator'}


def _get_component_dir(component_key: str) -> Optional[str]:
    """Map a manifest component key to the operator component directory name."""
    if component_key in _SKIP_COMPONENTS:
        return None
    # Keys like workbenches/kf-notebook-controller -> workbenches
    if '/' in component_key:
        return component_key.split('/')[0]
    return _COMPONENT_DIR_MAP.get(component_key, component_key)


def _parse_overlay_paths(content: str) -> Dict[str, str]:
    """Extract overlay/source paths from Go source files.

    Handles three patterns:
    1. Platform map literals: ``map[common.Platform]string{...}``
    2. Named const/var assignments containing "Manifest" or "Source" + "Path"
    3. Struct-literal ``SourcePath: "..."`` (fallback)
    """
    overlay_paths: Dict[str, str] = {}

    # Pattern 1: map[common.Platform]string with platform keys
    map_pattern = r'(\w+)\s*=\s*map\[(?:common\.)?Platform\]string\s*\{(.*?)\}'
    for map_match in re.finditer(map_pattern, content, re.DOTALL):
        var_name = map_match.group(1)
        map_body = map_match.group(2)
        # Only keep maps whose values look like filesystem paths (not display strings)
        entry_pattern = r'cluster\.(SelfManagedRhoai|ManagedRhoai|OpenDataHub)\s*:\s*"([^"]*)"'
        entries = {m.group(1): m.group(2) for m in re.finditer(entry_pattern, map_body)}
        if not entries:
            continue
        # Heuristic: if all values contain spaces they are display strings, skip
        if all(' ' in v for v in entries.values()):
            continue
        for platform, path in entries.items():
            key = f"{var_name}:{platform}"
            overlay_paths[key] = path.lstrip('/')

    # Pattern 2: named const/var with path value
    # e.g. kserveManifestSourcePath = "overlays/odh"
    const_pattern = r'(\w*(?:Manifest|Source)\w*Path\w*)\s*=\s*"([^"]*)"'
    for match in re.finditer(const_pattern, content):
        name = match.group(1)
        path = match.group(2).lstrip('/')
        if name not in overlay_paths:
            overlay_paths[name] = path

    # Pattern 3 (fallback): SourcePath: "literal" in struct literals
    if not overlay_paths:
        struct_pattern = r'SourcePath:\s*"([^"]+)"'
        for match in re.finditer(struct_pattern, content):
            path = match.group(1).lstrip('/')
            overlay_paths['default'] = path
            break

    return overlay_paths


def _parse_image_params(content: str) -> Dict[str, str]:
    """Extract imageParamMap / imagesMap entries from Go source."""
    image_params: Dict[str, str] = {}
    map_pattern = r'(?:imageParamMap|imagesMap)\s*=\s*map\[string\]string\s*\{(.*?)\}'
    for map_match in re.finditer(map_pattern, content, re.DOTALL):
        entry_pattern = r'"([^"]+)":\s*"(RELATED_IMAGE_[^"]+)"'
        for entry in re.finditer(entry_pattern, map_match.group(1)):
            image_params[entry.group(1)] = entry.group(2)
    return image_params


def _parse_kustomize_vars(content: str) -> Dict[str, str]:
    """Extract computed kustomize variable maps (e.g. sectionTitle) from Go source."""
    kustomize_vars: Dict[str, str] = {}
    map_pattern = r'(\w+)\s*=\s*map\[(?:common\.)?Platform\]string\s*\{(.*?)\}'
    for map_match in re.finditer(map_pattern, content, re.DOTALL):
        var_name = map_match.group(1)
        map_body = map_match.group(2)
        entry_pattern = r'cluster\.(SelfManagedRhoai|ManagedRhoai|OpenDataHub)\s*:\s*"([^"]*)"'
        entries = {m.group(1): m.group(2) for m in re.finditer(entry_pattern, map_body)}
        if not entries:
            continue
        # Keep only maps whose values are display strings (contain spaces)
        if not all(' ' in v for v in entries.values()):
            continue
        for platform, value in entries.items():
            kustomize_vars[f"{var_name}:{platform}"] = value
    return kustomize_vars


def _read_params_env(params_path: Path, operator_path: Path) -> tuple:
    """Read a params.env file and return (dict, relative_path)."""
    params_env: Dict[str, str] = {}
    rel_path = str(params_path.relative_to(operator_path))
    for line in params_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if '=' in line:
            k, v = line.split('=', 1)
            params_env[k] = v
    return params_env, rel_path


def _find_params_env(
    component_key: str,
    operator_path: Path,
    overlay_paths: Dict[str, str],
) -> tuple:
    """Locate and parse the most relevant params.env from prefetched-manifests."""
    prefetched = operator_path / "prefetched-manifests"
    component_dir = prefetched / component_key
    if not component_dir.exists():
        return {}, ""

    # Build search order: RHOAI overlay paths first, then fallbacks
    search_paths: List[str] = []
    for key, path in overlay_paths.items():
        if 'SelfManagedRhoai' in key:
            search_paths.append(path)
    for key, path in overlay_paths.items():
        if 'ManagedRhoai' in key and path not in search_paths:
            search_paths.append(path)
    for _key, path in overlay_paths.items():
        if path not in search_paths:
            search_paths.append(path)
    for fallback in ['base', 'overlays/rhoai', 'overlays/odh']:
        if fallback not in search_paths:
            search_paths.append(fallback)

    for search_path in search_paths:
        params_path = component_dir / search_path / "params.env"
        if params_path.exists():
            return _read_params_env(params_path, operator_path)

    # Last resort: any params.env in the component directory
    for params_path in sorted(component_dir.rglob("params.env")):
        return _read_params_env(params_path, operator_path)

    return {}, ""


def get_component_kustomize_context(
    component_key: str,
    operator_path: Path,
) -> Optional[KustomizeContext]:
    """
    Extract RHOAI kustomize deployment context for a component.

    Parses the operator's ``*_support.go`` (and sibling ``.go``) files to
    determine which overlay path, image parameters, and params.env values the
    rhods-operator applies when deploying this component.

    Args:
        component_key: Manifest component key (e.g. "dashboard", "kserve")
        operator_path: Path to the operator checkout
                       (e.g. checkouts/.../rhods-operator)

    Returns:
        KustomizeContext with extracted data, or None if no support.go exists.
    """
    component_dir = _get_component_dir(component_key)
    if component_dir is None:
        return None

    component_dir_path = (
        operator_path / "internal" / "controller" / "components" / component_dir
    )
    if not component_dir_path.exists():
        return None

    # Require at least one *_support.go file
    support_files = list(component_dir_path.glob("*_support.go"))
    if not support_files:
        return None

    # Read all non-test Go files for complete parsing
    content = ""
    for go_file in sorted(component_dir_path.glob("*.go")):
        if go_file.name.endswith("_test.go"):
            continue
        content += go_file.read_text() + "\n"

    overlay_paths = _parse_overlay_paths(content)
    image_params = _parse_image_params(content)
    kustomize_vars = _parse_kustomize_vars(content)
    params_env, params_env_path = _find_params_env(
        component_key, operator_path, overlay_paths
    )

    if not overlay_paths and not image_params:
        return None

    return KustomizeContext(
        component_key=component_key,
        overlay_paths=overlay_paths,
        image_params=image_params,
        params_env=params_env,
        params_env_path=params_env_path,
        kustomize_vars=kustomize_vars,
    )


def format_kustomize_context(
    ctx: KustomizeContext,
    source_folder: str = "",
) -> str:
    """
    Format KustomizeContext into a string for injection into agent prompts.

    Args:
        ctx: Extracted kustomize deployment context
        source_folder: The component's source_folder from manifests
                       (e.g. "config", "manifests")

    Returns:
        Multi-line prompt string describing the RHOAI kustomize context.
    """
    lines: List[str] = []
    lines.append("RHOAI Kustomize Deployment Context:")
    lines.append(
        "This component is deployed by the rhods-operator using kustomize overlays."
    )

    # Determine the primary RHOAI overlay path
    rhoai_overlay = None
    for key, path in ctx.overlay_paths.items():
        if 'SelfManagedRhoai' in key:
            rhoai_overlay = path
            break
    if rhoai_overlay is None:
        # Fall back to the first available path
        rhoai_overlay = next(iter(ctx.overlay_paths.values()), None)

    if rhoai_overlay:
        lines.append(
            f"The operator applies the following overlay for RHOAI self-managed: "
            f"{rhoai_overlay}"
        )
        if source_folder:
            lines.append(
                f"\nOverlay path within source_folder: {rhoai_overlay}"
            )
            lines.append(
                "This means the kustomization.yaml the operator actually "
                "processes is at:"
            )
            lines.append(f"  {source_folder}/{rhoai_overlay}/kustomization.yaml")

    # Show all overlay paths when there are multiple
    if len(ctx.overlay_paths) > 1:
        lines.append("\nAll overlay paths by platform/name:")
        for key, path in ctx.overlay_paths.items():
            lines.append(f"  {key}: {path}")

    if ctx.image_params:
        lines.append("\nImage parameters injected by operator at deploy time:")
        for param, env_var in sorted(ctx.image_params.items()):
            lines.append(f"  {param} -> {env_var}")

    if ctx.params_env:
        lines.append(f"\nparams.env values (from {ctx.params_env_path}):")
        for k, v in ctx.params_env.items():
            lines.append(f"  {k}={v}")

    if ctx.kustomize_vars:
        lines.append("\nComputed kustomize variables:")
        for key, value in ctx.kustomize_vars.items():
            lines.append(f"  {key}: {value}")

    if rhoai_overlay and source_folder:
        lines.append(
            f"\nIMPORTANT: When analyzing this component's kustomize manifests, "
            f"start from the overlay\n"
            f"kustomization.yaml at {source_folder}/{rhoai_overlay}/ rather than "
            f"the base. The overlay\n"
            f"determines which resources are actually deployed on RHOAI. The "
            f"params.env values above\n"
            f"show the default image references and configuration the operator "
            f"injects."
        )

    return "\n".join(lines)

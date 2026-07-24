import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.architecture_baseline import (  # noqa: E402
    REQUIRED_H2_SECTIONS,
    compare_component_documents,
    parse_component_markdown,
    parse_component_markdown_text,
)


def test_parser_handles_heading_paths_and_table_pipes():
    document = parse_component_markdown_text(
        r"""# Component: Example

## APIs Exposed

### HTTP Endpoints

| Path | Method | Purpose |
|------|--------|---------|
| `/readyz` | GET | Ready \| healthy |
| `/items` | POST | `left|right` payload |
"""
    )

    assert document.title == "Component: Example"
    assert document.h2_sections == ("APIs Exposed",)
    assert len(document.tables) == 1
    table = document.tables[0]
    assert table.section_path == ("APIs Exposed", "HTTP Endpoints")
    assert table.rows[0] == ("`/readyz`", "GET", "Ready \\| healthy")
    assert table.rows[1] == ("`/items`", "POST", "`left|right` payload")


def test_comparison_reports_missing_additional_and_conflicting_facts():
    baseline = parse_component_markdown_text(
        """# Component: Example

## APIs Exposed
### Custom Resource Definitions (CRDs)
| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| example.io | v1 | Widget | Namespaced | Test |
| example.io | v1 | ClusterWidget | Cluster | Test |

## Purpose
Baseline purpose.
""",
        path="baseline.md",
    )
    candidate = parse_component_markdown_text(
        """# Example

## CRDs
| Kind | Group | Version | Scope | Source |
|------|-------|---------|-------|--------|
| Widget | example.io | v1 | Cluster | api/v1/widget.go:10 |
| NewWidget | example.io | v1 | Namespaced | api/v1/new.go:10 |

## Controller Watches
| Controller | Resource | Source |
|------------|----------|--------|
| widget-controller | Widget | internal/controller/widget.go:20 |
""",
        path="candidate.md",
    )

    report = compare_component_documents(baseline, candidate)

    assert report.baseline_rows == 2
    assert report.matched_rows == 1
    assert report.row_recall == 0.5
    assert report.conflict_count == 1
    assert report.unmapped_candidate_rows == 1
    assert report.unmapped_candidate_tables[0].section_path == ("Controller Watches",)
    assert report.missing_synthesis_sections == [
        "Purpose",
        "Data Flows",
        "Architectural Analysis",
    ]
    crds = report.categories[0]
    assert crds.missing_keys == [("example.io", "v1", "clusterwidget")]
    assert crds.additional_keys == [("example.io", "v1", "newwidget")]
    assert crds.conflicts[0].column == "scope"


def test_document_matches_itself_without_fact_drift():
    baseline = parse_component_markdown_text(
        """# Component: Example

## Network Architecture
### Services
| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| api | ClusterIP | 8443/TCP | 8080 | TCP | TLS | Token | Internal |
"""
    )

    report = compare_component_documents(baseline, baseline)

    assert report.row_recall == 1.0
    assert report.conflict_count == 0
    assert report.categories[0].additional_keys == []
    assert report.categories[0].missing_keys == []


def test_source_line_comparison_accepts_mixed_ranges_and_single_lines():
    baseline = parse_component_markdown_text(
        """# Component: Example

## Source References
### Files Analyzed
| File | Lines | Sections Informed |
|------|-------|-------------------|
| app.py | 1-40 | Purpose |
"""
    )
    candidate = parse_component_markdown_text(
        """# Component: Example

## Source References
### Files Analyzed
| File | Lines | Sections Informed |
|------|-------|-------------------|
| app.py | 7, 12, 17-35 | Purpose |
"""
    )

    report = compare_component_documents(baseline, candidate)

    assert report.row_recall == 1.0
    assert report.conflict_count == 0


def test_rbac_rules_use_rule_identity_and_source_line_subsets_are_equivalent():
    document = parse_component_markdown_text(
        """# Component: Example

## Security
### RBAC - Cluster Roles
| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager | apps | deployments | list, get |
| manager | batch | jobs | create, delete |

## Source References
### Files Analyzed
| File | Lines | Sections Informed |
|------|-------|-------------------|
| controller.go | 10, 11, 12 | Security |
"""
    )
    baseline = parse_component_markdown_text(
        """# Component: Example

## Security
### RBAC - Cluster Roles
| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager | apps | deployments | get, list |
| manager | batch | jobs | create, delete |

## Source References
### Files Analyzed
| File | Lines | Sections Informed |
|------|-------|-------------------|
| controller.go | 1-100 | Security |
"""
    )

    report = compare_component_documents(baseline, document)

    assert report.baseline_rows == 3
    assert report.matched_rows == 3
    assert report.conflict_count == 0


def test_rbac_identity_normalizes_core_group_and_list_order():
    baseline = parse_component_markdown_text(
        '''# Component: Example

## Security
### RBAC - Cluster Roles
| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager | "" | configmaps, secrets, services | get, list |
| manager | networking.k8s.io | networkpolicies, ingresses | create |
'''
    )
    candidate = parse_component_markdown_text(
        """# Component: Example

## Security
### RBAC - Cluster Roles
| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| manager |  | services, configmaps, secrets | list, get |
| manager | networking.k8s.io | ingresses, networkpolicies | create |
"""
    )

    report = compare_component_documents(baseline, candidate)

    assert report.matched_rows == 2
    assert report.conflict_count == 0


def test_structured_recall_excludes_history_and_source_inventory():
    document = parse_component_markdown_text(
        """# Component: Example

## Architecture Components
| Component | Type | Purpose |
|-----------|------|---------|
| api | service | API |

## Recent Changes
| Version | Date | Changes |
|---------|------|---------|
| abc | 2026-01-01 | Initial |

## Source References
### Files Analyzed
| File | Lines | Sections Informed |
|------|-------|-------------------|
| app.go | 1-20 | Components |
"""
    )

    report = compare_component_documents(document, document)

    assert report.baseline_rows == 3
    assert report.structured_baseline_rows == 1
    assert report.structured_matched_rows == 1
    assert report.structured_row_recall == 1.0


def test_role_binding_kind_is_specific_when_present_and_wildcard_when_absent():
    baseline = parse_component_markdown_text(
        """# Component: Example

## Security
### RBAC - Role Bindings
| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| dashboard | apps | dashboard (ClusterRole) | dashboard |
| dashboard | apps | dashboard (Role) | dashboard |
| metrics | system | view | dashboard |
"""
    )
    candidate = parse_component_markdown_text(
        """# Component: Example

## Security
### RBAC - Role Bindings
| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| dashboard | apps | dashboard (Role) | dashboard |
| dashboard | Cluster-scoped | dashboard (ClusterRole) | dashboard |
| metrics | Cluster-scoped | view (ClusterRole) | dashboard |
"""
    )

    report = compare_component_documents(baseline, candidate)
    category = report.categories[0]

    assert category.matched_rows == 3
    assert category.missing_keys == []
    assert category.additional_keys == []


def test_known_platform_semantic_aliases_do_not_conflict():
    baseline = parse_component_markdown_text(
        """# Component: Example

## Integration Points
| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Perses | REST Proxy | 8080 | HTTP | None | Dashboards |

## Security
### RBAC - Role Bindings
| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| dashboard | applications namespace | view | dashboard |
"""
    )
    candidate = parse_component_markdown_text(
        """# Component: Example

## Integration Points
| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Perses Service | REST Proxy | 8080 | HTTP | None | Dashboards |

## Security
### RBAC - Role Bindings
| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| dashboard | redhat-ods-applications | view (ClusterRole) | dashboard |
"""
    )

    report = compare_component_documents(baseline, candidate)

    assert report.matched_rows == 2
    assert report.conflict_count == 0


def test_rhoai_next_kueue_is_a_valid_baseline_fixture():
    path = PROJECT_ROOT / "architecture" / "rhoai.next" / "kueue.md"
    document = parse_component_markdown(path)

    assert set(REQUIRED_H2_SECTIONS).issubset(document.h2_sections)
    assert len(document.tables) >= 20

    report = compare_component_documents(document, document)
    assert report.row_recall == 1.0
    assert report.conflict_count == 0
    assert report.baseline_rows >= 50

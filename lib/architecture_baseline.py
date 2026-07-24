"""Parse and compare generated component architecture Markdown documents."""

from __future__ import annotations

import json
import re
from collections.abc import Iterable
from dataclasses import asdict, dataclass, field
from pathlib import Path

_HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
_TABLE_SEPARATOR_RE = re.compile(r"^:?-{3,}:?$")
_WHITESPACE_RE = re.compile(r"\s+")
_MARKDOWN_LINK_RE = re.compile(r"\[([^]]+)]\([^)]+\)")
_PLACEHOLDERS = {
    "",
    "-",
    "--",
    "---",
    "n/a",
    "none",
    "none identified",
    "no dependencies identified",
    "no internal dependencies identified",
    "not applicable",
    "pending",
    "unknown",
}


REQUIRED_H2_SECTIONS = (
    "Metadata",
    "Purpose",
    "Architecture Components",
    "APIs Exposed",
    "Dependencies",
    "Network Architecture",
    "Security",
    "Data Flows",
    "Integration Points",
    "Recent Changes",
    "Source References",
)

SYNTHESIS_SECTIONS = (
    "Purpose",
    "Data Flows",
    "Architectural Analysis",
)

NON_ARCHITECTURE_CATEGORIES = frozenset(
    {"recent_changes", "source_files", "source_searches"}
)


@dataclass(frozen=True)
class MarkdownTable:
    """A Markdown table associated with its enclosing heading path."""

    section_path: tuple[str, ...]
    headers: tuple[str, ...]
    rows: tuple[tuple[str, ...], ...]
    start_line: int

    @property
    def section(self) -> str:
        return self.section_path[-1] if self.section_path else ""


@dataclass
class ComponentDocument:
    """Normalized structural representation of a component document."""

    path: str
    title: str = ""
    headings: list[tuple[int, str]] = field(default_factory=list)
    section_text: dict[tuple[str, ...], str] = field(default_factory=dict)
    tables: list[MarkdownTable] = field(default_factory=list)

    @property
    def h2_sections(self) -> tuple[str, ...]:
        return tuple(title for level, title in self.headings if level == 2)


@dataclass(frozen=True)
class CellConflict:
    category: str
    key: tuple[str, ...]
    column: str
    baseline: str
    candidate: str


@dataclass
class CategoryComparison:
    category: str
    baseline_rows: int
    candidate_rows: int
    matched_rows: int
    missing_keys: list[tuple[str, ...]] = field(default_factory=list)
    additional_keys: list[tuple[str, ...]] = field(default_factory=list)
    conflicts: list[CellConflict] = field(default_factory=list)

    @property
    def row_recall(self) -> float:
        if self.baseline_rows == 0:
            return 1.0
        return self.matched_rows / self.baseline_rows


@dataclass(frozen=True)
class UnmappedTable:
    """Candidate table that does not yet map to a baseline fact category."""

    section_path: tuple[str, ...]
    headers: tuple[str, ...]
    row_count: int


@dataclass
class ComparisonReport:
    baseline: str
    candidate: str
    missing_required_sections: list[str]
    missing_synthesis_sections: list[str]
    categories: list[CategoryComparison]
    unmapped_candidate_tables: list[UnmappedTable]

    @property
    def baseline_rows(self) -> int:
        return sum(category.baseline_rows for category in self.categories)

    @property
    def matched_rows(self) -> int:
        return sum(category.matched_rows for category in self.categories)

    @property
    def row_recall(self) -> float:
        if self.baseline_rows == 0:
            return 1.0
        return self.matched_rows / self.baseline_rows

    @property
    def conflict_count(self) -> int:
        return sum(len(category.conflicts) for category in self.categories)

    @property
    def structured_baseline_rows(self) -> int:
        return sum(
            category.baseline_rows
            for category in self.categories
            if category.category not in NON_ARCHITECTURE_CATEGORIES
        )

    @property
    def structured_matched_rows(self) -> int:
        return sum(
            category.matched_rows
            for category in self.categories
            if category.category not in NON_ARCHITECTURE_CATEGORIES
        )

    @property
    def structured_row_recall(self) -> float:
        if self.structured_baseline_rows == 0:
            return 1.0
        return self.structured_matched_rows / self.structured_baseline_rows

    @property
    def unmapped_candidate_rows(self) -> int:
        return sum(table.row_count for table in self.unmapped_candidate_tables)

    def to_dict(self) -> dict:
        data = asdict(self)
        data.update(
            {
                "baseline_rows": self.baseline_rows,
                "matched_rows": self.matched_rows,
                "row_recall": self.row_recall,
                "conflict_count": self.conflict_count,
                "structured_baseline_rows": self.structured_baseline_rows,
                "structured_matched_rows": self.structured_matched_rows,
                "structured_row_recall": self.structured_row_recall,
                "unmapped_candidate_rows": self.unmapped_candidate_rows,
            }
        )
        for category in data["categories"]:
            baseline_rows = category["baseline_rows"]
            category["row_recall"] = (
                category["matched_rows"] / baseline_rows if baseline_rows else 1.0
            )
        return data

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2)


@dataclass(frozen=True)
class _TableSpec:
    category: str
    sections: frozenset[str]
    keys: tuple[str, ...]
    columns: tuple[str, ...]
    aliases: dict[str, str]


def _normalize_text(value: str) -> str:
    value = _MARKDOWN_LINK_RE.sub(r"\1", value)
    value = value.replace("**", "").replace("__", "")
    value = value.replace("`", "")
    value = value.replace("—", "-").replace("–", "-").replace("→", " to ")
    return _WHITESPACE_RE.sub(" ", value).strip().casefold()


def _normalize_header(value: str) -> str:
    value = _normalize_text(value)
    return re.sub(r"[^a-z0-9]+", "_", value).strip("_")


def _normalize_section(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", value.casefold()).strip()


def _aliases(**values: str) -> dict[str, str]:
    return {_normalize_header(source): target for source, target in values.items()}


_TABLE_SPECS = (
    _TableSpec(
        "architecture_components",
        frozenset({"architecture components"}),
        ("component",),
        ("component", "type", "purpose"),
        _aliases(component="component", type="type", purpose="purpose"),
    ),
    _TableSpec(
        "crds",
        frozenset({"custom resource definitions crds", "crds"}),
        ("group", "version", "kind"),
        ("group", "version", "kind", "scope"),
        _aliases(group="group", version="version", kind="kind", scope="scope"),
    ),
    _TableSpec(
        "http_endpoints",
        frozenset({"http endpoints"}),
        ("method", "path"),
        ("method", "path", "port", "protocol", "encryption", "auth"),
        _aliases(
            method="method",
            path="path",
            port="port",
            protocol="protocol",
            encryption="encryption",
            auth="auth",
        ),
    ),
    _TableSpec(
        "grpc_services",
        frozenset({"grpc services"}),
        ("service",),
        ("service", "port", "protocol", "encryption", "auth"),
        _aliases(
            service="service",
            port="port",
            protocol="protocol",
            encryption="encryption",
            auth="auth",
        ),
    ),
    _TableSpec(
        "external_dependencies",
        frozenset({"external dependencies"}),
        ("component",),
        ("component", "version", "required"),
        _aliases(component="component", version="version", required="required"),
    ),
    _TableSpec(
        "internal_dependencies",
        frozenset({"internal platform dependencies"}),
        ("component",),
        ("component", "interaction_type"),
        _aliases(component="component", interaction_type="interaction_type"),
    ),
    _TableSpec(
        "services",
        frozenset({"services"}),
        ("service_name",),
        ("service_name", "type", "port", "protocol"),
        _aliases(
            service_name="service_name",
            name="service_name",
            type="type",
            port="port",
            ports="port",
            protocol="protocol",
        ),
    ),
    _TableSpec(
        "ingress",
        frozenset({"ingress", "ingress routing"}),
        ("name",),
        ("name", "type", "hosts", "port", "protocol", "encryption"),
        _aliases(
            name="name",
            type="type",
            kind="type",
            hosts="hosts",
            host="hosts",
            port="port",
            protocol="protocol",
            encryption="encryption",
        ),
    ),
    _TableSpec(
        "egress",
        frozenset({"egress"}),
        ("destination",),
        ("destination", "port", "protocol", "encryption", "auth"),
        _aliases(
            destination="destination",
            port="port",
            protocol="protocol",
            encryption="encryption",
            auth="auth",
        ),
    ),
    _TableSpec(
        "rbac_cluster_roles",
        frozenset({"rbac cluster roles", "cluster roles"}),
        ("role_name", "api_group", "resources"),
        ("role_name", "api_group", "resources", "verbs"),
        _aliases(
            role_name="role_name",
            name="role_name",
            api_group="api_group",
            resources="resources",
            verbs="verbs",
        ),
    ),
    _TableSpec(
        "rbac_role_bindings",
        frozenset({"rbac role bindings", "role bindings", "cluster role bindings"}),
        ("binding_name", "role"),
        ("binding_name", "namespace", "role", "service_account"),
        _aliases(
            binding_name="binding_name",
            name="binding_name",
            namespace="namespace",
            role="role",
            role_ref="role",
            service_account="service_account",
            subjects="service_account",
        ),
    ),
    _TableSpec(
        "secrets",
        frozenset({"secrets", "secrets referenced"}),
        ("secret_name",),
        ("secret_name", "type"),
        _aliases(secret_name="secret_name", name="secret_name", type="type"),
    ),
    _TableSpec(
        "authentication",
        frozenset({"authentication authorization"}),
        ("endpoint", "methods"),
        ("endpoint", "methods", "auth_mechanism"),
        _aliases(
            endpoint="endpoint",
            methods="methods",
            auth_mechanism="auth_mechanism",
        ),
    ),
    _TableSpec(
        "integration_points",
        frozenset({"integration points"}),
        ("component", "interaction_type"),
        ("component", "interaction_type", "port", "protocol", "encryption"),
        _aliases(
            component="component",
            interaction_type="interaction_type",
            port="port",
            protocol="protocol",
            encryption="encryption",
        ),
    ),
    _TableSpec(
        "recent_changes",
        frozenset({"recent changes"}),
        ("version", "date"),
        ("version", "date"),
        _aliases(version="version", date="date"),
    ),
    _TableSpec(
        "source_files",
        frozenset({"files analyzed"}),
        ("file",),
        ("file", "lines"),
        _aliases(file="file", lines="lines"),
    ),
    _TableSpec(
        "source_searches",
        frozenset({"grep search results used"}),
        ("search_pattern",),
        ("search_pattern", "files_matched", "sections_informed"),
        _aliases(
            search_pattern="search_pattern",
            files_matched="files_matched",
            sections_informed="sections_informed",
        ),
    ),
)


def parse_component_markdown(path: str | Path) -> ComponentDocument:
    """Parse headings, section prose, and tables from a Markdown document."""

    source = Path(path)
    return parse_component_markdown_text(source.read_text(), path=str(source))


def parse_component_markdown_text(
    text: str,
    *,
    path: str = "<memory>",
) -> ComponentDocument:
    """Parse component Markdown supplied as a string."""

    document = ComponentDocument(path=path)
    lines = text.splitlines()
    heading_stack: list[str] = []
    section_lines: dict[tuple[str, ...], list[str]] = {}
    current_path: tuple[str, ...] = ()
    index = 0

    while index < len(lines):
        line = lines[index]
        heading = _HEADING_RE.match(line)
        if heading:
            level = len(heading.group(1))
            title = heading.group(2).strip()
            document.headings.append((level, title))
            if level == 1 and not document.title:
                document.title = title
            if level >= 2:
                depth = level - 1
                heading_stack = heading_stack[: depth - 1]
                heading_stack.append(title)
                current_path = tuple(heading_stack)
                section_lines.setdefault(current_path, [])
            index += 1
            continue

        if _starts_table(lines, index):
            headers = tuple(_split_table_row(lines[index]))
            rows: list[tuple[str, ...]] = []
            start_line = index + 1
            index += 2
            while index < len(lines) and _is_table_row(lines[index]):
                row = _split_table_row(lines[index])
                row.extend([""] * (len(headers) - len(row)))
                rows.append(tuple(row[: len(headers)]))
                index += 1
            document.tables.append(
                MarkdownTable(
                    section_path=current_path,
                    headers=headers,
                    rows=tuple(rows),
                    start_line=start_line,
                )
            )
            continue

        if current_path:
            section_lines.setdefault(current_path, []).append(line)
        index += 1

    document.section_text = {
        section: "\n".join(content).strip()
        for section, content in section_lines.items()
    }
    return document


def compare_component_documents(
    baseline: ComponentDocument,
    candidate: ComponentDocument,
) -> ComparisonReport:
    """Compare stable table facts and required document surface."""

    candidate_h2 = set(candidate.h2_sections)
    missing_required = [
        section for section in REQUIRED_H2_SECTIONS if section not in candidate_h2
    ]
    candidate_sections = {title.casefold() for _, title in candidate.headings}
    missing_synthesis = [
        section
        for section in SYNTHESIS_SECTIONS
        if section.casefold() not in candidate_sections
    ]

    baseline_tables = _tables_by_category(baseline.tables)
    candidate_tables = _tables_by_category(candidate.tables)
    categories = []
    for spec in _TABLE_SPECS:
        baseline_rows = _canonical_rows(baseline_tables.get(spec.category, ()), spec)
        if not baseline_rows:
            continue
        candidate_rows = _canonical_rows(candidate_tables.get(spec.category, ()), spec)
        categories.append(_compare_category(spec, baseline_rows, candidate_rows))

    return ComparisonReport(
        baseline=baseline.path,
        candidate=candidate.path,
        missing_required_sections=missing_required,
        missing_synthesis_sections=missing_synthesis,
        categories=categories,
        unmapped_candidate_tables=_unmapped_tables(candidate.tables),
    )


def format_comparison_report(report: ComparisonReport) -> str:
    """Render a concise human-readable comparison report."""

    lines = [
        "Component architecture baseline comparison",
        f"Baseline:  {report.baseline}",
        f"Candidate: {report.candidate}",
        "",
        (
            f"Stable row recall: {report.matched_rows}/{report.baseline_rows} "
            f"({report.row_recall:.1%})"
        ),
        (
            "Structured row recall: "
            f"{report.structured_matched_rows}/{report.structured_baseline_rows} "
            f"({report.structured_row_recall:.1%})"
        ),
        f"Cell conflicts: {report.conflict_count}",
        f"Missing required sections: {len(report.missing_required_sections)}",
        f"Missing synthesis sections: {len(report.missing_synthesis_sections)}",
        (
            "Unmapped candidate tables: "
            f"{len(report.unmapped_candidate_tables)} "
            f"({report.unmapped_candidate_rows} rows)"
        ),
        "",
    ]
    if report.missing_required_sections:
        lines.append(
            "Required sections absent: " + ", ".join(report.missing_required_sections)
        )
    if report.missing_synthesis_sections:
        lines.append(
            "Synthesis sections absent: " + ", ".join(report.missing_synthesis_sections)
        )
    if report.missing_required_sections or report.missing_synthesis_sections:
        lines.append("")

    lines.extend(
        [
            "Category                    Baseline Candidate Matched Recall Conflicts",
            "--------------------------  -------- --------- ------- ------ ---------",
        ]
    )
    for category in report.categories:
        lines.append(
            f"{category.category:29}  {category.baseline_rows:8d}  "
            f"{category.candidate_rows:9d}  {category.matched_rows:7d}  "
            f"{category.row_recall:6.1%}  {len(category.conflicts):9d}"
        )

    missing = [item for item in report.categories if item.missing_keys]
    additional = [item for item in report.categories if item.additional_keys]
    conflicts = [item for item in report.categories if item.conflicts]
    if missing:
        lines.extend(["", "Missing baseline rows:"])
        for category in missing:
            for key in category.missing_keys[:20]:
                lines.append(f"- {category.category}: {' | '.join(key)}")
            if len(category.missing_keys) > 20:
                lines.append(
                    f"- {category.category}: ... {len(category.missing_keys) - 20} more"
                )
    if additional:
        lines.extend(["", "Additional candidate rows:"])
        for category in additional:
            for key in category.additional_keys[:20]:
                lines.append(f"- {category.category}: {' | '.join(key)}")
            if len(category.additional_keys) > 20:
                lines.append(
                    f"- {category.category}: ... "
                    f"{len(category.additional_keys) - 20} more"
                )
    if conflicts:
        lines.extend(["", "Conflicting source-backed cells:"])
        shown = 0
        for category in conflicts:
            for conflict in category.conflicts:
                lines.append(
                    f"- {conflict.category} {' | '.join(conflict.key)} "
                    f"[{conflict.column}]: baseline={conflict.baseline!r}, "
                    f"candidate={conflict.candidate!r}"
                )
                shown += 1
                if shown >= 30:
                    lines.append("- ... additional conflicts omitted")
                    return "\n".join(lines) + "\n"
    if report.unmapped_candidate_tables:
        lines.extend(["", "Unmapped candidate tables:"])
        for table in report.unmapped_candidate_tables:
            section = " / ".join(table.section_path) or "<document root>"
            headers = ", ".join(table.headers)
            lines.append(f"- {section}: {table.row_count} rows [{headers}]")
    return "\n".join(lines) + "\n"


def _starts_table(lines: list[str], index: int) -> bool:
    if index + 1 >= len(lines) or not _is_table_row(lines[index]):
        return False
    separators = _split_table_row(lines[index + 1])
    return bool(separators) and all(
        _TABLE_SEPARATOR_RE.match(cell.strip()) for cell in separators
    )


def _is_table_row(line: str) -> bool:
    return line.strip().startswith("|") and line.strip().endswith("|")


def _split_table_row(line: str) -> list[str]:
    stripped = line.strip()
    if stripped.startswith("|"):
        stripped = stripped[1:]
    if stripped.endswith("|"):
        stripped = stripped[:-1]

    cells: list[str] = []
    current: list[str] = []
    escaped = False
    code_delimiter = 0
    index = 0
    while index < len(stripped):
        char = stripped[index]
        if escaped:
            current.append(char)
            escaped = False
        elif char == "\\":
            current.append(char)
            escaped = True
        elif char == "`":
            run = 1
            while index + run < len(stripped) and stripped[index + run] == "`":
                run += 1
            current.extend("`" * run)
            code_delimiter = 0 if code_delimiter == run else run
            index += run - 1
        elif char == "|" and code_delimiter == 0:
            cells.append("".join(current).strip())
            current = []
        else:
            current.append(char)
        index += 1
    cells.append("".join(current).strip())
    return cells


def _meaningful(value: str) -> bool:
    return _normalize_text(value) not in _PLACEHOLDERS


def _tables_by_category(
    tables: Iterable[MarkdownTable],
) -> dict[str, list[MarkdownTable]]:
    result: dict[str, list[MarkdownTable]] = {}
    for table in tables:
        section = _normalize_section(table.section)
        for spec in _TABLE_SPECS:
            if section in spec.sections:
                result.setdefault(spec.category, []).append(table)
                break
    return result


def _unmapped_tables(tables: Iterable[MarkdownTable]) -> list[UnmappedTable]:
    mapped_sections = {
        section for spec in _TABLE_SPECS for section in spec.sections
    }
    return [
        UnmappedTable(
            section_path=table.section_path,
            headers=table.headers,
            row_count=len(table.rows),
        )
        for table in tables
        if table.rows and _normalize_section(table.section) not in mapped_sections
    ]


def _canonical_rows(
    tables: Iterable[MarkdownTable],
    spec: _TableSpec,
) -> dict[tuple[str, ...], dict[str, str]]:
    result: dict[tuple[str, ...], dict[str, str]] = {}
    for table in tables:
        mapped_headers = [
            spec.aliases.get(_normalize_header(header), "") for header in table.headers
        ]
        for raw_row in table.rows:
            row = {
                mapped: raw_row[index]
                for index, mapped in enumerate(mapped_headers)
                if mapped and index < len(raw_row)
            }
            key = tuple(
                _normalize_key_value(spec.category, column, row.get(column, ""))
                for column in spec.keys
            )
            if (
                not all(key)
                or not all(_meaningful(value) for value in key)
                or not any(_meaningful(value) for value in row.values())
            ):
                continue
            result[key] = row
    return result


_KEY_ALIASES = {
    (
        "architecture_components",
        "component",
        "epp endpoint picker process",
    ): "endpoint picker (epp)",
    (
        "architecture_components",
        "component",
        "epp (endpoint picker process)",
    ): "endpoint picker (epp)",
    (
        "internal_dependencies",
        "component",
        "gateway api inferencepool",
    ): "gateway-api-inference-extension",
    (
        "internal_dependencies",
        "component",
        "model server endpoints (vllm)",
    ): "model-serving endpoints",
    (
        "internal_dependencies",
        "component",
        "model-serving endpoints (vllm)",
    ): "model-serving endpoints",
    ("authentication", "endpoint", "ext-proc grpc"): "external processor grpc",
    ("authentication", "endpoint", "extproc grpc"): "external processor grpc",
    ("authentication", "methods", "grpc streaming"): "grpc",
    ("internal_dependencies", "component", "perses service"): "perses",
    ("integration_points", "component", "perses service"): "perses",
    (
        "integration_points",
        "component",
        "datascience pipelines api",
    ): "datascience pipelines",
}


def _normalize_key_value(category: str, column: str, value: str) -> str:
    normalized = _normalize_text(value)
    if category == "rbac_cluster_roles" and column == "api_group":
        if normalized in {"", '""'}:
            return "<core>"
    if category == "rbac_cluster_roles" and column in {"api_group", "resources"}:
        items = sorted(item.strip() for item in normalized.split(",") if item.strip())
        return ", ".join(items)
    return _KEY_ALIASES.get((category, column, normalized), normalized)


def _normalize_row_key(category: str, values: Iterable[str]) -> tuple[str, ...]:
    """Normalize a persisted row key using the current canonical identity rules."""
    key = tuple(str(value) for value in values)
    spec = next((item for item in _TABLE_SPECS if item.category == category), None)
    if spec is None or len(key) != len(spec.keys):
        return key
    return tuple(
        _normalize_key_value(category, column, value)
        for column, value in zip(spec.keys, key, strict=True)
    )


def _compare_category(
    spec: _TableSpec,
    baseline: dict[tuple[str, ...], dict[str, str]],
    candidate: dict[tuple[str, ...], dict[str, str]],
) -> CategoryComparison:
    if spec.category == "rbac_role_bindings":
        return _compare_role_bindings(spec, baseline, candidate)
    baseline_keys = set(baseline)
    candidate_keys = set(candidate)
    shared_keys = baseline_keys & candidate_keys
    conflicts: list[CellConflict] = []
    for key in sorted(shared_keys):
        baseline_row = baseline[key]
        candidate_row = candidate[key]
        if spec.category in NON_ARCHITECTURE_CATEGORIES:
            continue
        for column in spec.columns:
            left = baseline_row.get(column, "")
            right = candidate_row.get(column, "")
            if not _meaningful(left) or not _meaningful(right):
                continue
            if not _values_equivalent(left, right):
                conflicts.append(
                    CellConflict(
                        category=spec.category,
                        key=key,
                        column=column,
                        baseline=left,
                        candidate=right,
                    )
                )
    return CategoryComparison(
        category=spec.category,
        baseline_rows=len(baseline),
        candidate_rows=len(candidate),
        matched_rows=len(shared_keys),
        missing_keys=sorted(baseline_keys - candidate_keys),
        additional_keys=sorted(candidate_keys - baseline_keys),
        conflicts=conflicts,
    )


def _compare_role_bindings(
    spec: _TableSpec,
    baseline: dict[tuple[str, ...], dict[str, str]],
    candidate: dict[tuple[str, ...], dict[str, str]],
) -> CategoryComparison:
    matched: list[tuple[tuple[str, ...], tuple[str, ...]]] = []
    available = set(candidate)
    for baseline_key in sorted(baseline):
        candidate_key = next(
            (
                key
                for key in sorted(available)
                if _role_binding_keys_equivalent(baseline_key, key)
            ),
            None,
        )
        if candidate_key is None:
            continue
        matched.append((baseline_key, candidate_key))
        available.remove(candidate_key)

    conflicts: list[CellConflict] = []
    for baseline_key, candidate_key in matched:
        baseline_row = baseline[baseline_key]
        candidate_row = candidate[candidate_key]
        for column in spec.columns:
            left = baseline_row.get(column, "")
            right = candidate_row.get(column, "")
            if not _meaningful(left) or not _meaningful(right):
                continue
            if not _values_equivalent(left, right):
                conflicts.append(
                    CellConflict(
                        category=spec.category,
                        key=baseline_key,
                        column=column,
                        baseline=left,
                        candidate=right,
                    )
                )

    matched_baseline = {baseline_key for baseline_key, _ in matched}
    return CategoryComparison(
        category=spec.category,
        baseline_rows=len(baseline),
        candidate_rows=len(candidate),
        matched_rows=len(matched),
        missing_keys=sorted(set(baseline) - matched_baseline),
        additional_keys=sorted(available),
        conflicts=conflicts,
    )


_ROLE_KIND_RE = re.compile(r"\s+\((clusterrole|role)\)$")


def _role_binding_keys_equivalent(
    baseline: tuple[str, ...], candidate: tuple[str, ...]
) -> bool:
    if len(baseline) != 2 or len(candidate) != 2 or baseline[0] != candidate[0]:
        return False
    baseline_role, baseline_kind = _split_role_kind(baseline[1])
    candidate_role, candidate_kind = _split_role_kind(candidate[1])
    return baseline_role == candidate_role and (
        not baseline_kind or not candidate_kind or baseline_kind == candidate_kind
    )


def _split_role_kind(value: str) -> tuple[str, str]:
    match = _ROLE_KIND_RE.search(value)
    if not match:
        return value, ""
    return value[: match.start()], match.group(1)


def _values_equivalent(left: str, right: str) -> bool:
    normalized_left = _normalize_text(left)
    normalized_right = _normalize_text(right)
    if normalized_left == normalized_right:
        return True

    semantic_aliases = (
        {"applications namespace", "redhat-ods-applications"},
        {"perses", "perses service"},
        {"datascience pipelines", "datascience pipelines api"},
    )
    if {normalized_left, normalized_right} in semantic_aliases:
        return True

    if (
        normalized_left.startswith(normalized_right + " (")
        or normalized_right.startswith(normalized_left + " (")
    ):
        return True

    if (
        normalized_left.startswith("v0.0.0-")
        and normalized_right.startswith("v0.0.0-")
        and (
            normalized_left.startswith(normalized_right)
            or normalized_right.startswith(normalized_left)
        )
    ):
        return True

    left_items = {item.strip() for item in normalized_left.split(",")}
    right_items = {item.strip() for item in normalized_right.split(",")}
    if len(left_items) > 1 and left_items == right_items:
        return True

    left_ports = set(re.findall(r"\b\d{2,5}\b", normalized_left))
    right_ports = set(re.findall(r"\b\d{2,5}\b", normalized_right))
    if left_ports and right_ports and left_ports == right_ports:
        return True

    left_lines = _line_numbers(normalized_left)
    right_lines = _line_numbers(normalized_right)
    if left_lines is not None and right_lines is not None:
        return left_lines.issubset(right_lines) or right_lines.issubset(left_lines)
    return False


def _line_numbers(value: str) -> set[int] | None:
    if not re.fullmatch(r"\d+(?:\s*[-,]\s*\d+)*", value):
        return None
    result: set[int] = set()
    for item in value.split(","):
        item = item.strip()
        if "-" not in item:
            result.add(int(item))
            continue
        start, end = (int(part.strip()) for part in item.split("-", 1))
        if start > end:
            return None
        result.update(range(start, end + 1))
    return result

"""Bounded synthesis insight artifact model and deterministic validator."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from pathlib import Path

SCHEMA_VERSION = 1

INSIGHT_CATEGORIES = frozenset(
    {"pattern", "trade-off", "risk", "cross-component implication"}
)
CONFIDENCE_VALUES = frozenset({"high", "medium", "low"})
APPLICABILITY_VALUES = frozenset({"component", "platform", "cross-platform"})
PROVENANCE_KINDS = frozenset(
    {"analyzer-fact", "query-result", "overlay", "source-excerpt"}
)
VALIDATION_STATUSES = frozenset(
    {"pending", "confirmed", "rejected", "not-applicable", "unknown", "not-extracted"}
)

MAX_INSIGHTS_PER_ARTIFACT = 25
MAX_CLAIM_CHARS = 500
MAX_REASONING_CHARS = 2000
MAX_TOKEN_BUDGET = 200_000


@dataclass(frozen=True)
class ProvenanceReference:
    """A single cited input that supports an insight claim."""

    kind: str
    location: str
    excerpt: str = ""

    def validate(self) -> list[str]:
        errors: list[str] = []
        if not self.kind or self.kind not in PROVENANCE_KINDS:
            errors.append(
                f"provenance kind must be one of {sorted(PROVENANCE_KINDS)}, "
                f"got {self.kind!r}"
            )
        if not self.location or not self.location.strip():
            errors.append("provenance location must not be empty")
        return errors


@dataclass(frozen=True)
class Insight:
    """A single agent-derived architectural insight (non-authoritative)."""

    id: str
    claim: str
    category: str
    provenance: tuple[ProvenanceReference, ...]
    reasoning: str
    applicability: str
    confidence: str
    unknowns: tuple[str, ...] = ()
    counterevidence: tuple[str, ...] = ()
    suggested_validation: str = ""
    validation_status: str = "pending"

    def validate(self) -> list[str]:
        errors: list[str] = []
        if not self.id or not self.id.strip():
            errors.append("insight id must not be empty")
        if not self.claim or not self.claim.strip():
            errors.append("claim must not be empty")
        if len(self.claim) > MAX_CLAIM_CHARS:
            errors.append(
                f"claim exceeds {MAX_CLAIM_CHARS} characters "
                f"({len(self.claim)})"
            )
        if self.category not in INSIGHT_CATEGORIES:
            errors.append(
                f"category must be one of {sorted(INSIGHT_CATEGORIES)}, "
                f"got {self.category!r}"
            )
        if not self.provenance:
            errors.append("at least one provenance reference is required")
        for i, ref in enumerate(self.provenance):
            for err in ref.validate():
                errors.append(f"provenance[{i}]: {err}")
        if not self.reasoning or not self.reasoning.strip():
            errors.append("reasoning must not be empty")
        if len(self.reasoning) > MAX_REASONING_CHARS:
            errors.append(
                f"reasoning exceeds {MAX_REASONING_CHARS} characters "
                f"({len(self.reasoning)})"
            )
        if self.applicability not in APPLICABILITY_VALUES:
            errors.append(
                f"applicability must be one of {sorted(APPLICABILITY_VALUES)}, "
                f"got {self.applicability!r}"
            )
        if self.confidence not in CONFIDENCE_VALUES:
            errors.append(
                f"confidence must be one of {sorted(CONFIDENCE_VALUES)}, "
                f"got {self.confidence!r}"
            )
        if self.validation_status not in VALIDATION_STATUSES:
            errors.append(
                f"validation_status must be one of "
                f"{sorted(VALIDATION_STATUSES)}, "
                f"got {self.validation_status!r}"
            )
        return errors

    def sort_key(self) -> tuple[int, int, str]:
        category_order = ["pattern", "trade-off", "risk", "cross-component implication"]
        confidence_order = ["high", "medium", "low"]
        return (
            category_order.index(self.category)
            if self.category in INSIGHT_CATEGORIES
            else len(category_order),
            confidence_order.index(self.confidence)
            if self.confidence in CONFIDENCE_VALUES
            else len(confidence_order),
            self.id,
        )


@dataclass
class InsightArtifact:
    """A bounded, versioned collection of agent-derived insights."""

    schema_version: int
    component: str
    platform: str
    version: str
    insights: list[Insight] = field(default_factory=list)
    metadata: dict[str, object] = field(default_factory=dict)
    token_budget: int | None = None
    token_count: int | None = None

    def validate(self) -> list[str]:
        errors: list[str] = []
        if self.schema_version != SCHEMA_VERSION:
            errors.append(
                f"unsupported schema_version {self.schema_version}, "
                f"expected {SCHEMA_VERSION}"
            )
        if not self.component or not self.component.strip():
            errors.append("component must not be empty")
        if not self.platform or not self.platform.strip():
            errors.append("platform must not be empty")
        if not self.version or not self.version.strip():
            errors.append("version must not be empty")
        if len(self.insights) > MAX_INSIGHTS_PER_ARTIFACT:
            errors.append(
                f"insight count {len(self.insights)} exceeds maximum "
                f"{MAX_INSIGHTS_PER_ARTIFACT}"
            )
        errors.extend(self._validate_token_metadata())
        seen_ids: set[str] = set()
        for i, insight in enumerate(self.insights):
            for err in insight.validate():
                errors.append(f"insights[{i}]: {err}")
            if insight.id in seen_ids:
                errors.append(f"insights[{i}]: duplicate id {insight.id!r}")
            seen_ids.add(insight.id)
        return errors

    def _validate_token_metadata(self) -> list[str]:
        errors: list[str] = []
        if self.token_budget is not None:
            if not isinstance(self.token_budget, int) or self.token_budget < 1:
                errors.append("token_budget must be a positive integer")
            elif self.token_budget > MAX_TOKEN_BUDGET:
                errors.append(
                    f"token_budget {self.token_budget} exceeds maximum "
                    f"{MAX_TOKEN_BUDGET}"
                )
        if self.token_count is not None:
            if not isinstance(self.token_count, int) or self.token_count < 0:
                errors.append("token_count must be a non-negative integer")
            elif (
                self.token_budget is not None
                and isinstance(self.token_budget, int)
                and self.token_budget >= 1
                and self.token_count > self.token_budget
            ):
                errors.append(
                    f"token_count {self.token_count} exceeds "
                    f"token_budget {self.token_budget}"
                )
        return errors

    def sorted_insights(self) -> list[Insight]:
        return sorted(self.insights, key=lambda i: i.sort_key())

    def to_dict(self) -> dict[str, object]:
        result = asdict(self)
        result["insights"] = [asdict(i) for i in self.sorted_insights()]
        for insight_dict in result["insights"]:
            insight_dict["provenance"] = [
                dict(ref) for ref in insight_dict["provenance"]
            ]
        if self.token_budget is None:
            result.pop("token_budget", None)
        if self.token_count is None:
            result.pop("token_count", None)
        return result

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2, sort_keys=False) + "\n"


def validate_insight_artifact(data: dict) -> list[str]:
    """Validate a raw dict/JSON against the insight artifact contract."""
    errors: list[str] = []
    if not isinstance(data, dict):
        return ["artifact must be a JSON object"]

    schema_version = data.get("schema_version")
    if schema_version != SCHEMA_VERSION:
        errors.append(
            f"unsupported schema_version {schema_version!r}, "
            f"expected {SCHEMA_VERSION}"
        )

    for required in ("component", "platform", "version"):
        val = data.get(required)
        if not val or not isinstance(val, str) or not val.strip():
            errors.append(f"{required} must be a non-empty string")

    raw_insights = data.get("insights")
    if not isinstance(raw_insights, list):
        errors.append("insights must be a list")
        return errors

    if len(raw_insights) > MAX_INSIGHTS_PER_ARTIFACT:
        errors.append(
            f"insight count {len(raw_insights)} exceeds maximum "
            f"{MAX_INSIGHTS_PER_ARTIFACT}"
        )

    errors.extend(_validate_raw_token_metadata(data))

    seen_ids: set[str] = set()
    for i, raw in enumerate(raw_insights):
        if not isinstance(raw, dict):
            errors.append(f"insights[{i}]: must be a JSON object")
            continue
        for err in _validate_raw_insight(raw):
            errors.append(f"insights[{i}]: {err}")
        raw_id = raw.get("id", "")
        if raw_id in seen_ids:
            errors.append(f"insights[{i}]: duplicate id {raw_id!r}")
        seen_ids.add(raw_id)

    return errors


def _validate_raw_token_metadata(data: dict) -> list[str]:
    errors: list[str] = []
    token_budget = data.get("token_budget")
    token_count = data.get("token_count")

    if token_budget is not None:
        if not isinstance(token_budget, int) or token_budget < 1:
            errors.append("token_budget must be a positive integer")
        elif token_budget > MAX_TOKEN_BUDGET:
            errors.append(
                f"token_budget {token_budget} exceeds maximum "
                f"{MAX_TOKEN_BUDGET}"
            )

    if token_count is not None:
        if not isinstance(token_count, int) or token_count < 0:
            errors.append("token_count must be a non-negative integer")
        elif (
            token_budget is not None
            and isinstance(token_budget, int)
            and token_budget >= 1
            and token_count > token_budget
        ):
            errors.append(
                f"token_count {token_count} exceeds "
                f"token_budget {token_budget}"
            )

    return errors


def _validate_raw_insight(data: dict) -> list[str]:
    errors: list[str] = []

    for required in ("id", "claim", "reasoning"):
        val = data.get(required)
        if not val or not isinstance(val, str) or not val.strip():
            errors.append(f"{required} must be a non-empty string")

    claim = data.get("claim", "")
    if isinstance(claim, str) and len(claim) > MAX_CLAIM_CHARS:
        errors.append(
            f"claim exceeds {MAX_CLAIM_CHARS} characters ({len(claim)})"
        )

    reasoning = data.get("reasoning", "")
    if isinstance(reasoning, str) and len(reasoning) > MAX_REASONING_CHARS:
        errors.append(
            f"reasoning exceeds {MAX_REASONING_CHARS} characters "
            f"({len(reasoning)})"
        )

    category = data.get("category", "")
    if category not in INSIGHT_CATEGORIES:
        errors.append(
            f"category must be one of {sorted(INSIGHT_CATEGORIES)}, "
            f"got {category!r}"
        )

    applicability = data.get("applicability", "")
    if applicability not in APPLICABILITY_VALUES:
        errors.append(
            f"applicability must be one of {sorted(APPLICABILITY_VALUES)}, "
            f"got {applicability!r}"
        )

    confidence = data.get("confidence", "")
    if confidence not in CONFIDENCE_VALUES:
        errors.append(
            f"confidence must be one of {sorted(CONFIDENCE_VALUES)}, "
            f"got {confidence!r}"
        )

    validation_status = data.get("validation_status", "pending")
    if validation_status not in VALIDATION_STATUSES:
        errors.append(
            f"validation_status must be one of "
            f"{sorted(VALIDATION_STATUSES)}, "
            f"got {validation_status!r}"
        )

    provenance = data.get("provenance")
    if not isinstance(provenance, list) or not provenance:
        errors.append("at least one provenance reference is required")
    elif isinstance(provenance, list):
        for j, ref in enumerate(provenance):
            if not isinstance(ref, dict):
                errors.append(f"provenance[{j}]: must be a JSON object")
                continue
            kind = ref.get("kind", "")
            if kind not in PROVENANCE_KINDS:
                errors.append(
                    f"provenance[{j}]: kind must be one of "
                    f"{sorted(PROVENANCE_KINDS)}, got {kind!r}"
                )
            loc = ref.get("location", "")
            if not loc or not isinstance(loc, str) or not loc.strip():
                errors.append(
                    f"provenance[{j}]: location must be a non-empty string"
                )

    return errors


def load_insight_artifact(path: Path) -> tuple[InsightArtifact | None, list[str]]:
    """Load and validate an insight artifact from a JSON file."""
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        return None, [f"failed to load {path}: {exc}"]

    errors = validate_insight_artifact(data)
    if errors:
        return None, errors

    insights = [
        Insight(
            id=raw["id"],
            claim=raw["claim"],
            category=raw["category"],
            provenance=tuple(
                ProvenanceReference(
                    kind=ref["kind"],
                    location=ref["location"],
                    excerpt=ref.get("excerpt", ""),
                )
                for ref in raw["provenance"]
            ),
            reasoning=raw["reasoning"],
            applicability=raw["applicability"],
            confidence=raw["confidence"],
            unknowns=tuple(raw.get("unknowns") or ()),
            counterevidence=tuple(raw.get("counterevidence") or ()),
            suggested_validation=raw.get("suggested_validation", ""),
            validation_status=raw.get("validation_status", "pending"),
        )
        for raw in data["insights"]
    ]

    artifact = InsightArtifact(
        schema_version=data["schema_version"],
        component=data["component"],
        platform=data["platform"],
        version=data["version"],
        insights=insights,
        metadata=data.get("metadata") or {},
        token_budget=data.get("token_budget"),
        token_count=data.get("token_count"),
    )
    return artifact, []


INSIGHT_JSON_SCHEMA: dict = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "title": "InsightArtifact",
    "description": (
        "Bounded, non-authoritative agent-derived architectural insights. "
        "Version 1."
    ),
    "type": "object",
    "required": [
        "schema_version",
        "component",
        "platform",
        "version",
        "insights",
    ],
    "additionalProperties": True,
    "properties": {
        "schema_version": {"type": "integer", "const": SCHEMA_VERSION},
        "component": {"type": "string", "minLength": 1},
        "platform": {"type": "string", "minLength": 1},
        "version": {"type": "string", "minLength": 1},
        "metadata": {"type": "object"},
        "token_budget": {
            "type": "integer",
            "minimum": 1,
            "maximum": MAX_TOKEN_BUDGET,
        },
        "token_count": {
            "type": "integer",
            "minimum": 0,
            "maximum": MAX_TOKEN_BUDGET,
        },
        "insights": {
            "type": "array",
            "maxItems": MAX_INSIGHTS_PER_ARTIFACT,
            "items": {
                "type": "object",
                "required": [
                    "id",
                    "claim",
                    "category",
                    "provenance",
                    "reasoning",
                    "applicability",
                    "confidence",
                ],
                "additionalProperties": True,
                "properties": {
                    "id": {"type": "string", "minLength": 1},
                    "claim": {
                        "type": "string",
                        "minLength": 1,
                        "maxLength": MAX_CLAIM_CHARS,
                    },
                    "category": {
                        "type": "string",
                        "enum": sorted(INSIGHT_CATEGORIES),
                    },
                    "provenance": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                            "type": "object",
                            "required": ["kind", "location"],
                            "properties": {
                                "kind": {
                                    "type": "string",
                                    "enum": sorted(PROVENANCE_KINDS),
                                },
                                "location": {
                                    "type": "string",
                                    "minLength": 1,
                                },
                                "excerpt": {"type": "string"},
                            },
                        },
                    },
                    "reasoning": {
                        "type": "string",
                        "minLength": 1,
                        "maxLength": MAX_REASONING_CHARS,
                    },
                    "applicability": {
                        "type": "string",
                        "enum": sorted(APPLICABILITY_VALUES),
                    },
                    "confidence": {
                        "type": "string",
                        "enum": sorted(CONFIDENCE_VALUES),
                    },
                    "unknowns": {
                        "type": "array",
                        "items": {"type": "string"},
                    },
                    "counterevidence": {
                        "type": "array",
                        "items": {"type": "string"},
                    },
                    "suggested_validation": {"type": "string"},
                    "validation_status": {
                        "type": "string",
                        "enum": sorted(VALIDATION_STATUSES),
                        "default": "pending",
                    },
                },
            },
        },
    },
}

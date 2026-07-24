import json
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator, ValidationError

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = (
    PROJECT_ROOT
    / "src"
    / "arch-analyzer"
    / "schema"
    / "component-architecture.schema.json"
)


def schema() -> dict[str, object]:
    return json.loads(SCHEMA_PATH.read_text())


def complete_record() -> dict[str, object]:
    return {
        "status": "complete",
        "fact_count": 0,
        "discovery_contract": "authentication/v1",
        "completed_checks": ["runtime-inventory"],
        "limitations": [],
        "evidence": ["summary:no applicable authentication surfaces"],
    }


def test_schema_remains_compatible_with_legacy_json_without_coverage():
    validator = Draft202012Validator(schema())

    validator.validate({"component": "legacy-component"})


def test_schema_accepts_typed_category_coverage():
    validator = Draft202012Validator(schema())

    validator.validate(
        {
            "component": "covered-component",
            "category_coverage": {"authentication": complete_record()},
        }
    )


@pytest.mark.parametrize(
    "mutation",
    [
        lambda record: record.pop("limitations"),
        lambda record: record.update(status="assumed"),
        lambda record: record.update(fact_count=-1),
        lambda record: record.update(evidence=[""]),
    ],
)
def test_schema_rejects_malformed_category_coverage(mutation):
    record = complete_record()
    mutation(record)
    validator = Draft202012Validator(schema())

    with pytest.raises(ValidationError):
        validator.validate(
            {
                "component": "invalid-component",
                "category_coverage": {"authentication": record},
            }
        )

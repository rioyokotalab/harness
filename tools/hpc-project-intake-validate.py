#!/usr/bin/env python3
"""Validate an HPC project intake without third-party Python packages."""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path
from typing import Any


class ValidationError(Exception):
    pass


def load_unique(path: Path) -> Any:
    def unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in pairs:
            if key in result:
                raise ValidationError("duplicate object key")
            result[key] = value
        return result

    try:
        return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_object)
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValidationError("manifest is not readable JSON") from error


def type_matches(value: Any, expected: str) -> bool:
    return {
        "object": isinstance(value, dict),
        "array": isinstance(value, list),
        "string": isinstance(value, str),
        "integer": isinstance(value, int) and not isinstance(value, bool),
        "boolean": isinstance(value, bool),
    }.get(expected, False)


def validate(schema: dict[str, Any], value: Any, path: str = "$") -> None:
    expected = schema.get("type")
    if expected is not None and not type_matches(value, expected):
        raise ValidationError(f"{path}: wrong type")
    if "const" in schema and value != schema["const"]:
        raise ValidationError(f"{path}: wrong constant")
    if "enum" in schema and value not in schema["enum"]:
        raise ValidationError(f"{path}: value is outside the allowed set")

    if isinstance(value, dict):
        required = schema.get("required", [])
        missing = [key for key in required if key not in value]
        if missing:
            raise ValidationError(f"{path}: required field is missing")
        properties = schema.get("properties", {})
        if schema.get("additionalProperties") is False:
            unknown = set(value).difference(properties)
            if unknown:
                raise ValidationError(f"{path}: undeclared field is present")
        for key, child in value.items():
            if key in properties:
                validate(properties[key], child, f"{path}.{key}")

    if isinstance(value, list):
        if len(value) < schema.get("minItems", 0):
            raise ValidationError(f"{path}: too few items")
        if schema.get("uniqueItems"):
            canonical = [json.dumps(item, sort_keys=True, separators=(",", ":")) for item in value]
            if len(canonical) != len(set(canonical)):
                raise ValidationError(f"{path}: duplicate item")
        item_schema = schema.get("items")
        if item_schema is not None:
            for index, item in enumerate(value):
                validate(item_schema, item, f"{path}[{index}]")

    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            raise ValidationError(f"{path}: string is too short")
        pattern = schema.get("pattern")
        if pattern is not None and re.search(pattern, value) is None:
            raise ValidationError(f"{path}: string does not match the contract")

    if isinstance(value, int) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            raise ValidationError(f"{path}: integer is below the minimum")


def main(argv: list[str]) -> int:
    require_ready = False
    if len(argv) == 3 and argv[1] == "--require-ready":
        require_ready = True
        manifest = Path(argv[2])
    elif len(argv) == 2:
        manifest = Path(argv[1])
    else:
        print("Usage: hpc-project-intake-validate.py [--require-ready] MANIFEST", file=sys.stderr)
        return 2

    try:
        stat_result = manifest.lstat()
        if not manifest.is_file() or manifest.is_symlink():
            raise ValidationError("manifest must be a regular non-symlink file")
        if stat_result.st_size > 1024 * 1024:
            raise ValidationError("manifest exceeds the size limit")
        root = Path(__file__).resolve().parent.parent
        schema_path = root / "docs/schemas/hpc-project-intake.schema.json"
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        document = load_unique(manifest)
        validate(schema, document)
        if require_ready and document["status"] != "ready":
            raise ValidationError("manifest is not ready")
    except (OSError, UnicodeError, json.JSONDecodeError, ValidationError) as error:
        print(f"HPC_PROJECT_INTAKE status=fail reason={error}", file=sys.stderr)
        return 1

    print(
        "HPC_PROJECT_INTAKE"
        f" status=pass phase={document['status']}"
        f" targets={len(document['project']['target_hosts'])}"
        f" artifacts={len(document['environment']['artifacts'])}"
        f" libraries={len(document['software']['scientific_libraries'])}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

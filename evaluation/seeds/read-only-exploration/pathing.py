from pathlib import Path


def artifact_path(root: Path, user_value: str) -> Path:
    return root / user_value

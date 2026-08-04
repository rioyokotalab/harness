"""Discover and validate every repository-local skill."""

from __future__ import annotations

import os
import re
import subprocess
import sys
from collections.abc import Callable
from itertools import islice
from pathlib import Path

NAME = re.compile(r"[a-z0-9][a-z0-9-]{0,63}")
CLIENTS = (".agents", ".claude")
MAX_SKILLS = 64
MAX_DISCOVERY_ENTRIES = 128


class LocalSkillDiscoveryError(ValueError):
    """A stable, value-free discovery denial."""


def _default_validator(root: Path, skill: Path) -> None:
    result = subprocess.run(
        [sys.executable, str(root / "tools/validate-skill.py"), str(skill)],
        cwd=root,
        env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if result.returncode != 0:
        raise LocalSkillDiscoveryError("malformed-skill")


def discover_local_skills(
    root: Path,
    validator: Callable[[Path, Path], None] = _default_validator,
    declared_external_names: tuple[str, ...] = (),
) -> tuple[str, ...]:
    """Return sorted local skill names after exact structural validation."""
    if root.is_symlink() or not root.is_dir():
        raise LocalSkillDiscoveryError("root-invalid")
    skills = root / "skills"
    if skills.is_symlink() or not skills.is_dir():
        raise LocalSkillDiscoveryError("skills-root-invalid")
    try:
        observed = tuple(islice(skills.iterdir(), MAX_SKILLS + 1))
    except OSError as error:
        raise LocalSkillDiscoveryError("skills-root-invalid") from error
    if not observed or len(observed) > MAX_SKILLS:
        raise LocalSkillDiscoveryError("skill-count-invalid")
    entries = sorted(observed, key=lambda path: path.name)

    if (
        not isinstance(declared_external_names, tuple)
        or len(declared_external_names) > MAX_SKILLS
        or any(
            not isinstance(name, str) or NAME.fullmatch(name) is None
            for name in declared_external_names
        )
        or len(set(declared_external_names)) != len(declared_external_names)
    ):
        raise LocalSkillDiscoveryError("external-names-invalid")

    names: list[str] = []
    for skill in entries:
        if NAME.fullmatch(skill.name) is None:
            raise LocalSkillDiscoveryError("skill-name-invalid")
        if skill.is_symlink() or not skill.is_dir():
            raise LocalSkillDiscoveryError("skill-entry-invalid")
        skill_file = skill / "SKILL.md"
        if skill_file.is_symlink() or not skill_file.is_file():
            raise LocalSkillDiscoveryError("skill-file-invalid")
        names.append(skill.name)

    local_names = set(names)
    external_names = set(declared_external_names)
    if local_names & external_names:
        raise LocalSkillDiscoveryError("discovery-name-conflict")
    expected_names = local_names | external_names
    for client in CLIENTS:
        discovery = root / client / "skills"
        if discovery.is_symlink() or not discovery.is_dir():
            raise LocalSkillDiscoveryError("discovery-root-invalid")
        try:
            links = tuple(islice(discovery.iterdir(), MAX_DISCOVERY_ENTRIES + 1))
        except OSError as error:
            raise LocalSkillDiscoveryError("discovery-root-invalid") from error
        if len(links) > MAX_DISCOVERY_ENTRIES:
            raise LocalSkillDiscoveryError("discovery-count-invalid")
        observed_names = {link.name for link in links}
        if expected_names - observed_names:
            raise LocalSkillDiscoveryError("local-link-missing")
        if observed_names - expected_names:
            raise LocalSkillDiscoveryError("local-link-extra")
        if any(not link.is_symlink() for link in links):
            raise LocalSkillDiscoveryError("discovery-entry-invalid")

    for skill in entries:
        try:
            skill_root = skill.resolve(strict=True)
        except OSError as error:
            raise LocalSkillDiscoveryError("skill-entry-invalid") from error
        for client in CLIENTS:
            link = root / client / "skills" / skill.name
            if not link.is_symlink():
                raise LocalSkillDiscoveryError("local-link-missing")
            try:
                raw_target = os.readlink(link)
                resolved = link.resolve(strict=True)
            except OSError as error:
                raise LocalSkillDiscoveryError("local-link-unresolved") from error
            if raw_target != f"../../skills/{skill.name}":
                raise LocalSkillDiscoveryError("local-link-malformed")
            if resolved != skill_root:
                raise LocalSkillDiscoveryError("local-link-unresolved")
        try:
            validator(root, skill)
        except LocalSkillDiscoveryError:
            raise
        except Exception as error:
            raise LocalSkillDiscoveryError("malformed-skill") from error
    return tuple(names)


def discover_shared_skill_names(harness_root: Path) -> tuple[str, ...]:
    """Return the bounded declared shared-skill name set."""
    source_root = harness_root / "shared" / "skills"
    if source_root.is_symlink() or not source_root.is_dir():
        raise LocalSkillDiscoveryError("shared-root-invalid")
    try:
        observed = tuple(islice(source_root.iterdir(), MAX_SKILLS + 1))
    except OSError as error:
        raise LocalSkillDiscoveryError("shared-root-invalid") from error
    if not observed or len(observed) > MAX_SKILLS:
        raise LocalSkillDiscoveryError("shared-count-invalid")
    entries = sorted(observed, key=lambda path: path.name)
    if any(
        NAME.fullmatch(entry.name) is None or not entry.is_dir() for entry in entries
    ):
        raise LocalSkillDiscoveryError("shared-entry-invalid")
    return tuple(entry.name for entry in entries)


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("LOCAL_SKILL_DISCOVERY status=failed reason=arguments-invalid")
    try:
        shared_names = discover_shared_skill_names(Path(sys.argv[2]))
        names = discover_local_skills(
            Path(sys.argv[1]), declared_external_names=shared_names
        )
    except LocalSkillDiscoveryError as error:
        raise SystemExit(
            f"LOCAL_SKILL_DISCOVERY status=failed reason={error}"
        ) from error
    print("\n".join(names))


if __name__ == "__main__":
    main()

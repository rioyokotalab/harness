#!/usr/bin/env python3
"""Closed repository map for the three managed Local Codex sessions."""

from __future__ import print_function

import os
import stat
import subprocess
import sys


TARGET_NAMES = ("harness", "students", "swallow")
HARNESS_TOKEN = "@HARNESS_ROOT@"


class TargetError(RuntimeError):
    pass


def fail(message):
    raise TargetError(message)


def control_root():
    root = os.environ.get("HARNESS_CONTROL_ROOT") or os.environ.get(
        "HARNESS_ROOT"
    )
    if (
        not root
        or not os.path.isabs(root)
        or os.path.normpath(root) != root
    ):
        fail("Harness control root is unavailable")
    return root


def harness_repository_root():
    root = os.environ.get("HARNESS_TARGET_ROOT")
    if root is None:
        root = os.environ.get("HARNESS_ROOT") or control_root()
    if not os.path.isabs(root) or os.path.normpath(root) != root:
        fail("Harness target root is malformed")
    return root


def profile_path():
    override = os.environ.get("HARNESS_TEST_CODEX_TARGETS_FILE")
    if override:
        if os.environ.get("HARNESS_TESTING") != "1" or not os.path.isabs(override):
            fail("test target profile override is forbidden")
        return override
    return os.path.join(
        control_root(), "profiles", "codex-session-targets.tsv"
    )


def _safe_regular_file(path):
    try:
        info = os.lstat(path)
    except OSError:
        fail("Codex target profile is unavailable")
    if (
        not stat.S_ISREG(info.st_mode)
        or stat.S_ISLNK(info.st_mode)
        or info.st_uid != os.getuid()
        or info.st_nlink != 1
        or stat.S_IMODE(info.st_mode) & 0o002
    ):
        fail("Codex target profile is unsafe")


def load_targets():
    path = profile_path()
    _safe_regular_file(path)
    try:
        with open(path, "r") as stream:
            lines = stream.read().splitlines()
    except (IOError, OSError, UnicodeError):
        fail("Codex target profile cannot be read")
    root = harness_repository_root()
    values = []
    for line_number, line in enumerate(lines, 1):
        if not line or line.startswith("#"):
            continue
        fields = line.split("\t")
        if len(fields) != 3:
            fail("Codex target profile line {} is malformed".format(line_number))
        name, raw_index, repository = fields
        try:
            index = int(raw_index)
        except ValueError:
            fail("Codex target index is malformed")
        if repository == HARNESS_TOKEN:
            repository = root
        if (
            not repository
            or not os.path.isabs(repository)
            or os.path.normpath(repository) != repository
            or "\n" in repository
            or "\r" in repository
            or "\t" in repository
        ):
            fail("Codex target repository is malformed")
        values.append(
            {"name": name, "index": index, "repository": repository}
        )
    if (
        tuple(value["name"] for value in values) != TARGET_NAMES
        or tuple(value["index"] for value in values) != tuple(range(len(TARGET_NAMES)))
        or len(set(value["repository"] for value in values)) != len(values)
    ):
        fail("Codex target profile is not the closed canonical map")
    return tuple(values)


def target_map():
    return {value["name"]: value for value in load_targets()}


def repository_for(name):
    mapping = target_map()
    if name not in mapping:
        fail("unknown Codex target")
    return mapping[name]["repository"]


def _reject_symlink_components(path):
    current = os.path.sep
    for component in path.split(os.path.sep)[1:]:
        current = os.path.join(current, component)
        try:
            info = os.lstat(current)
        except OSError:
            fail("Codex target repository is unavailable")
        if stat.S_ISLNK(info.st_mode):
            fail("Codex target repository has a symlinked component")


def validate_repository(path):
    _reject_symlink_components(path)
    try:
        info = os.lstat(path)
    except OSError:
        fail("Codex target repository is unavailable")
    if (
        not stat.S_ISDIR(info.st_mode)
        or stat.S_ISLNK(info.st_mode)
        or info.st_uid != os.getuid()
        or os.path.realpath(path) != path
    ):
        fail("Codex target repository is unsafe")
    result = subprocess.run(
        ["git", "-C", path, "rev-parse", "--show-toplevel"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    try:
        root = result.stdout.decode("utf-8", "strict").strip()
    except UnicodeError:
        fail("Codex target repository identity is malformed")
    if result.returncode != 0 or root != path:
        fail("Codex target path is not an exact repository root")
    config = os.path.join(path, ".codex", "config.toml")
    try:
        config_info = os.lstat(config)
    except OSError:
        fail("Codex target project configuration is unavailable")
    if (
        not stat.S_ISREG(config_info.st_mode)
        or stat.S_ISLNK(config_info.st_mode)
        or config_info.st_uid != os.getuid()
        or config_info.st_nlink != 1
        or stat.S_IMODE(config_info.st_mode) & 0o002
    ):
        fail("Codex target project configuration is unsafe")
    return path


def target_for_repository(path, validate=True):
    if not os.path.isabs(path) or os.path.normpath(path) != path:
        fail("Codex repository path is malformed")
    matches = [
        value["name"]
        for value in load_targets()
        if value["repository"] == path
    ]
    if len(matches) != 1:
        fail("Codex repository is outside the closed target map")
    if validate:
        validate_repository(path)
    return matches[0]


def cwd_allowed(name, path):
    expected = repository_for(name)
    return path == expected


def validate_all():
    for value in load_targets():
        validate_repository(value["repository"])


def main(arguments):
    if len(arguments) == 2 and arguments[0] == "repository":
        print(repository_for(arguments[1]))
        return 0
    if len(arguments) == 2 and arguments[0] == "target-for-repository":
        print(target_for_repository(arguments[1]))
        return 0
    if len(arguments) == 1 and arguments[0] == "validate-all":
        validate_all()
        print("CODEX_TARGETS status=ready count=3")
        return 0
    fail("usage: harness_codex_targets.py repository TARGET | "
         "target-for-repository PATH | validate-all")


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except TargetError as error:
        print("harness: {}".format(error), file=sys.stderr)
        sys.exit(2)

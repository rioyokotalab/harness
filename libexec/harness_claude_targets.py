#!/usr/bin/env python3
"""Closed location and repository map for managed Local Claude panes."""

from __future__ import print_function

import os
import stat
import subprocess
import sys


SESSION_NAME = "harness"
INITIAL_LAYOUT = "even-horizontal"
PANE_ROLE_OPTION = "@harness_claude_target"
PANE_SESSION_OPTION = "@harness_claude_session_id"
TARGET_NAMES = ("harness", "personal", "students")
HARNESS_TOKEN = "@HARNESS_ROOT@"
LAUNCH_FLAGS = (
    "--permission-mode",
    "bypassPermissions",
    "--model",
    "fable",
    "--effort",
    "high",
    "--fallback-model",
    "opus",
)


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
    override = os.environ.get("HARNESS_TEST_CLAUDE_TARGETS_FILE")
    if override:
        if os.environ.get("HARNESS_TESTING") != "1" or not os.path.isabs(override):
            fail("test target profile override is forbidden")
        return override
    return os.path.join(
        control_root(), "profiles", "claude-session-targets.tsv"
    )


def _safe_regular_file(path):
    try:
        info = os.lstat(path)
    except OSError:
        fail("Claude target profile is unavailable")
    if (
        not stat.S_ISREG(info.st_mode)
        or stat.S_ISLNK(info.st_mode)
        or info.st_uid != os.getuid()
        or info.st_nlink != 1
        or stat.S_IMODE(info.st_mode) & 0o002
    ):
        fail("Claude target profile is unsafe")


def load_targets():
    path = profile_path()
    _safe_regular_file(path)
    try:
        with open(path, "r") as stream:
            lines = stream.read().splitlines()
    except (IOError, OSError, UnicodeError):
        fail("Claude target profile cannot be read")
    root = harness_repository_root()
    values = []
    for line_number, line in enumerate(lines, 1):
        if not line or line.startswith("#"):
            continue
        fields = line.split("\t")
        if len(fields) != 5:
            fail("Claude target profile line {} is malformed".format(line_number))
        name, raw_window_index, window_name, raw_pane_index, repository = fields
        try:
            window_index = int(raw_window_index)
            pane_index = int(raw_pane_index)
        except ValueError:
            fail("Claude target index is malformed")
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
            fail("Claude target repository is malformed")
        values.append(
            {
                "name": name,
                "window_index": window_index,
                "window_name": window_name,
                "pane_index": pane_index,
                "index": pane_index,
                "repository": repository,
            }
        )
    if (
        tuple(value["name"] for value in values) != TARGET_NAMES
        or any(
            value["window_index"] < 0
            or value["pane_index"] < 0
            or not value["window_name"]
            or not value["window_name"].replace("-", "").isalnum()
            for value in values
        )
        or len(
            {
                (value["window_index"], value["window_name"], value["pane_index"])
                for value in values
            }
        ) != len(values)
    ):
        fail("Claude target profile is not the closed canonical map")
    return tuple(values)


def target_map():
    return {value["name"]: value for value in load_targets()}


def repository_for(name):
    mapping = target_map()
    if name not in mapping:
        fail("unknown Claude target")
    return mapping[name]["repository"]


def location_for(name):
    mapping = target_map()
    if name not in mapping:
        fail("unknown Claude target")
    value = mapping[name]
    return value["window_index"], value["window_name"], value["pane_index"]


def _reject_symlink_components(path):
    current = os.path.sep
    for component in path.split(os.path.sep)[1:]:
        current = os.path.join(current, component)
        try:
            info = os.lstat(current)
        except OSError:
            fail("Claude target repository is unavailable")
        if stat.S_ISLNK(info.st_mode):
            fail("Claude target repository has a symlinked component")


def validate_repository(path):
    _reject_symlink_components(path)
    try:
        info = os.lstat(path)
    except OSError:
        fail("Claude target repository is unavailable")
    if (
        not stat.S_ISDIR(info.st_mode)
        or stat.S_ISLNK(info.st_mode)
        or info.st_uid != os.getuid()
        or os.path.realpath(path) != path
    ):
        fail("Claude target repository is unsafe")
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
        fail("Claude target repository identity is malformed")
    if result.returncode != 0 or root != path:
        fail("Claude target path is not an exact repository root")
    marker = os.path.join(path, "CLAUDE.md")
    try:
        marker_info = os.lstat(marker)
    except OSError:
        fail("Claude target project instructions are unavailable")
    if (
        not stat.S_ISREG(marker_info.st_mode)
        or stat.S_ISLNK(marker_info.st_mode)
        or marker_info.st_uid != os.getuid()
        or stat.S_IMODE(marker_info.st_mode) & 0o002
    ):
        fail("Claude target project instructions are unsafe")
    return path


def target_for_repository(path, validate=True):
    if not os.path.isabs(path) or os.path.normpath(path) != path:
        fail("Claude repository path is malformed")
    matches = [
        value["name"]
        for value in load_targets()
        if value["repository"] == path
    ]
    if len(matches) > 1 and "harness" in matches:
        matches = ["harness"]
    if len(matches) != 1:
        fail("Claude repository is outside the closed target map")
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
    if len(arguments) == 2 and arguments[0] == "validate-target":
        print(validate_repository(repository_for(arguments[1])))
        return 0
    if len(arguments) == 1 and arguments[0] == "validate-all":
        validate_all()
        print("CLAUDE_TARGETS status=ready count=3")
        return 0
    fail("usage: harness_claude_targets.py repository TARGET | "
         "target-for-repository PATH | validate-target TARGET | validate-all")


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except TargetError as error:
        print("harness: {}".format(error), file=sys.stderr)
        sys.exit(2)

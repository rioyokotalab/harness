#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
peer=$(printf '%s' 'web''site')

if [ "${HARNESS_VALIDATION_FULL:-1}" = 1 ] ||
	[ -z "${HARNESS_CHANGED_PATHS:-}" ]; then
	candidates=$(git ls-files)
else
	candidates=$HARNESS_CHANGED_PATHS
fi

scan_files=$(
	printf '%s\n' "$candidates" |
		while IFS= read -r file; do
			[ -f "$file" ] && [ ! -L "$file" ] && printf '%s\n' "$file"
		done |
		sed -e '/^TODO\.md$/d' \
			-e '/^docs\/audits\//d' \
			-e '/^docs\/llm-hpc-readiness-handoff-2026-07-17\.md$/d' \
			-e '/^evaluation\/results\//d' \
			-e '/^tests\/test-repository-independence\.sh$/d'
)
if [ -n "$scan_files" ] && printf '%s\n' "$scan_files" | xargs rg -n -i \
	"/home/[^/]+/$peer|\$HOME/$peer|github\\.com/[^/]+/$peer|$peer-main\\.json|$peer-public-history"; then
	echo 'FAIL: harness has an operational dependency on the peer repository' >&2
	exit 1
fi

[ ! -e .gitmodules ] || {
	echo 'FAIL: harness must not declare a Git submodule' >&2
	exit 1
}
printf '%s\n' "$candidates" | while IFS= read -r file; do
	git ls-files -s -- "$file"
done | awk '$1 == 120000 { print $4 }' |
while IFS= read -r link; do
	target=$(readlink "$link")
	case "$target" in /*)
		echo "FAIL: tracked symlink leaves the repository: $link" >&2
		exit 1
		;; esac
	case $(uname -s) in
		Darwin) resolved=$(realpath "${link%/*}/$target") ;;
		*) resolved=$(realpath -m -- "${link%/*}/$target") ;;
	esac
	case "$resolved" in "$ROOT"/*) ;;
		*) echo "FAIL: tracked symlink leaves the repository: $link" >&2; exit 1 ;;
	esac
done

tool_files=
for file in profiles/tools.tsv tools/artifacts.tsv \
	libexec/harness-tool libexec/harness-inventory; do
	if printf '%s\n' "$candidates" | grep -F -x "$file" >/dev/null; then
		tool_files="$tool_files $file"
	fi
done
if [ -n "$tool_files" ] && rg -n -i 'lftp' $tool_files; then
	echo 'FAIL: harness still owns the peer deployment client' >&2
	exit 1
fi

echo 'repository independence tests passed'

#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../../.." && pwd)
[ -d "$ROOT/.git" ] && [ ! -L "$ROOT/.git" ] || {
    echo 'source-contract: harness Git checkout required' >&2
    exit 2
}
[ "$#" -ge 2 ] || {
    echo 'source-contract: expected revision and paths required' >&2
    exit 2
}
expected=$1
shift
case $expected in ''|*[!0-9a-f]*) echo 'source-contract: invalid revision' >&2; exit 2 ;; esac
[ "${#expected}" -eq 40 ] || { echo 'source-contract: invalid revision' >&2; exit 2; }

git -C "$ROOT" cat-file -e "$expected^{commit}" 2>/dev/null || {
    echo 'source-contract: revision unavailable' >&2
    exit 2
}
head=$(git -C "$ROOT" rev-parse --verify HEAD)
git -C "$ROOT" merge-base --is-ancestor "$expected" "$head" || {
    echo 'source-contract: revision is not an ancestor' >&2
    exit 2
}

seen=' '
count=0
for path in "$@"; do
    case $path in
        ''|/*|.|..|../*|*/../*|*/..|*//*|*[!A-Za-z0-9._/-]*)
            echo 'source-contract: unsafe path' >&2
            exit 2
            ;;
    esac
    case "$seen" in *" $path "*) echo 'source-contract: duplicate path' >&2; exit 2 ;; esac
    seen="$seen$path "
    [ -f "$ROOT/$path" ] && [ ! -L "$ROOT/$path" ] || {
        echo 'source-contract: path is not a regular file' >&2
        exit 2
    }
    [ "$(git -C "$ROOT" cat-file -t "$expected:$path" 2>/dev/null || true)" = blob ] || {
        echo 'source-contract: path unavailable at revision' >&2
        exit 2
    }
    git -C "$ROOT" diff --quiet "$expected" -- "$path" || {
        echo 'source-contract: path differs from submitted revision' >&2
        exit 2
    }
    [ -z "$(git -C "$ROOT" status --porcelain=v1 -- "$path")" ] || {
        echo 'source-contract: path has local changes' >&2
        exit 2
    }
    count=$((count + 1))
done

printf 'SOURCE_CONTRACT expected=%s head=%s paths=%s status=pass\n' \
    "$expected" "$head" "$count"

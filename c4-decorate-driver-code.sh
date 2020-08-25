#!/bin/bash

set -Eeuo pipefail

stderr(){
	echo -e "$*" >&2
}

die(){
	rc=$?
	stderr "$@"
	exit $((rc ? rc : 99))
}

command -V mawk >/dev/null
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

while [ $# -ne 0 ]; do
	FILE_TO_TRANSFORM="$1"
	FILE_TRANSFORMED="$FILE_TO_TRANSFORM".decorated
	mawk \
	  -v logtag="C4-$(basename "${FILE_TO_TRANSFORM}" .c): " \
	  -f "$SCRIPT_DIR"/c4-decorate-driver-code.awk "${FILE_TO_TRANSFORM}" \
	> "${FILE_TRANSFORMED}"
	if diff -q "$FILE_TRANSFORMED" "$FILE_TO_TRANSFORM" >/dev/null; then
		rm "$FILE_TRANSFORMED"
	else
		mv "$FILE_TRANSFORMED" "$FILE_TO_TRANSFORM"
	fi
	shift
done

if [ "${FILE_TO_TRANSFORM-}" = '' ]; then
	die "pass file(s) to decorate with logging code as positional param(s) to this script"
fi

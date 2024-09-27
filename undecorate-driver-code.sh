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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

while [ $# -ne 0 ]; do
	FILE_TO_TRANSFORM="$1"
	FILE_TRANSFORMED="$FILE_TO_TRANSFORM".undecorated
	# remove all known logging macros (definitions + invocations)
	# first two rules are handling special cases (*write_reg & *read_reg fnctns)
	# third rule removes *lines* with our macros definitions
	# fourth rule removes function entry logging (just logging part)
	# fifth rule removes return statement decorations
	# sixth and seventh rules removes LOG_VOID decorations
	sed -re '
		s|.+(return u8RdVal;) /\*LOG_RET\*/$|\t\1|;
		s|^\{ int __attribute__\(\(unused\)\) dummy .+/\*LOG_RET\*/$|{|;
		/^\#define LOG_(ENTRY|RET(_COMPLEX)?|VOID)\(/d;
		s/^\{\tLOG_ENTRY\(\);$/{/;
		s/(return )LOG_RET(_COMPLEX)?\((.+)\);$/\1\3;/;
		s/LOG_VOID\(return\);$/return;/;
		s/^LOG_VOID\(_\); }$/}/;
		' "$FILE_TO_TRANSFORM" > "$FILE_TRANSFORMED"
	if diff -q "$FILE_TRANSFORMED" "$FILE_TO_TRANSFORM" >/dev/null; then
		rm "$FILE_TRANSFORMED"
	else
		mv "$FILE_TRANSFORMED" "$FILE_TO_TRANSFORM"
	fi
	shift
done

if [ "${FILE_TO_TRANSFORM-}" = '' ]; then
	die "pass file(s) to undecorate with logging code as positional param(s) to this script"
fi

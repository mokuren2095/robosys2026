#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 もくれん
# SPDX-License-Identifier: BSD-3-Clause
set -eu
cd "$(dirname "$0")"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
check() {
    local name=$1 input=$2 expected=$3 status=$4 diagnostic=$5 actual=0
    printf '%s' "$input" | ./seqgaps >"$tmp/out" 2>"$tmp/err" || actual=$?
    printf '%s' "$expected" >"$tmp/expected"
    if [[ $actual != "$status" ]] || ! diff -u "$tmp/expected" "$tmp/out"; then
        echo "FAIL: $name (exit $actual)" >&2
        exit 1
    fi
    if [[ -n $diagnostic ]]; then
        grep -Fq "$diagnostic" "$tmp/err" || { echo "FAIL: $name (stderr)" >&2; exit 1; }
    elif [[ -s $tmp/err ]]; then
        cat "$tmp/err" >&2
        exit 1
    fi
    echo "PASS: $name"
}

check multiple $'40\n41\n45\n47\n' $'42\t44\t3\n46\t46\t1\n' 0 ''
check consecutive $'0\n1\n2\n' '' 0 ''
check singleton '20' '' 0 ''
check whitespace $' 009\r\n\n\t011 ' $'10\t10\t1\n' 0 ''
check large $'0\n999999999999999999' $'1\t999999999999999998\t999999999999999998\n' 0 ''
check empty '' '' 1 '番号がありません'
check blank $' \n\t' '' 1 '番号がありません'
check duplicate $'1\n3\n3' '' 1 '3行目'
check reversed $'4\n2' '' 1 '2行目'
check invalid $'1\n5\n\n六' '' 1 '4行目'
check negative '-2' '' 1 '1行目'
check too_long '1000000000000000000' '' 1 '1行目'

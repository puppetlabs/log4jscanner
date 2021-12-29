#!/usr/bin/env bash

set -e

skip=""
if [ -n "${PT_skip}" ]; then
  while IFS=',' read -ra skipdirs; do
    for glob in "${skipdirs[@]}"; do
      skip="${skip} --skip ${glob}"
    done
  done <<< "${PT_skip}"
fi

rewrite=""
if [ -n "${PT_rewrite}" ] && [ "${PT_rewrite}" = "true" ]; then
  rewrite="--rewrite"
fi

dirs=""
while IFS=',' read -ra directories; do
  for d in "${directories[@]}"; do
    dirs="${directories} ${d}"
  done
done <<< "${PT_directories}"

echo "Command: ${PT__installdir}/log4jscanner/files/log4jscanner_nix ${skip} ${rewrite} ${dirs}"
${PT__installdir}/log4jscanner/files/log4jscanner_nix ${skip} ${rewrite} ${dirs} 2>&1
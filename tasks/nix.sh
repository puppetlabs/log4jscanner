#!/usr/bin/env bash

set -e

skip=""
if [ -n "${PT_skip}" ]; then
  while IFS=' ' read -ra skipdirs; do
    for glob in "${skipdirs[@]}"; do
      skip="${skip} --skip ${glob}"
    done
  done <<< "${PT_skip}"
fi

rewrite=""
if [ -n "${PT_rewrite}" ] && [ "${PT_rewrite}" = "true" ]; then
  rewrite="--rewrite"
fi
echo "${PT__installdir}/log4jscanner/files/log4jscanner_nix ${skip} ${rewrite} ${PT_directories}"
${PT__installdir}/log4jscanner/files/log4jscanner_nix ${skip} ${rewrite} ${PT_directories}
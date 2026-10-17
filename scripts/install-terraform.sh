#!/usr/bin/env bash
# Installs a pinned Terraform version on a Linux agent and adds it to PATH for later steps.
#   scripts/install-terraform.sh <version>
set -euo pipefail

version="${1:?terraform version required}"
dest="${AGENT_TOOLSDIRECTORY:-$HOME/.local}/terraform/${version}"

if [[ ! -x "$dest/terraform" ]]; then
  mkdir -p "$dest"
  base="https://releases.hashicorp.com/terraform/${version}"
  zip="terraform_${version}_linux_amd64.zip"
  curl -fsSLo "/tmp/$zip" "$base/$zip"
  curl -fsSLo /tmp/terraform_SHA256SUMS "$base/terraform_${version}_SHA256SUMS"
  (cd /tmp && grep " $zip\$" terraform_SHA256SUMS | sha256sum -c -)
  unzip -oq "/tmp/$zip" -d "$dest"
fi

echo "##vso[task.prependpath]$dest"
"$dest/terraform" version

#!/usr/bin/env bash

set -e
set -o pipefail

check_installed() {
  if ! command -v $1 > /dev/null 2>&1; then
    printf "$1 must be installed before running this script!"
    exit 1
  fi
}

configure_pipeline() {
  local name=$1
  local pipeline=$2

  printf "configuring the $name pipeline...\n"

  fly -t ci set-pipeline -p $name -c $pipeline
}

check_installed fly

pipelines_path=$(cd $(dirname $0)/../ && pwd)

pipeline=${1}

if [ "$#" -gt 0 ]; then
  for pipeline in $*; do
    file=$pipelines_path/${pipeline}.yml
    if [ "$pipeline" = "main" ]; then
      file=$pipelines_path/concourse.yml
    fi

    configure_pipeline $pipeline \
      $file
  done
else
  configure_pipeline main \
    $pipelines_path/concourse.yml

  if [ -e $pipelines_path/releases/concourse-*.yml ]; then
    for release in $pipelines_path/releases/concourse-*.yml; do
      version=$(echo $release | sed -e 's/.*concourse-\(.*\).yml$/\1/')
      configure_pipeline releases:$version \
        $release
    done
  fi

  configure_pipeline wings \
    $pipelines_path/wings.yml

  configure_pipeline resources \
    $pipelines_path/resources.yml

  configure_pipeline images \
    $pipelines_path/images.yml

  configure_pipeline hangar \
    $pipelines_path/hangar.yml

  configure_pipeline prs \
    $pipelines_path/pull-requests.yml
fi

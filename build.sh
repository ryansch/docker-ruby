#!/bin/bash

set -euo pipefail

images=()
images+=("3.2.1" "3.2")

variants=("base" "plus" "test")

function parse_tags() {
  while [ $# -ge 2 ] ; do
    echo "$1"
    shift; shift
  done
}

tags=()
while IFS=$'\n' read -r tag ; do
  [[ -n "${tag:-}" ]] && tags+=("$tag")
done <<< "$(parse_tags "${images[@]}")"

# Show a prompt for a command
function prompt() {
  if [[ -z "${HIDE_PROMPT:-}" ]] ; then
    echo -ne '\033[90m$\033[0m' >&2
    for arg in "${@}" ; do
      if [[ $arg =~ [[:space:]] ]] ; then
        echo -n " '$arg'" >&2
      else
        echo -n " $arg" >&2
      fi
    done
    echo >&2
  fi
}

# Shows the command being run, and runs it
function prompt_and_run() {
  local exit_code

  prompt "$@"
  "$@"
  exit_code=$?

  echo

  return $exit_code
}

build_images() {
  local prefix="$1"
  shift

  while [ $# -ge 2 ] ; do
    for variant in "${variants[@]}"; do
      prompt_and_run docker build --target "${variant}" --pull -t "${prefix}:${1}-${variant}" "${2}"
    done

    shift; shift
  done
}

function push_images() {
  local prefix="$1"
  shift

  while [ $# -ge 1 ] ; do
    for variant in "${variants[@]}"; do
      prompt_and_run docker push "${prefix}:${1}-${variant}"
    done

    shift
  done
}

build_images ryansch/ruby "${images[@]}"
push_images ryansch/ruby "${tags[@]}"

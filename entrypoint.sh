#!/bin/sh
set -e

main() {
  echo "" # see https://github.com/actions/toolkit/issues/168

  sanitize "${INPUT_NAME}" "name"
  sanitize "${INPUT_USERNAME}" "username"
  sanitize "${INPUT_PASSWORD}" "password"

  REGISTRY_NO_PROTOCOL=$(echo "${INPUT_REGISTRY}" | sed -e 's/^https:\/\///g')
  if uses "${INPUT_REGISTRY}" && ! isPartOfTheName "${REGISTRY_NO_PROTOCOL}"; then
    INPUT_NAME="${REGISTRY_NO_PROTOCOL}/${INPUT_NAME}"
  fi

  # Branch or tag
  REF="${GITHUB_REF}"
  # Pull request is always related to a branch that should be merged into the default one
  if [ "${GITHUB_EVENT_NAME}" = "pull_request" ]; then
    REF="${GITHUB_HEAD_REF}"
  fi
  # Remove refs/heads/<branch>, refs/tags/<branch>, etc...
  REF=${REF#refs/*/}
  # Remove everything that is before the @ tag
  REF=${REF#*@}

  DOCKERNAME_REF="${INPUT_NAME}:${REF}"
  DOCKERNAME_SHA="${INPUT_NAME}:${GITHUB_SHA}"

  if uses "${INPUT_WORKDIR}"; then
    changeWorkingDirectory
  fi

  # shellcheck disable=SC2086
  echo "${INPUT_PASSWORD}" | docker login -u ${INPUT_USERNAME} --password-stdin ${INPUT_REGISTRY}

  BUILDPARAMS=""
  CONTEXT="."

  if uses "${INPUT_DOCKERFILE}"; then
    useCustomDockerfile
  fi
  if uses "${INPUT_BUILDARGS}"; then
    addBuildArgs
  fi
  if uses "${INPUT_TAGS}"; then
    addTags
  fi
  if uses "${INPUT_CONTEXT}"; then
    CONTEXT="${INPUT_CONTEXT}"
  fi
  if usesBoolean "${INPUT_CACHE}"; then
    useBuildCache
  fi

  pushImage
  echo ::set-output name=sha-tag::"${GITHUB_SHA}"
  echo ::set-output name=ref-tag::"${REF}"

  docker logout
}

sanitize() {
  if [ -z "${1}" ]; then
    >&2 echo "Unable to find the ${2}. Did you set with.${2}?"
    exit 1
  fi
}

isPartOfTheName() {
  [ "$(echo "${INPUT_NAME}" | sed -e "s/${1}//g")" != "${INPUT_NAME}" ]
}

changeWorkingDirectory() {
  cd "${INPUT_WORKDIR}"
}

useCustomDockerfile() {
  BUILDPARAMS="$BUILDPARAMS -f ${INPUT_DOCKERFILE}"
}

addBuildArgs() {
  for arg in $(echo "${INPUT_BUILDARGS}" | tr ',' '\n'); do
    BUILDPARAMS="$BUILDPARAMS --build-arg ${arg}"
    echo "::add-mask::${arg}"
  done
}

addTags() {
  for tag in $(echo "${INPUT_TAGS}" | tr ',' '\n'); do
    BUILDPARAMS="$BUILDPARAMS -t ${INPUT_NAME}:${tag}"
  done
}

useBuildCache() {
  if docker pull "${DOCKERNAME_REF}" 2>/dev/null; then
    BUILDPARAMS="$BUILDPARAMS --cache-from ${DOCKERNAME_REF}"
  fi
}

uses() {
  [ -n "${1}" ]
}

usesBoolean() {
  [ -n "${1}" ] && [ "${1}" = "true" ]
}

pushImage() {
  # shellcheck disable=SC2086
  docker build $BUILDPARAMS -t "${DOCKERNAME_SHA}" -t "${DOCKERNAME_REF}" "${CONTEXT}"
  docker push "${DOCKERNAME_SHA}"
  docker push "${DOCKERNAME_REF}"
  if uses "${INPUT_TAGS}"; then
    for tag in $(echo "${INPUT_TAGS}" | tr ',' '\n'); do
      docker push "${INPUT_NAME}:${tag}"
    done
  fi
}

main

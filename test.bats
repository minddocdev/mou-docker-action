#!/usr/bin/env bats

setup(){
  cat /dev/null >| mockCalledWith

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ) > mockReturns

  export GITHUB_REF='refs/heads/master'
  export GITHUB_HEAD_REF='refs/heads/my-branch'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export GITHUB_EVENT_NAME='push'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
}

teardown() {
  unset INPUT_DOCKERFILE
  unset INPUT_REGISTRY
  unset INPUT_CACHE
  unset GITHUB_SHA
  unset INPUT_PULL_REQUESTS
  unset MOCK_ERROR_CONDITION
}

@test "it pushes branch as name of the branch" {
  run /entrypoint.sh

  expectStdOut "
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::master"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:master .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:master
/usr/local/bin/docker logout"
}

@test "it pushes a release branch" {
  export GITHUB_REF='refs/heads/release/1.3.3'

  run /entrypoint.sh

  expectStdOut "
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::1.3.3"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:1.3.3 .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:1.3.3
/usr/local/bin/docker logout"
}

@test "it pushes a feature branch with context" {
  export GITHUB_REF='refs/heads/feat/myapp/JIRA-123/add-auth'

  run /entrypoint.sh

  expectStdOut "
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::add-auth"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:add-auth .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:add-auth
/usr/local/bin/docker logout"
}

@test "it pushes a feature branch with context and more dashes" {
  export GITHUB_REF='refs/heads/chore/myapp/split-dev-dependencies'

  run /entrypoint.sh

  expectStdOut "
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::split-dev-dependencies"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:split-dev-dependencies .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:split-dev-dependencies
/usr/local/bin/docker logout"
}

@test "it pushes a git tag" {
  export GITHUB_REF='refs/tags/v1.0.0'

  run /entrypoint.sh

  expectStdOut "
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::1.0.0"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:1.0.0 .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:1.0.0
/usr/local/bin/docker logout"
}

@test "it removes prefix for git tags with @" {
  export GITHUB_REF='refs/tags/myapp@1.0.0'

  run /entrypoint.sh

  expectStdOut "
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::1.0.0"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:1.0.0 .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:1.0.0
/usr/local/bin/docker logout"
}

@test "it removes prefix for git tags with @ and v" {
  export GITHUB_REF='refs/tags/versionedapp@1.0.0'

  run /entrypoint.sh

  expectStdOut "
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::1.0.0"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:1.0.0 .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:1.0.0
/usr/local/bin/docker logout"
}

@test "it pushes specific Dockerfile to branch" {
  export INPUT_DOCKERFILE='MyDockerFileName'

  run /entrypoint.sh  export GITHUB_REF='refs/heads/master'

  expectStdOut "
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::master"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -f MyDockerFileName -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:master .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:master
/usr/local/bin/docker logout"
}

@test "it pushes to another registry and adds the hostname" {
  export INPUT_REGISTRY='my.Registry.io'

  run /entrypoint.sh

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin my.Registry.io
/usr/local/bin/docker build -t my.Registry.io/my/repository:12169ed809255604e557a82617264e9c373faca7 -t my.Registry.io/my/repository:master .
/usr/local/bin/docker push my.Registry.io/my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my.Registry.io/my/repository:master
/usr/local/bin/docker logout"
}

@test "it pushes to another registry and is ok when the hostname is already present" {
  export INPUT_REGISTRY='my.Registry.io'
  export INPUT_NAME='my.Registry.io/my/repository'

  run /entrypoint.sh

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin my.Registry.io
/usr/local/bin/docker build -t my.Registry.io/my/repository:12169ed809255604e557a82617264e9c373faca7 -t my.Registry.io/my/repository:master .
/usr/local/bin/docker push my.Registry.io/my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my.Registry.io/my/repository:master
/usr/local/bin/docker logout"
}

@test "it pushes to another registry and removes the protocol from the hostname" {
  export INPUT_REGISTRY='https://my.Registry.io'
  export INPUT_NAME='my/repository'

  run /entrypoint.sh

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin https://my.Registry.io
/usr/local/bin/docker build -t my.Registry.io/my/repository:12169ed809255604e557a82617264e9c373faca7 -t my.Registry.io/my/repository:master .
/usr/local/bin/docker push my.Registry.io/my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my.Registry.io/my/repository:master
/usr/local/bin/docker logout"
}

@test "it caches the image from a former build" {
  export INPUT_CACHE='true'

  run /entrypoint.sh

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker pull my/repository:master
/usr/local/bin/docker build --cache-from my/repository:master -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:master .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:master
/usr/local/bin/docker logout"
}

@test "it does not cache the image from a former build if set to false" {
  export INPUT_CACHE='false'

  run /entrypoint.sh

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:master .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:master
/usr/local/bin/docker logout"
}

@test "it uses buildargs for building, if configured" {
  export INPUT_BUILDARGS='MY_FIRST,MY_SECOND'

  run /entrypoint.sh

  expectStdOut "
::add-mask::MY_FIRST
::add-mask::MY_SECOND
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::master"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build --build-arg MY_FIRST --build-arg MY_SECOND -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:master .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:master
/usr/local/bin/docker logout"
}

@test "it uses buildargs for a single variable" {
  export INPUT_BUILDARGS='MY_ONLY'

  run /entrypoint.sh

  expectStdOut "
::add-mask::MY_ONLY
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::master"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build --build-arg MY_ONLY -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:master .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:master
/usr/local/bin/docker logout"
}

@test "it uses tags for building, if configured" {
  export INPUT_TAGS='firsttag,secondtag'

  run /entrypoint.sh

  expectStdOut "
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::master"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:firsttag -t my/repository:secondtag -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:master .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:master
/usr/local/bin/docker push my/repository:firsttag
/usr/local/bin/docker push my/repository:secondtag
/usr/local/bin/docker logout"
}

@test "it uses tags for a single variable" {
  export INPUT_TAGS='lonelytag'

  run /entrypoint.sh

  expectStdOut "
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::master"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:lonelytag -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:master .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:master
/usr/local/bin/docker push my/repository:lonelytag
/usr/local/bin/docker logout"
}

@test "it errors when with.name was not set" {
  unset INPUT_NAME

  run /entrypoint.sh

  local expected="Unable to find the name. Did you set with.name?"
  echo $output
  [ "$status" -eq 1 ]
  echo "$output" | grep "$expected"
}

@test "it errors when with.username was not set" {
  unset INPUT_USERNAME

  run /entrypoint.sh

  local expected="Unable to find the username. Did you set with.username?"
  echo $output
  [ "$status" -eq 1 ]
  echo "$output" | grep "$expected"
}

@test "it errors when with.password was not set" {
  unset INPUT_PASSWORD

  run /entrypoint.sh

  local expected="Unable to find the password. Did you set with.password?"
  echo $output
  [ "$status" -eq 1 ]
  echo "$output" | grep "$expected"
}

@test "it errors when the working directory is configured but not present" {
  export INPUT_WORKDIR='mySubDir'

  run /entrypoint.sh

  [ "$status" -eq 2 ]
}

@test "it can set a custom context" {
  export GITHUB_REF='refs/heads/master'
  export INPUT_CONTEXT='/myContextFolder'

  run /entrypoint.sh

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:master /myContextFolder
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:master
/usr/local/bin/docker logout"
}

function expectStdOut() {
  echo "Expected: |$1|
  Got: |$output|"
  [ "$output" = "$1" ]
}

function expectMockCalled() {
  local mockCalledWith=$(cat mockCalledWith)
  echo "Expected: |$1|
  Got: |$mockCalledWith|"
  [ "$mockCalledWith" = "$1" ]
}

@test "it uses the head ref as name of the branch on pull request" {
  GITHUB_EVENT_NAME='pull_request'

  run /entrypoint.sh

  expectStdOut "
::set-output name=sha-tag::12169ed809255604e557a82617264e9c373faca7
::set-output name=ref-tag::my-branch"

  expectMockCalled "/usr/local/bin/docker login -u USERNAME --password-stdin
/usr/local/bin/docker build -t my/repository:12169ed809255604e557a82617264e9c373faca7 -t my/repository:my-branch .
/usr/local/bin/docker push my/repository:12169ed809255604e557a82617264e9c373faca7
/usr/local/bin/docker push my/repository:my-branch
/usr/local/bin/docker logout"
}

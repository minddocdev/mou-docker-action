# Docker publish action

[![Actions Status](https://github.com/minddocdev/mou-docker-action/workflows/test/badge.svg)](https://github.com/minddocdev/mou-docker-action/actions)

This Action for [Docker](https://www.docker.com/) uses the Git branch or tag as
the [Docker tag](https://docs.docker.com/engine/reference/commandline/tag/)
for building and pushing the container.

Forked from [elgohr/Publish-Docker-Github-Action](https://github.com/elgohr/Publish-Docker-Github-Action)
and edited to handle git branches and tags by default.

## Usage

### Example pipeline

```yaml
name: Publish Docker
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Publish to Registry
      uses: minddocdev/mou-docker-action@master
      with:
        name: myDocker/repository
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
```

## Mandatory Arguments

`name` is the name of the image you would like to push
`username` the login username for the registry
`password` the login password for the registry

## Outputs

`tag` is the git commit sha, which was pushed
`branch-tag` is the detected git branch or tag, which was pushed

## Optional Arguments

### registry

Use `registry` for pushing to a custom registry.
> NOTE: GitHub's Docker registry uses a different path format to Docker Hub, as shown below.
> See [Configuring Docker for use with GitHub Package Registry](https://help.github.com/en/github/managing-packages-with-github-package-registry/configuring-docker-for-use-with-github-package-registry#publishing-a-package)
> for more information.

```yaml
with:
  name: owner/repository/image
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  registry: docker.pkg.github.com
```

### dockerfile

Use `dockerfile` when you would like to explicitly build a Dockerfile.
This might be useful when you have multiple DockerImages.

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  dockerfile: MyDockerFileName
```

### workdir

Use `workdir` when you would like to change the directory for building.

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  workdir: mySubDirectory
```

### context

Use `context` when you would like to change the Docker build context.

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  context: myContextDirectory
```

### buildargs

Use `buildargs` when you want to pass a list of environment variables as [build-args](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg).
Identifiers are separated by comma.
All `buildargs` will be masked, so that they don't appear in the logs.

```yaml
- name: Publish to Registry
  uses: minddocdev/mou-docker-action@master
  env:
    MY_FIRST: variableContent
    MY_SECOND: variableContent
  with:
    name: myDocker/repository
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    buildargs: MY_FIRST,MY_SECOND
```

### cache

Use `cache` when you have big images, that you would only like to build partially (changed layers).
> CAUTION: Docker builds will cache non-repoducable commands, such as installing packages.
> If you use this option, your packages will never update.
> To avoid this, run this action on a schedule with caching **disabled**
> to rebuild the cache periodically.

```yaml
name: Publish to Registry
on:
  push:
    branches:
      - master
  schedule:
    - cron: '0 2 * * 0' # Weekly on Sundays at 02:00
jobs:
  update:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Publish to Registry
      uses: minddocdev/mou-docker-action@master
      with:
        name: myDocker/repository
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
        cache: ${{ github.event_name != 'schedule' }}
```

### tags

Use `tags` when you want to pass a list of environment variables as docker tags,
that will also be push into the registry.
Identifiers are separated by comma.

```yaml
- name: Publish to Registry
  uses: minddocdev/mou-docker-action@master
  with:
    name: myDocker/repository
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
    tags: firsttag,secondtag
```

## Development

Run the tests with

```sh
docker build .
```

#!/bin/bash

ARCHS=linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6

echo -e "\n\nPull request: $TRAVIS_PULL_REQUEST\nRelease tag: $TRAVIS_TAG\nBranch: $TRAVIS_BRANCH\n\n"

if [  "$TRAVIS_PULL_REQUEST" != "false" ]; then
  echo -e "\n\nBuilding pull request without pushing to Docker Hub\n\n"
  docker buildx build  \
    -f alpine.Dockerfile \
    --progress plain \
    --platform=linux/amd64 \
    --platform=linux/arm64 \
    --platform=linux/arm/v7 \
    --platform=linux/arm/v6 \
    .
  [ -z $? ] || exit $?
  docker buildx build  \
    -f debian.Dockerfile \
    --progress plain \
    --platform=linux/amd64 \
    --platform=linux/arm64 \
    --platform=linux/arm/v7 \
    --platform=linux/arm/v6 \
    .
  exit $?
fi

echo $DOCKER_PASSWORD | docker login -u qmcgaw --password-stdin 2>&1

TAG="$TRAVIS_TAG"
if [ -z "$TAG" ] && [ "$TRAVIS_BRANCH" != "master" ]; then
  TAG="$TRAVIS_BRANCH"
fi

LATEST_TAG=latest
ALPINE_TAG=alpine
DEBIAN_TAG=debian
STRETCH_TAG=stretch
if [ ! -z "$TAG" ]; then
  LATEST_TAG="$LATEST_TAG-$TAG"
  ALPINE_TAG="$ALPINE_TAG-$TAG"
  DEBIAN_TAG="$DEBIAN_TAG-$TAG"
  STRETCH_TAG="$STRETCH_TAG-$TAG"
fi

echo "\n\nBuilding Docker images for \"$DOCKER_REPO:$ALPINE_TAG\" and \"$DOCKER_REPO:$LATEST_TAG\"\n\n"
docker buildx build \
    -f alpine.Dockerfile \
    --progress plain \
    --platform="$ARCHS" \
    --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
    --build-arg VCS_REF=`git rev-parse --short HEAD` \
    --build-arg VERSION=$ALPINE_TAG \
    -t $DOCKER_REPO:$LATEST_TAG \
    -t $DOCKER_REPO:$ALPINE_TAG \
    --push \
    .
echo "\n\nBuilding Docker images for \"$DOCKER_REPO:$DEBIAN_TAG\" and \"$DOCKER_REPO:$STRETCH_TAG\"\n\n"
docker buildx build \
    -f debian.Dockerfile \
    --progress plain \
    --platform="$ARCHS" \
    --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
    --build-arg VCS_REF=`git rev-parse --short HEAD` \
    --build-arg VERSION=$STRETCH_TAG \
    -t $DOCKER_REPO:$DEBIAN_TAG \
    -t $DOCKER_REPO:$STRETCH_TAG \
    --push \
    .

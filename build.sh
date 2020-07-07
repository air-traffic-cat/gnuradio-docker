#!/bin/bash

function print_usage {
  echo "Usage:"
  echo "  build.sh -i <image_name> [-p platform_list] [-n] [-r git_version_range]"
  echo "  -n Load built image instead of pushing"
  echo "  -r Check if the image is changed during specified git version range (default to HEAD). "
  echo "     If nothing is changed, the build process is skipped."
}

IMAGE_NAME=""
SHOULD_PUSH=1
PLATFORM="linux/amd64,linux/arm,linux/arm64"
GIT_RANGE="HEAD"

# Parsing arguments
while getopts 'i:np:r:' flag; do
  case "${flag}" in
    i) IMAGE_NAME="${OPTARG}" ;;
    n) SHOULD_PUSH=0 ;;
    p) PLATFORM="${OPTARG}" ;;
    r) GIT_RANGE="${OPTARG}" ;;
  esac
done

# Check if the image_name is valid
if [ ! -d "$IMAGE_NAME" ]; then
  echo "'$IMAGE_NAME' is not a valid image name"
  print_usage
  exit 1
fi

# Check if the source files for the image are changed
echo "git diff-tree --no-commit-id --name-only -r $GIT_RANGE | grep -c \"^$IMAGE_NAME/\""
CHANGED_COUNT=$(git diff-tree --no-commit-id --name-only -r $GIT_RANGE | grep -c "^$IMAGE_NAME/")

echo $CHANGED_COUNT
if [ $CHANGED_COUNT -eq 0 ]; then
  echo "Image '$IMAGE_NAME' not changed in $GIT_RANGE. Nothing to build."
  exit 0
fi

TAG=$(git tag --list 'v*' --points-at HEAD)
VERSION=${TAG:1}
VERSION=${VERSION:-latest}

echo "Building akfish/$IMAGE_NAME:$VERSION for $PLATFORM"

if [ $SHOULD_PUSH == 1 ]; then
  BUILD_FLAGS="--push"
  echo "Image will be pushed to Docker Hub after it's built."
else
  BUILD_FLAGS="--load"
  echo "Image will be loaded locally after it's built."
fi

BUILD_FLAGS="$BUILD_FLAGS --tag akfish/$IMAGE_NAME:$VERSION"
BUILD_FLAGS="$BUILD_FLAGS --platform $PLATFORM"
BUILD_FLAGS="$BUILD_FLAGS --build-arg VERSION=$VERSION"

docker buildx create --use --name $IMAGE_NAME-build
pushd $IMAGE_NAME 
docker buildx build \
  $BUILD_FLAGS \
  .
popd
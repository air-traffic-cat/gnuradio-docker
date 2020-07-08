#!/bin/bash

function print_usage {
  echo "Usage:"
  echo "  build.sh -i <image_name> [-p platform_list] [-n] [-r git_version_range] -m"
  echo "  -n Load built image instead of pushing"
  echo "  -r Check if the image is changed during specified git version range (default to HEAD). "
  echo "     If nothing is changed, the build process is skipped."
  echo "  -m Build manifest"
}

IMAGE_NAME=""
SHOULD_PUSH=1
PLATFORM="linux/amd64,linux/arm,linux/arm64"
GIT_RANGE="HEAD"
FORCED=0
BUILD_MANIFEST=0

# Parsing arguments
while getopts 'fi:np:r:m' flag; do
  case "${flag}" in
    f) FORCED=1 ;;
    i) IMAGE_NAME="${OPTARG}" ;;
    n) SHOULD_PUSH=0 ;;
    p) PLATFORM="${OPTARG}" ;;
    r) GIT_RANGE="${OPTARG}" ;;
    m) BUILD_MANIFEST=1 ;;
  esac
done

PLATFORM_COUNT=$(echo $PLATFORM | tr -cd , | wc -c)

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
  if [ $FORCED == 1 ]; then
    echo "Forced == 1, will build anyway."
  else
    exit 0
  fi
fi

TAG=$(git tag --list 'v*' --points-at HEAD)
VERSION=${TAG:1}
VERSION=${VERSION:-latest}

if [ $BUILD_MANIFEST == 1 ]; then
  echo "Building manifest akfish/$IMAGE_NAME:$VERSION for $PLATFORM"
  MANIFEST_FLAGS="akfish/$IMAGE_NAME:$VERSION"
  IFS=',' read -ra P <<< "$PLATFORM"
  for i in "${P[@]}"; do
    MANIFEST_FLAGS="$MANIFEST_FLAGS --amend akfish/$IMAGE_NAME:$VERSION-${i//\//-}"
  done

  pushd $IMAGE_NAME 
  docker manifest create $MANIFEST_FLAGS
  RET=$?
  if [ $RET -ne 0 ]; then
    echo "Build manifest failed (exit code = $RET)"
    exit 1
  fi
  popd

  if [ $SHOULD_PUSH == 1 ]; then
    echo "Pushing manifest..."
    docker manifest push "akfish/$IMAGE_NAME:$VERSION"
  else
    echo "Manifest will not be pushed"
  fi

  exit 0
fi

echo "Building akfish/$IMAGE_NAME:$VERSION for $PLATFORM"

if [ $PLATFORM_COUNT -ne 0 ]; then
  if [ $SHOULD_PUSH == 1 ]; then
    BUILD_FLAGS="--push"
    echo "Image will be pushed to Docker Hub after it's built."
  else
    BUILD_FLAGS="--load"
    echo "Image will be loaded locally after it's built."
  fi

  BUILD_FLAGS="$BUILD_FLAGS --tag akfish/$IMAGE_NAME:$VERSION"
  BUILD_FLAGS="$BUILD_FLAGS --build-arg VERSION=$VERSION"

  echo "Multi-arch build with buildx..."
  BUILD_FLAGS="$BUILD_FLAGS --platform $PLATFORM"
  docker buildx create --use --name $IMAGE_NAME-build
  pushd $IMAGE_NAME 
  docker buildx build \
    $BUILD_FLAGS \
    .
  popd
else
  echo "Single platform build"
  BUILD_FLAGS=
  BUILD_FLAGS="$BUILD_FLAGS --tag akfish/$IMAGE_NAME:$VERSION-${PLATFORM//\//-}"
  BUILD_FLAGS="$BUILD_FLAGS --build-arg VERSION=$VERSION"
  BUILD_FLAGS="$BUILD_FLAGS --build-arg TARGETPLATFORM=$PLATFORM"
  pushd $IMAGE_NAME 
  docker build $BUILD_FLAGS .

  RET=$?
  if [ $RET -ne 0 ]; then
    echo "Build image failed (exit code = $RET)"
    exit 1
  fi
  popd

  if [ $SHOULD_PUSH == 1 ]; then
    echo "Image will be pushed to Docker Hub."
    docker push "akfish/$IMAGE_NAME:$VERSION-${PLATFORM//\//-}"
  else
    echo "Image will not be pushed."
  fi
fi
#!/bin/bash -x

echo "Configure volk for $1 build"
if [ $1 == "linux/amd64" ]; then
  cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=$(which python3) \
    ../
else
  cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=$(which python3) \
    ../
fi
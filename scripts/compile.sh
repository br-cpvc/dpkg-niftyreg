#!/bin/bash

# terminate script if a command failes with error code other than 0
set -e
#set -x

cwd=`pwd`

tmpdir=$cwd/tmp
mkdir -p $tmpdir

# cuda 6.5.19_linux_64.run link copied from:
# https://developer.nvidia.com/cuda-downloads-geforce-gtx9xx
cudarun=$tmpdir/cuda_6.5.19_linux_64.run
if [ ! -f $cudarun ]; then
    wget http://developer.download.nvidia.com/compute/cuda/6_5/rel/installers/cuda_6.5.19_linux_64.run -O $cudarun
fi
md5sum -c cuda_6.5.19_linux_64.run.md5  # 74014042f92d3eade43af0da5f65935e

cudadir=$tmpdir/cuda
if [ ! -d $cudadir ]; then
    echo "extracting $cudarun"
    sh $cudarun --extract=$tmpdir
    sh $tmpdir/cuda-linux64-rel-6.5.19-18849900.run -noprompt -nosymlink -prefix=$cudadir
fi

driverdir=$tmpdir/NVIDIA-Linux-x86_64-343.19
if [ ! -d $driverdir ]; then
    cd $tmpdir
    sh NVIDIA-Linux-x86_64-343.19.run -x
    cd $cwd
    ln -s $driverdir/libcuda.so.343.19 $cudadir/lib64/libcuda.so
fi

# make
rm -rf usr
mkdir -p $tmpdir/build
cd $tmpdir/build
CC=gcc-4.8 CXX=g++-4.8 cmake ../../deps/niftyreg/ \
-DCMAKE_INSTALL_PREFIX=../install \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_TESTING=OFF \
-DUSE_CUDA=ON \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_CXX_FLAGS="-L$cudadir/lib64" \
-DCUDA_TOOLKIT_ROOT_DIR=$cudadir \
-DCUDA_NVCC_FLAGS="-ccbin gcc-4.8 -gencode arch=compute_20,code=sm_20 -gencode arch=compute_30,code=sm_30 -gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52 -gencode arch=compute_52,code=compute_52"
# CC=gcc-4.8 CXX=g++-4.8, and -ccbin gcc-4.8, was added to make it build on ubuntu 16.04
# see: https://stackoverflow.com/questions/6622454/cuda-incompatible-with-my-gcc-version

n=`nproc --ignore=1`
make -j $n
make install
cd ..

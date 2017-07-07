#!/bin/bash
if [ ! -d se ]; then mkdir se; fi
if [ ! -d build ]; then mkdir build; fi
if [ ! -d ccache ]; then mkdir ccache; fi
docker run --rm -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) -e SYMENGINE_PREFIX=/se -v $(pwd)/se:/se -v $(pwd)/build:/build -v $(pwd)/ccache:/ccache -i ${1:-"bjodah/se_llvm"} /bin/bash -sxe <<'EOF'
cd $SYMENGINE_PY_SRC
git pull
cd $SYMENGINE_SRC
git pull
git checkout $(cat ${SYMENGINE_PY_SRC}/symengine_version.txt)
cd /build
source activate $CONDA_ENV_DIR
export CXX="ccache g++-4.9"
export CC="ccache gcc-4.9"
export CCACHE_DIR=/ccache
ccache -M 400M
export CPPFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0"
cmake -DCMAKE_INSTALL_PREFIX=$SYMENGINE_PREFIX -DCMAKE_BUILD_TYPE:STRING="Release" -DWITH_LLVM:BOOL=ON -DINTEGER_CLASS:STRING=gmp -DBUILD_SHARED_LIBS:BOOL=ON -DWITH_MPC=yes $SYMENGINE_SRC
make -j 4
make install
ctest --output-on-failure
cp -r $SYMENGINE_SRC/benchmarks .
cd benchmarks/
compile_flags=`cmake --find-package -DNAME=SymEngine -DSymEngine_DIR=$SYMENGINE_PREFIX/lib/cmake/symengine -DCOMPILER_ID=GNU -DLANGUAGE=CXX -DMODE=COMPILE`
link_flags=`cmake --find-package -DNAME=SymEngine -DSymEngine_DIR=$SYMENGINE_PREFIX/lib/cmake/symengine  -DCOMPILER_ID=GNU -DLANGUAGE=CXX -DMODE=LINK`

${CXX} -std=c++0x $compile_flags expand1.cpp $link_flags
export LD_LIBRARY_PATH=$SYMENGINE_PREFIX/lib:$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
./a.out
echo "Checking whether all header files are installed:"
python $SYMENGINE_SRC/bin/test_make_install.py $CONDA_PREFIX/include/symengine/ $SYMENGINE_SRC/symengine
chown $HOST_UID:$HOST_GID -R /build /ccache
EOF

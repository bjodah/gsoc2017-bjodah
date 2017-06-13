#!/bin/bash
if [ ! -d build ]; then mkdir build; fi
if [ ! -d ccache ]; then mkdir ccache; fi
docker run --rm -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) -v $(pwd)/build:/build -v $(pwd)/ccache:/ccache -i symeng /bin/bash -s <<'EOF'
SOURCE_DIR=/opt/symengine
cd $SOURCE_DIR
git checkout v0.3.0
cd /build
source activate $our_install_dir
export CXX="ccache clang++"
export CC="ccache clang"
export CCACHE_DIR=/ccache
ccache -M 400M
export CPPFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0"
cmake -DCMAKE_INSTALL_PREFIX=$our_install_dir -DCMAKE_BUILD_TYPE:STRING="Release" -DWITH_LLVM:BOOL=ON -DINTEGER_CLASS:STRING=gmp -DBUILD_SHARED_LIBS:BOOL=ON -DWITH_MPC=yes $SOURCE_DIR
make -j 4
make install
ctest --output-on-failure
cp -r $SOURCE_DIR/benchmarks .
cd benchmarks/
compile_flags=`cmake --find-package -DNAME=SymEngine -DSymEngine_DIR=$our_install_dir/lib/cmake/symengine -DCOMPILER_ID=GNU -DLANGUAGE=CXX -DMODE=COMPILE`
link_flags=`cmake --find-package -DNAME=SymEngine -DSymEngine_DIR=$our_install_dir/lib/cmake/symengine  -DCOMPILER_ID=GNU -DLANGUAGE=CXX -DMODE=LINK`

${CXX} -std=c++0x $compile_flags expand1.cpp $link_flags
export LD_LIBRARY_PATH=$our_install_dir/lib:$LD_LIBRARY_PATH
./a.out
echo "Checking whether all header files are installed:"
python $SOURCE_DIR/bin/test_make_install.py $our_install_dir/include/symengine/ $SOURCE_DIR/symengine
chown $HOST_UID:$HOST_GID -R /build /ccache
EOF

#!/bin/bash
if [ ! -d se ]; then
    >&2 echo "Compile symenginge first (found no dir ./se/)"
fi
if [[ $# -eq 0 ]]; then
    ARGS=""
elif [[ $# -eq 1 ]]; then
    ARGS="-v $1:/opt/symengine.py"
else
    2>&1 echo "0 or 1 argument supported"
fi
docker run --rm -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) -e SYMENGINE_PREFIX=/se -v $(pwd)/se:/se $ARGS -i bjodah/se_llvm /bin/bash -s <<'EOF'
export CC=gcc-4.9
export CXX=g++-4.9
cd $SYMENGINE_PY_SRC
source activate $CONDA_ENV_DIR
python setup.py build_ext -i --symengine-dir=$SYMENGINE_PREFIX
python -m nose
chown $HOST_UID:$HOST_GID -R .
EOF

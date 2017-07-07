FROM ubuntu:xenial
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV CONDA_ENV_DIR /opt/condaenv
ENV PATH /opt/miniconda3/bin:$PATH
ENV SYMENGINE_SRC /opt/symengine
ENV SYMENGINE_PY_SRC /opt/symengine.py
RUN apt-get update && \
    apt-get --quiet --assume-yes install locales && \
    locale-gen en_US.UTF-8 && \
    echo "path-exclude /usr/share/doc/*" >/etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo "path-include /usr/share/doc/*/copyright" >>/etc/dpkg/dpkg.cfg.d/01_nodoc && \
    apt-get update && \
    apt-get --quiet --assume-yes --no-install-recommends install wget git binutils-dev bzip2 make g++-4.9 gcc-4.9 && \
    apt-get clean && \
    wget --no-check-certificate --no-verbose "https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O miniconda3.sh && \
    bash miniconda3.sh -b -p /opt/miniconda3 && \
    rm miniconda3.sh && \
    conda config --set always_yes yes --set changeps1 no && \
    conda config --add channels conda-forge --force && \
    conda create -q -p $CONDA_ENV_DIR ccache gmp=6.1.1 mpc=1.0.3 llvmdev=3.8 cmake=3.6.2 nose cython numpy && \
    export LLVM_DIR=$CONDA_ENV_DIR/share/llvm/ && \
    cd /opt && git clone git://github.com/symengine/symengine.git && \
    cd /opt && git clone git://github.com/symengine/symengine.py.git && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN conda install -p $CONDA_ENV_DIR -c conda-forge sympy

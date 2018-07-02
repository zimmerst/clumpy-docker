FROM centos:latest
MAINTAINER stephan zimmer <zimmerst@gmail.com>
ARG root_version="6.09.02"
LABEL description="CLUMPY CONTAINER"
LABEL version="2.0"

RUN yum -y install epel-release
RUN yum -y install svn gcc-c++ bzip2 git vim libpng libjpeg \
     python-devel gsl libSM libX11 libXext libXpm libXft gsl-devel python-pip make cmake3\
     && yum -y clean all
RUN pip install --upgrade pip && pip install jupyter
RUN ln -s /usr/bin/cmake3 /usr/bin/cmake

# Set ROOT environment
ENV ROOTSYS         "/opt/root"
ENV PATH            "$ROOTSYS/bin:$ROOTSYS/bin/bin:$PATH"
ENV LD_LIBRARY_PATH "$ROOTSYS/lib:$LD_LIBRARY_PATH"
ENV PYTHONPATH      "$ROOTSYS/lib:$PYTHONPATH"

ADD https://root.cern.ch/download/root_v${root_version}.Linux-centos7-x86_64-gcc4.8.tar.gz /var/tmp/root.tar.gz
RUN tar xzf /var/tmp/root.tar.gz -C /opt && rm /var/tmp/root.tar.gz

# cfitsio
RUN oldpath=`pwd` && cd /var/tmp \
&& curl -o cfitsio_latest.tar.gz ftp://heasarc.gsfc.nasa.gov/software/fitsio/c/cfitsio_latest.tar.gz \
&& tar zxvf cfitsio_latest.tar.gz \
&& cd cfitsio \
&& ./configure --prefix=/usr\
&& make -j 2 \
&& make install \
&& make clean \
&& cd $oldpath \
&& rm -Rf /tmp/cfitsio*
ENV CFITSIO_LIB_DIR=/usr/lib
ENV CFITSIO_INC_DIR=/usr/include

# healpix
RUN yum -y install gcc-gfortran gsl-devel git
ENV CLUMPY_INSTALL=/opt/clumpy
# download clumpy
RUN git clone https://gitlab.com/clumpy/CLUMPY.git /opt/clumpy
# build it.
RUN cd ${CLUMPY_INSTALL} && mkdir -p build && cd build && \
    cmake --DCMAKE_INSTALL_PREFIX=${CLUMPY_INSTALL} /opt/clumpy && \
    make -j$(grep -c processor /proc/cpuinfo)

ENV CLUMPY=/opt/clumpy
ENV PATH=${CLUMPY}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CLUMPY}/lib:${LD_LIBRARY_PATH}


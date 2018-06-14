FROM centos:latest
MAINTAINER stephan zimmer <zimmerst@gmail.com>
ARG root_version="6.09.02"
LABEL description="CLUMPY CONTAINER"
LABEL version="1.0"

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

# healpix
RUN yum -y install gcc-gfortran
ENV HEALPIX=/opt/healpix
RUN mkdir -p $HEALPIX/lib $HEALPIX/bin $HEALPIX/include

# inspired from: https://github.com/mserylak/pulsar_docker/blob/master/Dockerfile
RUN cd /var/tmp && \
    svn co svn://svn.code.sf.net/p/healpix/code/branches/branch_v320r670 && \
    cd branch_v320r670 && \
    mkdir bin lib include && \
    cp Makefile.in Makefile && \
    awk '!x{x=sub("ALL.*=.*c-void cpp-void f90-void healpy-void.*","ALL = c-all cpp-all f90-all")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("TESTS.*=.*c-void cpp-void f90-void healpy-void.*","TESTS = c-test cpp-test f90-test")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("CLEAN.*=.*c-void cpp-void f90-void healpy-void.*","CLEAN = c-clean cpp-clean f90-clean")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("TIDY.*=.*c-void cpp-void f90-void healpy-void.*","TIDY = c-tidy cpp-tidy f90-tidy")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("DISTCLEAN.*=.*c-void cpp-void f90-void healpy-void.*","DISTCLEAN = c-distclean cpp-distclean f90-distclean")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("HEALPIX=","HEALPIX = '"$HEALPIX"'")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_BINDIR.*=.*","F90_BINDIR = '"$HEALPIX"'/bin")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_INCDIR.*=.*","F90_INCDIR = '"$HEALPIX"'/include")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_LIBDIR.*=.*","F90_LIBDIR = '"$HEALPIX"'/lib")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("FITSDIR.*=.*","FITSDIR = /usr/lib/x86_64-linux-gnu")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("LIBFITS.*=.*","LIBFITS = cfitsio")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_BUILDDIR.*=.*","F90_BUILDDIR = '"$HEALPIX"'/build")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_FFTSRC.*=.*","F90_FFTSRC = healpix_fft")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_FC.*=.*","F90_FC = gfortran")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_FFLAGS.*=.*","F90_FFLAGS = -O3 -I$(F90_INCDIR) -DGFORTRAN -fno-second-underscore -fPIC")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_CC.*=.*","F90_CC = gcc")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_CFLAGS.*=.*","F90_CFLAGS = -O3 -std=c99 -DgFortran -fPIC")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_LDFLAGS.*=.*","F90_LDFLAGS = -L$(F90_LIBDIR) -L$(FITSDIR) -lhealpix -lhpxgif -l$(LIBFITS) -Wl,-R$(FITSDIR)")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_AR.*=.*","F90_AR = ar -rsv")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_I8FLAG.*=.*","F90_I8FLAG = -fdefault-integer-8")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_LIBSUFFIX.*=.*","F90_LIBSUFFIX = .a")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_MOD.*=.*","F90_MOD = mod")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_MODDIR.*=.*","F90_MODDIR = \"-J\"")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("F90_OS.*=.*","F90_OS = Linux")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("C_CC.*=.*","C_CC = gcc")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("C_PIC.*=.*","C_PIC = -fPIC")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("C_OPT.*=.*","C_OPT = -O2 -Wall")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("C_LIBDIR.*=.*","C_LIBDIR = '"$HEALPIX"'/lib")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("C_INCDIR.*=.*","C_INCDIR = '"$HEALPIX"'/include")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("C_AR.*=.*","C_AR = ar -rsv")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("C_WITHOUT_CFITSIO.*=.*","C_WITHOUT_CFITSIO = 0")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("C_CFITSIO_INCDIR.*=.*","C_CFITSIO_INCDIR = /usr/include")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("C_CFITSIO_LIBDIR.*=.*","C_CFITSIO_LIBDIR = /usr/lib/x86_64-linux-gnu")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("C_WLRPATH.*=.*","C_WLRPATH = -Wl,-R/usr/lib/x86_64-linux-gnu")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("C_ALL.*=.*","C_ALL = c-static c-shared")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("HEALPIX_TARGET.*=.*","HEALPIX_TARGET = generic_gcc")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("CFITSIO_EXT_LIB.*=.*","CFITSIO_EXT_LIB = -L/usr/lib/x86_64-linux-gnu -lcfitsio")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    awk '!x{x=sub("CFITSIO_EXT_INC.*=.*","CFITSIO_EXT_INC = -I/usr/include")}1' Makefile > temp.tmp && mv temp.tmp Makefile && \
    make -j $(nproc) && \
    make test && \
    cp -rpv src/cxx/generic_gcc/include/*.h /opt/healpix/include/. && \
    cp -rpv src/cxx/generic_gcc/lib/* /opt/healpix/lib/. && \
    cp -rpv data /opt/healpix/. && \
    cp -rpv src/cxx/generic_gcc/bin/* /opt/healpix/bin/.

ENV FITSIOLIBS_PATH=/usr/lib
ENV FITSIOINCLUDE_PATH=/usr/include
ENV HEALPIXCPPLIBS_PATH=/opt/healpix/lib
ENV HEALPIXCPPINCLUDE_PATH=/opt/healpix/include
ENV HEALPIXF90LIBS_PATH=/opt/healpix/lib
ENV HEALPIXF90INCLUDE_PATH=/opt/healpix/include

RUN mkdir -p /opt/clumpy
ADD https://lpsc.in2p3.fr/clumpy/download/CLUMPY_v2015.06.CPC_corr2.tar.gz /opt/clumpy.tar.gz
RUN tar xzvf /opt/clumpy.tar.gz -C /opt/clumpy && \
    ln -s /opt/clumpy/CLUMP* /opt/clumpy/latest && rm -f /opt/clumpy.tar.gz && \
    cd /opt/clumpy/latest && make

ARG VERSION
FROM --platform=$TARGETPLATFORM akfish/gnuradio-base:${VERSION}
ARG TARGETPLATFORM

ENV num_threads 2
ENV volk_version 2.3.0
ENV gr_version 3.8.1.0

WORKDIR /opt/volk
RUN git status
RUN mkdir build && cd build
WORKDIR /opt/volk/build
COPY configure_volk.sh configure.sh
RUN chmod +x ./configure.sh
RUN ./configure.sh ${TARGETPLATFORM} 
RUN make -j${num_threads}
RUN make install
# RUN make test
RUN ldconfig

WORKDIR /opt/gnuradio
RUN git status
RUN mkdir build && cd build
WORKDIR /opt/gnuradio/build
RUN cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=$(which python3) \
    -DENABLE_DEFAULT=False \
    -DENABLE_VOLK=True \
    -DENABLE_INTERNAL_VOLK=OFF \
    -DENABLE_PYTHON=True \
    -DENABLE_GNURADIO_RUNTIME=True \
    -DENABLE_GR_BLOCKS=True \
    -DENABLE_GR_FFT=True \
    -DENABLE_GR_FILTER=True \
    -DENABLE_GR_ANALOG=True \
    -DENABLE_GR_AUDIO=True \
    ../
    # -DENABLE_GR_QTGUI=OFF \
    # -DENABLE_GRC=OFF \
    # -DENABLE_GR_UHD=OFF \
    # -DENABLE_DOXYGEN=OFF \
    # -DENABLE_SPHINX=OFF \
    # -DENABLE_INTERNAL_VOLK=OFF \
RUN make -j${num_threads}
RUN make install
RUN ldconfig
# Link built python packages
RUN ln -s /usr/local/lib/python3/dist-packages/* /usr/local/lib/python3.6/dist-packages
RUN python3 --version
RUN echo "from gnuradio import gr\nprint(gr.version())" | python3
FROM --platform=$TARGETPLATFORM phusion/baseimage:bionic-1.0.0

ENV volk_version 2.3.0
ENV gr_version 3.8.1.0

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN apt-get update

RUN apt-get install -y \
    build-essential \
    git \
    cmake \
    liblog4cpp5-dev \
    libboost-all-dev \
    libgmp-dev \
    libfftw3-dev \
    libgsl-dev \
    libzmq3-dev \
    python3-mako \
    python3-numpy \
    python3-yaml \
    python3-click \
    python3-click-plugins \
    python3-zmq \
    python3-scipy \
    python3-pip \
    swig

RUN pip3 install six

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt/
RUN while ! git clone https://github.com/gnuradio/volk.git; do echo Clone failed, retry...; done
WORKDIR /opt/volk
RUN git checkout tags/v${volk_version} -b v${volk_version}
RUN git status

WORKDIR /opt/
RUN while ! git clone --branch v${gr_version} --depth=1 https://github.com/gnuradio/gnuradio.git; do echo Clone failed, retry...; done
WORKDIR /opt/gnuradio
RUN git checkout tags/v${gr_version} -b v${gr_version}
RUN git status

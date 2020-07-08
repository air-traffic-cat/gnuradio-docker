FROM --platform=$TARGETPLATFORM phusion/baseimage:bionic-1.0.0
# FROM phusion/baseimage:bionic-1.0.0

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN apt-get update

RUN apt-get install -y \
    build-essential \
    git \
    cmake \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    libglib2.0-dev \
    python3 \
    python3-numpy \
    python3-pip

RUN apt-get build-dep -y librtlsdr-dev
RUN pip3 install pipenv

WORKDIR /opt/
RUN while ! git clone git://git.osmocom.org/rtl-sdr.git; do echo Clone failed, retry...; done
WORKDIR /opt/rtl-sdr
RUN mkdir build
WORKDIR /opt/rtl-sdr/build
RUN cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON
RUN make
RUN make install
RUN ldconfig

# RUN pip3 install pyrtlsdr
# RUN python3 -c "from rtlsdr import *"

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV FREECAD_PATH=/usr/lib

ARG FREECAD_VERSION=1.0.2
ARG PY_VERSION=311
ARG ARCH=x86_64
ARG FREECAD_IMAGE=FreeCAD_${FREECAD_VERSION}-conda-Linux-${ARCH}-py${PY_VERSION}.AppImage
ARG IMAGEPATH=https://github.com/FreeCAD/FreeCAD-Bundle/releases/download/${FREECAD_VERSION}/
ARG SHA=${FREECAD_IMAGE}-SHA256.txt

RUN apt update && apt install -y curl xvfb sudo

RUN mkdir /opt/freecad
WORKDIR /opt/freecad

RUN curl -o ${FREECAD_IMAGE} -L ${IMAGEPATH}/${FREECAD_IMAGE} \
    && curl -o ${SHA} -L ${IMAGEPATH}/${SHA}  \
    && sha256sum -c ${SHA}

RUN chmod a+x ./${FREECAD_IMAGE}
RUN ./${FREECAD_IMAGE} --appimage-extract && rm -rf ./${FREECAD_IMAGE}

# Install elmer
RUN apt-get install -y software-properties-common \
    && add-apt-repository ppa:elmer-csc-ubuntu/elmer-csc-ppa \
    && apt-get update && sudo apt-get -y install elmerfem-csc

# Install Z88
ARG Z88_DIR=/opt/z88/Z88AuroraV5/bin/ubuntu64
ARG Z88_IMAGE=z88aurorav5_en.tar.gz
RUN mkdir /opt/z88
WORKDIR /opt/z88

RUN curl -o ${Z88_IMAGE} -L https://download.z88.de/z88aurora/V5/${Z88_IMAGE}
RUN tar -xpzvf ${Z88_IMAGE} \
    && sudo chmod -R 777 Z88AuroraV5

# Clean up 
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /opt/z88/${Z88_IMAGE}

# Setup User
ARG USERNAME=user
ARG UID=1000
ARG GID=1000

# Create the user, add to sudo group, and allow passwordless sudo
RUN groupadd --gid $GID $USERNAME \
 && useradd --uid $UID --gid $GID -m -s /bin/bash $USERNAME \
 && usermod -aG sudo $USERNAME \
 && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME \
 && chmod 0440 /etc/sudoers.d/$USERNAME

ENV HOME=/home/${USERNAME}
WORKDIR /home/${USERNAME}
USER ${USERNAME}

ENV PATH="/opt/freecad/squashfs-root/usr/bin:${Z88_DIR}:$PATH"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${Z88_DIR}"
CMD ["freecad"]

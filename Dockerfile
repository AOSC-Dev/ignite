FROM ubuntu:24.04
RUN apt-get install -U -y ca-certificates && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY --chown=0:0 assets/ia16-gcc.sources /etc/apt/sources.list.d/ia16-gcc.sources
COPY --chown=0:0 assets/jwt27-djgpp.sources /etc/apt/sources.list.d/jwt27-djgpp.sources
# Install essential tools and DJGPP cross-compilers
RUN apt-get full-upgrade -U -y && apt-get install -y \
    build-essential dos2unix \
    curl \
    wget \
    git-core \
    bzip2 xz-utils libarchive-tools \
    meson pkg-config \
    binutils-djgpp gcc-djgpp \
    nasm jwasm \
    upx \
    dosfstools mtools \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
# Un-comment the following to install IA16-GCC cross-compiler (for building 16-bit DOS programs)
# RUN apt-get install -U -y binutils-ia16-elf gcc-ia16-elf && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Open-Watcom v2 (and delete unnecessary files to save space)
RUN wget -c https://github.com/open-watcom/open-watcom-v2/releases/download/2026-08-01-Build/ow-snapshot.tar.xz \
    && echo "6279e1bf7aea4ceba24539d7924f095142047fa55d352b3ba96f33c81ededd32  ow-snapshot.tar.xz" | sha256sum -c - \
    && mkdir -p /opt/owlinux && tar -C /opt/owlinux -xf ow-snapshot.tar.xz \
    && rm ow-snapshot.tar.xz \
    && rm -rf /opt/owlinux/binp /opt/owlinux/binl /opt/owlinux/binw /opt/owlinux/binb64 /opt/owlinux/arm* \
       /opt/owlinux/binnt* /opt/owlinux/bino64 /opt/owlinux/setup /opt/owlinux/uninstal.exe

LABEL org.opencontainers.image.source=https://github.com/AOSC-Dev/ignite
LABEL org.opencontainers.image.description="AOSC Afterglow Ignite Build Environment"

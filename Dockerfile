FROM ubuntu:24.04
RUN apt-get install -U -y ca-certificates && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY --chown=0:0 assets/ia16-gcc.sources /etc/apt/sources.list.d/ia16-gcc.sources
COPY --chown=0:0 assets/jwt27-djgpp.sources /etc/apt/sources.list.d/jwt27-djgpp.sources
# Install essential tools and IA16/DJGPP cross-compilers
RUN apt-get install -U -y \
    build-essential \
    curl \
    wget \
    git-core \
    bzip2 xz-utils libarchive-tools \
    binutils-ia16-elf gcc-ia16-elf \
    binutils-djgpp gcc-djgpp \
    nasm jwasm \
    upx \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
# Install Open-Watcom v2 (and delete unnecessary files to save space)
RUN wget -c https://github.com/open-watcom/open-watcom-v2/releases/download/2026-08-01-Build/ow-snapshot.tar.xz \
    && mkdir -p /opt/owlinux && tar -C /opt/owlinux -xf ow-snapshot.tar.xz \
    && rm ow-snapshot.tar.xz \
    && rm -rf /opt/owlinux/binp /opt/owlinux/binl /opt/owlinux/binw /opt/owlinux/binb64 /opt/owlinux/arm* \
       /opt/owlinux/binnt* /opt/owlinux/bino64 /opt/owlinux/setup /opt/owlinux/uninstal.exe

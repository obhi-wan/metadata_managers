#
# dupeguru Dockerfile
#
# https://github.com/jlesage/docker-dupeguru
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.16-v4.5.3

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG DUPEGURU_VERSION=4.3.1

# Define software download URLs.
ARG DUPEGURU_URL=https://github.com/arsenetar/dupeguru/archive/${DUPEGURU_VERSION}.tar.gz

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN \
    add-pkg \
        py3-qt5 \
        # Needed for dark mode support.
        adwaita-qt \
        # Need a font.
        font-croscore \
        mesa-dri-gallium \
    && \
    # Save some space by removing unused DRI drivers.
    find /usr/lib/xorg/modules/dri/ -type f ! -name swrast_dri.so -exec echo "Removing {}..." ';' -delete

# Install dupeGuru.
RUN \
    # Install packages needed by the build.
    add-pkg --virtual build-dependencies \
        build-base \
        python3-dev \
        py3-pip \
        gettext \
        curl \
        && \
    # Download the dupeGuru package.
    echo "Downloading dupeGuru..." && \
    mkdir dupeguru && \
    curl -L -# ${DUPEGURU_URL} | tar xz --strip 1 -C dupeguru && \
    # Install Python dependencies.
    pip3 --no-cache-dir install -r dupeguru/requirements.txt && \
    # Compile dupeGuru.
    echo "Compiling dupeGuru..." && \
    cd dupeguru && \
    make PREFIX=/usr/ NO_VENV=1 install && \
    cd .. && \
    rm -r /usr/share/applications && \
    find /usr/share/dupeguru -type d -name tests | xargs rm -r && \
    # Enable direct file deletion by default.
    #sed-patch 's/self.direct = False/self.direct = True/' /usr/share/dupeguru/core/gui/deletion_options.py && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/dupeguru-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "dupeGuru" && \
    set-cont-env APP_VERSION "$DUPEGURU_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    set-cont-env TRASH_DIR "/trash" && \
    true

# Define mountable directories.
VOLUME ["/storage"]
VOLUME ["/trash"]

# Metadata.
LABEL \
    org.label-schema.name="dupeguru" \
    org.label-schema.description="Docker container for dupeGuru" \
    org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
    org.label-schema.vcs-url="https://github.com/jlesage/docker-dupeguru" \
    org.label-schema.schema-version="1.0"

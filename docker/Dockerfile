# ================================
# Build image
# ================================
FROM swift:5.7-jammy as builder

# Install updates and set locales to en_US.UTF-8.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y locales locales-all python3 rsync \
    && rm -rf /var/lib/apt/lists/*

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN swift package resolve

# Copy entire repo into container
COPY . .

# Planning build
RUN python3 build-script.py --build --configuration release --static-swift-stdlib

# Makedir
# RUN mkdir -p Public Resources

# Switch to the staging area
WORKDIR /staging

# Copy main executable to staging area
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/swift-blog" ./

# Copy resources bundled by SPM to staging area
RUN find -L "$(swift build --package-path /build -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \;

# Uncomment the next line if you need to load resources from the `Public` directory.
# Ensure that by default, neither the directory nor any of its contents are writable.
# RUN mv /build/Public Public && mv /build/Resources Resources

# ================================
# Run image
# ================================
FROM ubuntu:jammy

# Make sure all system packages are up to date.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && rm -r /var/lib/apt/lists/*

# Create a vapor user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=builder --chown=vapor:vapor /staging /app

# Ensure all further commands run as the vapor user
USER vapor:vapor

# Let Docker bind to port 8080
EXPOSE 8080

# Start the Vapor service when the image is run, default to listening on 8080 in production environment
ENTRYPOINT ["/app/swift-blog"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]

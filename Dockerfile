FROM debian:bookworm-slim AS build

ARG FLUTTER_VERSION=3.47.2
ARG FLUTTER_SHA256=447878859d01ca9bfdb99a85f245af07ed8a15fedcd9d189c4749e8e92d1f185

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && curl --fail --location --retry 3 \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      --output /tmp/flutter.tar.xz \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum --check --strict \
    && tar --extract --xz --file=/tmp/flutter.tar.xz --directory=/opt \
    && rm /tmp/flutter.tar.xz

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN git config --global --add safe.directory /opt/flutter

WORKDIR /app
COPY client/pubspec.yaml client/pubspec.lock ./
RUN flutter pub get

COPY client/ ./
RUN flutter build web --release

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 10000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost:10000/ >/dev/null || exit 1

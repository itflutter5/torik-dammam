FROM ghcr.io/cirruslabs/flutter:3.47.2 AS build

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

FROM ghcr.io/cirruslabs/flutter:3.19.6 AS build

ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn

WORKDIR /app
COPY dracu_app/ .

RUN flutter pub get
RUN flutter build web --release \
    --dart-define=API_URL=http://localhost:8889

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80

# Stage 1: build Flutter web
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app
COPY . .

RUN flutter pub get

ARG AUTH_URL=http://localhost:8000/api/v1/auth
ARG PROFILE_URL=http://localhost:8080/profile/api/v1
ARG CASE_GO_URL=http://localhost:8081/api/v1/case_go
ARG CASE_PROFILE_URL=http://localhost:8082/api/v1/case_go

RUN flutter build web --release \
    --dart-define=AUTH_URL=$AUTH_URL \
    --dart-define=PROFILE_URL=$PROFILE_URL \
    --dart-define=CASE_GO_URL=$CASE_GO_URL \
    --dart-define=CASE_PROFILE_URL=$CASE_PROFILE_URL

# Stage 2: serve with nginx
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

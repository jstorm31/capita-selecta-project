FROM swift:4.2

WORKDIR /app
COPY . .

# Install dependencies
RUN apt-get update && apt-get install -y libssl-dev libicu-dev

# Build
RUN swift package clean
RUN swift build -c release
RUN mkdir /app/bin
RUN mv `swift build -c release --show-bin-path` /app/bin
EXPOSE 8080

ENTRYPOINT ./bin/release/Run serve --env local \
  --hostname 0.0.0.0

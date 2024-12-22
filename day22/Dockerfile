FROM denisgolius/zig:0.13.0 AS builder
WORKDIR /src
COPY . .
COPY input.txt .
RUN zig build-exe main.zig -femit-bin=./aoc

FROM alpine:latest
WORKDIR /app
COPY --from=builder /src/aoc .
CMD ["./aoc"]
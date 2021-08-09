FROM rust:1.50.0 AS builder
RUN apt-get update && apt-get install -y cmake
COPY . lighthouse
ARG PORTABLE
ENV PORTABLE $PORTABLE
# build lighthouse directly with a cargo build command, bypassing the makefile
RUN cd lighthouse && LD_LIBRARY_PATH=/lighthouse/libvoidstar/ RUSTFLAGS="-Cpasses=sancov -Cllvm-args=-sanitizer-coverage-level=3 -Cllvm-args=-sanitizer-coverage-trace-pc-guard -Ccodegen-units=1 -L/lighthouse/libvoidstar/ -lvoidstar" cargo build --release --manifest-path lighthouse/Cargo.toml --target x86_64-unknown-linux-gnu --features modern --verbose --bin lighthouse

# build lcli binary directly with cargo install command, bypassing the makefile
RUN cargo install --path lcli --force --locked --features portable

FROM debian:buster-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
  libssl-dev \
  ca-certificates \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \

# create and move the libvoidstar file
RUN mkdir libvoidstar
COPY --from=builder /lighthouse/libvoidstar/libvoidstar.so /libvoidstar/libvoidstar.so

# set the env variable to avoid having to always set it
ENV LD_LIBRARY_PATH=/libvoidstar
# move the lighthouse binary and lcli binary
COPY --from=builder /lighthouse/target/x86_64-unknown-linux-gnu/release/lighthouse /usr/local/bin/lighthouse
COPY --from=builder  /lighthouse/target/release/lcli /usr/local/bin/lcli
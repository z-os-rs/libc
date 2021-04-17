#!/usr/bin/env sh

# Checks that libc does not contain breaking changes for the following targets.

set -ex

OS=${1}

echo "Testing Semver on ${OS}"

if ! rustc --version | grep -E "nightly" ; then
    echo "Building semverver requires a nightly Rust toolchain"
    exit 1
fi

rustup component add rustc-dev llvm-tools-preview

# Should update the nightly version in bors CI config if we touch this.
cargo install --locked --git https://github.com/rust-lang/rust-semverver --rev 71c340ff867d2f79613cfe02c6714f1d2ef00bc4

# FIXME: Replace `x86_64-sun-solaris` with `x86_64-pc-solaris`
# when we update the nightly date for semverver to nightly-2021-03-02 or later.
TARGETS=
case "${OS}" in
    *linux*)
        TARGETS="\
aarch64-fuchsia \
aarch64-linux-android \
aarch64-unknown-linux-gnu \
aarch64-unknown-linux-musl \
armv7-linux-androideabi \
armv7-unknown-linux-gnueabihf \
i586-unknown-linux-gnu \
i586-unknown-linux-musl \
i686-linux-android \
i686-unknown-freebsd \
i686-unknown-linux-gnu \
i686-unknown-linux-musl \
i686-pc-windows-gnu \
x86_64-unknown-freebsd \
x86_64-unknown-linux-gnu \
x86_64-unknown-linux-musl \
x86_64-unknown-netbsd \
x86_64-sun-solaris \
x86_64-fuchsia \
x86_64-pc-windows-gnu \
x86_64-unknown-linux-gnux32 \
x86_64-unknown-redox \
x86_64-unknown-z_os \
x86_64-fortanix-unknown-sgx \
wasm32-unknown-unknown \
"
    ;;
    *macos*)
        TARGETS="\
aarch64-apple-ios \
x86_64-apple-darwin \
x86_64-apple-ios \
"
    ;;
esac

for TARGET in $TARGETS; do
    # FIXME: rustup often fails to download some artifacts due to network
    # issues, so we retry this N times.
    N=5
    n=0
    until [ $n -ge $N ]
    do
        if rustup target add "${TARGET}" ; then
            break
        fi
        n=$((n+1))
        sleep 1
    done

    cargo semver --api-guidelines --target="${TARGET}"
done

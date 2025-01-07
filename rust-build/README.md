## Overview

This readme briefly describes how to build our Rust toolchain.

## Functionality
The Rust toolchain is built based on Rust 1.72.0. It is used to provide capability of building ohos image. For detailed information about Rust 1.72.0, please refer to [Rust 1.72.0](https://blog.rust-lang.org/2023/08/24/Rust-1.72.0.html).

### System Requirements for Toolchain Build

Ubuntu >= 18.04

MacOS >= 13.0

### Environmental preparation 

Ubuntu

```bash
sudo apt install gcc llvm python cmake openssl pkg-config git unzip ninja-build python3-distutils gawk curl python3-pip
```

Mac

```
brew install gcc cmake ninja python openssh pkg-config git
```

### Toolchain build process

1、create build directory

```
mkdir -p harmony
cd harmony
```

2、download reliant build tools（Mac environment need not to download）

```
git clone https://gitee.com/openharmony/build.git
export PYTHONIOENCODING=utf-8 && bash build/prebuilts_download.sh
pip3 install -i https://repo.huaweicloud.com/repository/pypi/simple requests
python3 ./build/scripts/download_sdk.py --branch OpenHarmony-5.0.0-Release --product-name ohos-sdk-full-5.0.0 --api-version 12
```

3、download build code

```
git clone --depth=1 https://gitee.com/openharmony/third_party_llvm-project.git third_party/llvm-project
git clone --depth=1 https://gitee.com/openharmony-sig/third_party_rust_rust.git third_party/rust/rust
```

4、start to build

```
bash third_party/rust/rust/rust-build/ohos_ci_build.sh
```

### Output Layout

When build successfully completed. following artifacts will be available in `output` directory.

- Ubuntu system

```
rust-nightly-x86_64-unknown-linux-gnu.tar.gz
rust-std-nightly-x86_64-pc-windows-gnullvm.tar.gz
rust-std-nightly-aarch64-unknown-linux-ohos.tar.gz
rust-std-nightly-armv7-unknown-linux-ohos.tar.gz
rust-std-nightly-x86_64-unknown-linux-ohos.tar.gz
```

- Mac arm64 system

```
rust-nightly-aarch64-apple-darwin.tar.gz
```

- Mac x86_64 system

```
rust-nightly-x86_64-apple-darwin.tar.gz
```


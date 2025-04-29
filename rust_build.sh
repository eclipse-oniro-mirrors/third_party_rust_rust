#!/bin/bash
set -e

CURRENT_DIR=$(pwd)

mkdir -p ~/.cargo && touch ~/.cargo/config.toml && chmod 777 ~/.cargo/config.toml
cat > ~/.cargo/config.toml <<EOF
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "https://mirrors.ustc.edu.cn/crates.io-index"

[net]
git-fetch-with-cli = true 
EOF

pushd $CURRENT_DIR > /dev/null
	# 获取rust_std包
	mkdir -p build/cache/2024-10-16
	pushd build/cache/2024-10-16 > /dev/null
	  wget https://repo.huaweicloud.com/harmonyos/compiler/rust/1.83.0/rust-std-beta-x86_64-unknown-linux-gnu.tar.xz
	  wget https://repo.huaweicloud.com/harmonyos/compiler/rust/1.83.0/rustc-nightly-x86_64-unknown-linux-gnu.tar.xz
	  wget https://repo.huaweicloud.com/harmonyos/compiler/rust/1.83.0/cargo-beta-x86_64-unknown-linux-gnu.tar.xz
	  wget https://repo.huaweicloud.com/harmonyos/compiler/rust/1.83.0/rustc-beta-x86_64-unknown-linux-gnu.tar.xz
	  wget https://repo.huaweicloud.com/harmonyos/compiler/rust/1.83.0/rustfmt-nightly-x86_64-unknown-linux-gnu.tar.xz
	popd > /dev/null
	# 获取rust_src包
	wget https://repo.huaweicloud.com/harmonyos/compiler/rust/1.84.0/rust_src.tar.gz
	mkdir tmp_rust && tar -zxvf rust_src.tar.gz -C tmp_rust/

	if [[ ! -d src/gcc ]]; then
	  mkdir -p src/gcc
	fi
	cp -rf tmp_rust/src/gcc/* src/gcc/
	
	if [[ ! -d src/llvm-project ]]; then
	  mkdir -p src/llvm-project
	fi
	cp -rf tmp_rust/src/llvm-project/* src/llvm-project/

	if [[ ! -d src/tools/enzyme ]]; then
	  mkdir -p src/tools/enzyme
	fi
	cp -rf tmp_rust/src/tools/enzyme/* src/tools/enzyme/

	if [[ ! -d src/tools/rustc-perf ]]; then
	  mkdir -p src/tools/rustc-perf
	fi
	cp -rf tmp_rust/src/tools/rustc-perf/* src/tools/rustc-perf/

	if [[ ! -d src/tools/cargo ]]; then
	  mkdir -p src/tools/cargo  
	fi
	cp -rf tmp_rust/src/tools/cargo/* src/tools/cargo/

	if [[ ! -d src/doc/rust-by-example ]]; then
	  mkdir -p src/doc/rust-by-example
	fi
	cp -rf tmp_rust/src/doc/rust-by-example/* src/doc/rust-by-example/

	if [[ ! -d src/doc/embedded-book ]]; then
	  mkdir -p src/doc/embedded-book
	fi
	cp -rf tmp_rust/src/doc/embedded-book/* src/doc/embedded-book/

	if [[ ! -d src/doc/reference ]]; then
	  mkdir -p src/doc/reference
	fi
	cp -rf tmp_rust/src/doc/reference/* src/doc/reference/

	if [[ ! -d src/doc/edition-guide ]]; then
	  mkdir -p src/doc/edition-guide
	fi
	cp -rf tmp_rust/src/doc/edition-guide/* src/doc/edition-guide/

	if [[ ! -d src/doc/nomicon ]]; then
	  mkdir -p src/doc/nomicon
	fi
	cp -rf tmp_rust/src/doc/nomicon/* src/doc/nomicon/

	if [[ ! -d src/doc/book ]]; then
	  mkdir -p src/doc/book
	fi
	cp -rf tmp_rust/src/doc/book/* src/doc/book/

	if [[ ! -d library/stdarch ]]; then
	  mkdir -p library/stdarch
	fi
	cp -rf tmp_rust/library/stdarch/* library/stdarch/

	if [[ ! -d library/backtrace ]]; then
	  mkdir -p library/backtrace
	fi
	cp -rf tmp_rust/library/backtrace/* library/backtrace/
    
    mkdir -p vendor

    echo "stage2 build start ..."
    python3 x.py build --stage 2
    echo "stage2 build end"

    # libprofiler_builtins-xx.rlib build
    python3 x.py build --stage 2 library/std
    ls build/x86_64-unknown-linux-gnu/stage0/lib/rustlib/x86_64-unknown-linux-gnu/lib/

    echo "dist rust-dev build start ..."
	python3 x.py dist
    echo "dist rust build end"
popd > /dev/null

EXTRA_PATH=$CURRENT_DIR/tmp_rust/extra
pushd $EXTRA_PATH/rustlib > /dev/null
    unzip src.zip
popd > /dev/null

if [[ ! -d $CURRENT_DIR/build/dist ]]; then
    echo "rust build fail"
    exit 1
fi

echo "start add extra files"
pushd $CURRENT_DIR/build/dist > /dev/null
    ls -alh $CURRENT_DIR/build/dist/
    tar -zxvf rust-1.84.0-dev-x86_64-unknown-linux-gnu.tar.gz
    package_dir="rust-1.84.0-dev-x86_64-unknown-linux-gnu"
    pushd rust-1.84.0-dev-x86_64-unknown-linux-gnu > /dev/null
        echo "----------rust build start-------------"
        chmod 777 install.sh && mkdir rust-toolchain && ./install.sh --prefix="rust-toolchain"
        echo "----------rust build finish------------"
        mkdir -p rust-toolchain/lib/rustlib/src
    popd > /dev/null
    
    cp -rf $EXTRA_PATH/libclang* $package_dir/rust-toolchain/lib/
	cp $package_dir/rust-toolchain/lib/libclang.so $package_dir/rust-toolchain/lib/libclang.so.20.0.0git
	cp $package_dir/rust-toolchain/lib/libclang.so $package_dir/rust-toolchain/lib/libclang.so.20.0git
	cp -rf $EXTRA_PATH/rustlib/src $package_dir/rust-toolchain/lib/rustlib/
    cp -rf $EXTRA_PATH/bin/* $package_dir/rust-toolchain/bin/
    rm -rf $package_dir/rust-toolchain/lib/rustlib/x86_64-unknown-linux-gnu/bin
popd > /dev/null
echo "extra files add finish"

pushd $CURRENT_DIR/build/dist > /dev/null
    rm -rf rust-1.84.0-dev-x86_64-unknown-linux-gnu.tar.gz
    tar -zcvf rust-1.84.0-dev-x86_64-unknown-linux-gnu.tar.gz rust-1.84.0-dev-x86_64-unknown-linux-gnu
popd > /dev/null

pushd $CURRENT_DIR/build/dist/rust-1.84.0-dev-x86_64-unknown-linux-gnu > /dev/null
    tar -zcvf rust-toolchain.tar.gz rust-toolchain
popd > /dev/null

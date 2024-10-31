#! /bin/bash
set -e

readonly shell_path=$(cd $(dirname $0); pwd)
readonly root_build_dir="${shell_path}/../../../.."
readonly rust_source_dir="${shell_path}/.."
readonly rust_tools="${root_build_dir}/prebuilts"

case $(uname -s) in
    Linux)
        host_platform=linux
        ;;
    Darwin)
        host_platform=darwin
        ;;
    *)
        echo "Unsupported host platform: $(uname -s)"
        exit 1
esac

case $(uname -m) in
    arm64)
        host_cpu=arm64
        ;;
    *)
        host_cpu=x86_64
esac

function update_config_toml_clang(){
    # $1:clang path, $2:clang name, $4:ar name

    # add clang absolute path to shell tools
    sys_clang_dir="$(echo ${1} | sed 's/\//\\\//g')"
    sed -i "s/exec ${2}/exec ${sys_clang_dir}\/${2}/g" ${rust_source_dir}/build/${2}
    sed -i "s/exec ${2}++/exec ${sys_clang_dir}\/${2}++/g" ${rust_source_dir}/build/${2}++
    # add clang absolute path to config.toml
    rust_clang_dir="$(echo ${rust_source_dir}/build | sed 's/\//\\\//g')"
    sed -i "s/cc = \"${2}\"/cc = \"${rust_clang_dir}\/${2}\"/g" ${rust_source_dir}/config.toml
    sed -i "s/cxx = \"${2}++\"/cxx = \"${rust_clang_dir}\/${2}++\"/g" ${rust_source_dir}/config.toml
    sed -i "s/linker = \"${2}\"/linker = \"${sys_clang_dir}\/${2}\"/g" ${rust_source_dir}/config.toml
    sed -i "s/ar = \"${3}\"/ar = \"${sys_clang_dir}\/${3}\"/g" ${rust_source_dir}/config.toml
}

# download rust 1.71 for build
readonly rust_down_dir="${root_build_dir}/rust_download"
mkdir -p ${rust_down_dir}
readonly rust_down_net="https://mirrors.ustc.edu.cn/rust-static/dist"
cd ${rust_down_dir}
mkdir -p ${rust_source_dir}/build/cache/2023-07-13

if [ "${host_platform}" = "linux" ] && [ ${host_cpu} = "x86_64" ]; then
    curl -O -k -m 300 ${rust_down_net}/2023-07-13/rust-std-1.71.0-x86_64-unknown-linux-gnu.tar.xz
    curl -O -k -m 300 ${rust_down_net}/2023-07-13/rustc-1.71.0-x86_64-unknown-linux-gnu.tar.xz
    curl -O -k -m 300 ${rust_down_net}/2023-07-13/cargo-1.71.0-x86_64-unknown-linux-gnu.tar.xz

    cp ${shell_path}/config.toml ${rust_source_dir}
    chmod 750 ${shell_path}/tools/*
    cp ${shell_path}/tools/* ${rust_source_dir}/build/
    update_config_toml_clang ${rust_tools}/clang/ohos/linux-x86_64/llvm/bin clang llvm-ar
    update_config_toml_clang ${rust_tools}/mingw-w64/ohos/linux-x86_64/clang-mingw/bin x86_64-w64-mingw32-clang x86_64-w64-mingw32-ar
elif [ "${host_platform}" = "darwin" ] && [ ${host_cpu} = "x86_64" ]; then
    curl -O -k -m 300 ${rust_down_net}/2023-07-13/rustc-1.71.0-x86_64-apple-darwin.tar.xz
    curl -O -k -m 300 ${rust_down_net}/2023-07-13/rust-std-1.71.0-x86_64-apple-darwin.tar.xz
    curl -O -k -m 300 ${rust_down_net}/2023-07-13/cargo-1.71.0-x86_64-apple-darwin.tar.xz
    cp ${shell_path}/mac_x8664_config.toml ${rust_source_dir}/config.toml
elif [ "${host_platform}" = "darwin" ] && [ ${host_cpu} = "arm64" ]; then
    curl -O -k -m 300 ${rust_down_net}/2023-07-13/rustc-1.71.0-aarch64-apple-darwin.tar.xz
    curl -O -k -m 300 ${rust_down_net}/2023-07-13/rust-std-1.71.0-aarch64-apple-darwin.tar.xz
    curl -O -k -m 300 ${rust_down_net}/2023-07-13/cargo-1.71.0-aarch64-apple-darwin.tar.xz
    cp ${shell_path}/mac_arm64_config.toml ${rust_source_dir}/config.toml
else
    echo "Unsupported platform: $(uname -s) $(uname -m)"
fi

mv ${rust_down_dir}/*.tar.xz ${rust_source_dir}/build/cache/2023-07-13/

curl -O -k -m 300 ${rust_down_net}/rustc-1.72.0-src.tar.gz
tar xf rustc-1.72.0-src.tar.gz
cd ${rust_down_dir}/rustc-1.72.0-src/
cp -r .cargo/ ${rust_source_dir}
cp -r vendor ${rust_source_dir}
cp -r library ${rust_source_dir}
cp -r src/doc/* ${rust_source_dir}/src/doc
cp -r src/tools/cargo/* ${rust_source_dir}/src/tools/cargo

cp -r src/llvm-project/* ${rust_source_dir}/src/llvm-project/
# cp -r ${root_build_dir}/../harmony/third_party_llvm-project/* ${rust_source_dir}/src/llvm-project/

cd ${rust_source_dir}
if [ "${host_platform}" = "linux" ]; then
export PATH=${rust_tools}/cmake/linux-x86/bin:${rust_tools}/clang/ohos/linux-x86_64/llvm/bin:$PATH
fi
python3 ./x.py dist

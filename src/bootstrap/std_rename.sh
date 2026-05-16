#!/bin/bash
set -e
readonly script_path=$(cd $(dirname $0);pwd)
readonly build_path="${script_path}/../../build"

# $1 is target triple, such as `x86_64-unknown-linux-ohos`.
readonly lib_path="${build_path}/tmp/tarball/rust-std/$1/image/lib/rustlib/$1/lib"

for file in $(find "${lib_path}" -name "lib*.*")
do
    dir_name=${file%/*}
    file_name=${file##*/}
    file_prefix=$(echo "$file_name" | awk '{split($1, arr, "."); print arr[1]}')
    file_suffix=$(echo "$file_name" | awk '{split($1, arr, "."); print arr[2]}')

    # Get filename without metadata-id.
    file_prefix=$(echo "$file_prefix" | awk '{split($1, arr, "-"); print arr[1]}')

    if [[ "$file_suffix" != "rlib" && "$file_suffix" != "so" || \
          "$file_prefix" == "librustc_demangle" || "$file_prefix" == "libcfg_if" || \
          "$file_prefix" == "libunwind" ]]
    then
        continue
    fi
    if [[ "$file_suffix" == "rlib" ]]
    then
        if [[ "$file_prefix" == "libstd" || "$file_prefix" == "libtest" ]]
        then
            # Add '.dylib' for `libstd` and `libtest`.
            newfile_name="$file_prefix.dylib.rlib"
        else
            newfile_name="$file_prefix.rlib"
        fi
    fi

    # `libstd` and `libtest` have both `so` and `rlib`, the other libs only have `rlib`.
    if [[ "$file_suffix" == "so" ]]
    then
        newfile_name="$file_prefix.dylib.so"
        if [[ "$file_prefix" == "libtest" ]]
        then
            # Modify the dependency of `libtest.dylib.so` from `libstd-{metadata-id}.so`
            # to `libstd.dylib.so`.
            readonly dynstr_section_vaddr=$(readelf -S "$file" | grep ".dynstr" | \
                        awk -F']' '{print $2}' | awk '{print strtonum("0x"$3)}')
            readonly libstd_str_offset=$(readelf -p .dynstr "$file" | \
                        grep "libstd-[a-z0-9]\{16\}\.so" | awk -F'[' '{print $2}' | \
                        awk '{print $1}' | awk -F']' '{print strtonum("0x"$1)}')
            readonly libstd_str_vaddr=`expr $dynstr_section_vaddr + $libstd_str_offset`
            $(printf 'libstd.dylib.so\0\0\0\0\0\0\0\0\0\0\0' | \
                dd of="$file" bs=1 seek=$libstd_str_vaddr count=26 conv=notrunc)
        fi
    fi

    if [[ "$file_name" == "$newfile_name" ]]
    then
        continue
    fi

    mv $file "$dir_name/$newfile_name"
done



## Rust介绍

Rust 是一门静态强类型语言，具有更安全的内存管理、更好的运行性能、原生支持多线程开发等优势。

## 引入背景简述

本工具链基于开源 Rust 1.72.0 与 LLVM 15.0.4 增量开发，适配了 OpenHarmony target 二进制构建。可将 rust 源码编译成能在 OpenHarmony 设备上使用的目标二进制。

## 使用场景

在 Linux x86环境本地编译 Linux x86 目标二进制或交叉编译 OpenHarmony 目标二进制。
在 Mac x86 环境本地编译 Mac x86 目标二进制。
在 Mac arm64 环境本地编译 Mac arm64 目标二进制。

## 如何使用

使用方法可参考：[使用说明](https://gitee.com/openharmony/docs/blob/master/zh-cn/device-dev/subsystems/subsys-build-rust-toolchain.md)
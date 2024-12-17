# Rust 编程语言

[![Rust 社区](https://img.shields.io/badge/Rust_Community%20-Join_us-brightgreen?style=plastic&logo=rust)](https://www.rust-lang.org/community)

这是 [Rust] 的主要源代码库。它包含编译器、标准库和文档、
标准库和文档。

[Rust]: https://www.rust-lang.org/

**注意：本 README 是为用户而非贡献者准备的。**
如果您希望为编译器做出贡献，请阅读
[CONTRIBUTING.md](CONTRIBUTING.md)。

### 快速入门

阅读 [The Book] 中的 ["安装"]。

["安装"]: https://doc.rust-lang.org/book/ch01-01-installation.html
[本书]： https://doc.rust-lang.org/book/index.html

## 从源文件安装

Rust 编译系统使用一个名为 `x.py` 的 Python 脚本来编译编译器、
管理引导过程。它位于项目的根目录下。
它还使用一个名为 `config.toml` 的文件来确定编译时的各种配置设置。
设置。您可以在
`config.example.toml`.

在大多数 Unix 系统上都可以直接运行 `x.py` 命令，格式如下
格式直接运行：

```sh
./x.py <子命令> [标志］
```

文档和示例都假定你是这样运行 `x.py`的。
如果这在你的平台上不起作用，请参阅 [rustc dev guide][rustcguidebuild]。
平台上不起作用，请参阅 [rustc dev guide][rustcguidebuild] 。

关于 `x.py` 的更多信息，可以通过使用 `--help`标记来运行它
或阅读[rustc dev guide][rustcguidebuild]。

[gettingstarted]: https://rustc-dev-guide.rust-lang.org/getting-started.html
[rustcguidebuild]: https://rustc-dev-guide.rust-lang.org/building/how-to-build-and-run.html#what-is-xpy

#### 依赖关系

确保已安装依赖项：

* `python` 3 或 2.7
* `git`
* C 语言编译器（为主机编译时，使用 `cc` 即可；交叉编译时可能需要额外的编译器
  需要额外的编译器）
* `curl`（在 Windows 上不需要）
* 如果在 Linux 上编译并以 Linux 为目标，则需要 `pkg-config`
* `libiconv` （在基于 Debian 的发行版中已包含在 glibc 中）

要编译 Cargo，还需要 OpenSSL（在大多数 Unix 发行版上为 `libssl-dev` 或 `openssl-devel` ）。
在大多数 Unix 发行版上）。

如果从源代码编译 LLVM，还需要额外的工具：

* `g++`、`clang++`或 MSVC，其版本列于
  [LLVM 的文档](https://llvm.org/docs/GettingStarted.html#host-c-toolchain-both-compiler-and-standard-library)
* `ninja`，或 GNU `make` 3.81 或更高版本（推荐使用 Ninja，尤其是在
  Windows）
* `cmake` 3.13.4 或更高版本
* 在某些 Linux 发行版上可能需要 `libstdc++-static` ，如 Fedora
  和 Ubuntu

在带主机工具平台的第 1 层或第 2 层，您还可以选择下载
通过设置 `llvm.download-ci-llvm = true` 下载 LLVM。
否则，需要安装 LLVM 并在路径中设置 `llvm-config`。
更多信息请参见[the rustc-dev-guide for more info][sysllvm]。

[sysllvm]: https://rustc-dev-guide.rust-lang.org/building/new-target.html#using-pre-built-llvm


### 在类 Unix 系统上构建

#### 构建步骤

1.使用 `git` 克隆 [源代码]：

   ```sh
   git clone https://github.com/rust-lang/rust.git
   cd rust
   ```

[source]: https://github.com/rust-lang/rust

2.配置构建设置：

   ```sh
   ./configure
   ```

   如果计划使用 `x.py install` 创建安装，建议将 `[install]`部分中的 `prefix` 值设置一个
   目录：`./configure --set install.prefix=<path>`

3.构建并安装：

   ```sh
   ./x.py build && ./x.py install
   ```

   完成后，`./x.py install` 会将几个程序放入
   `$PREFIX/bin` 中：`rustc`，Rust 编译器，和`rustdoc`，API 文档工具。
   API 文档工具。默认情况下，它还会包含 [Cargo]，Rust 的
   包管理器。你可以通过
   `--set build.extended=false` 到 `./configure`。

[Cargo]: https://github.com/rust-lang/cargo

#### 配置和 Make

该项目提供了 configure 脚本和 makefile（后者只是
调用 `x.py`）。`./configure `是以编程方式生成
`config.toml`.不推荐使用 `make`（我们建议直接使用 `x.py`
直接使用），但它是受支持的，我们尽量避免不必要地破坏它。

```sh
./configure
make && sudo make install
```

`configure` 会生成一个 `config.toml` 文件，该文件也可用于普通的 `x.py`
调用。

### 在 Windows 上构建

在 Windows 上，我们建议使用 [winget] 安装依赖项，在终端运行
在终端运行

```powershell
winget install -e Python.Python.3
winget install -e Kitware.CMake
winget install -e Git.Git
```

然后编辑系统的 `PATH` 变量并添加：`C:\Program Files\CMake\bin`.
参见
[关于编辑系统 `PATH` 的指南](https://www.java.com/en/download/help/path.html)
Java 文档。

[winget]：https://github.com/microsoft/winget-cli

Windows 上有两种著名的 ABI：Visual Studio 使用的本地 (MSVC) ABI 和 GCC 工具链使用的 GNU ABI。
Visual Studio 使用的本地（MSVC）ABI 和 GCC 工具链使用的 GNU ABI。您需要哪个版本的 Rust
主要取决于你想与哪些 C/C++ 库互操作。
使用 MSVC 版本的 Rust 与 Visual Studio 制作的软件进行互操作
工具链构建的 GNU 软件进行互操作。
工具链构建的 GNU 软件进行互操作。

#### MinGW

[MSYS2][msys2]可用于在 Windows 上轻松构建 Rust：

[msys2]: https://www.msys2.org/

1.下载最新的 [MSYS2 安装程序][msys2]，并完成安装。

2.从 MSYS2 安装目录（例如 `C:\msys64` ）运行 `mingw32_shell.bat` 或 `mingw64_shell.bat` 。
   目录（例如 `C:\msys64`）中运行`mingw32_shell.bat`或`mingw64_shell.bat`，具体取决于您需要 32 位还是 64 位的 Rust。
   Rust。(从 MSYS2 的最新版本开始，您必须运行 `msys2_shell.cmd -mingw32` 或 `msys2_shell.cmd -mingw64`）。

3.从该终端安装所需的工具：

   ```sh
   # 更新软件包镜像（如果重新安装了 MSYS2，可能需要这样做）
   pacman -Sy pacman-mirrors

   # 安装 Rust 所需的编译工具。如果要编译 32 位编译器、
   # 则将下面的 "x86_64 "替换为 "i686"。如果你已经安装了 Git、Python、
   # 或 CMake 已安装并在 PATH 中，则可将它们从列表中移除。
   # 请注意，切勿***使用 "python2"、"cmake "和 "ninja "软件包、
   # 以及 "msys2 "子系统中的 "ninja "软件包。
   # 历史上，使用这些软件包会导致编译失败。
   pacman -S git \
               make
               diffutils \
               tar
               mingw-w64-x86_64-python \
               mingw-w64-x86_64-cmake \
               mingw-w64-x86_64-gcc
               mingw-w64-x86_64-ninja
   ```

4.导航到 Rust 的源代码（或克隆它），然后构建它：

   ```sh
   python x.py setup user && python x.py build && python x.py install
   ```

#### MSVC

Rust 的 MSVC 版本还需要安装 Visual Studio 2017
(或更高版本），以便 `rustc` 可以使用其链接器。最简单的方法是获取
[Visual Studio]，检查 "C++ 编译工具 "和 "Windows 10 SDK "工作量。

[Visual Studio]: https://visualstudio.microsoft.com/downloads/

(如果您自己安装 CMake，请注意 "C++ CMake tools for
Windows 工具 "不包含在 "单个组件 "中）。

安装好这些依赖项后，就可以在 `cmd.exe` shell 中编译编译器了。
shell 中编译编译器：

```sh
python x.py setup user
python x.py build
```

目前，构建 Rust 只适用于某些已知版本的 Visual Studio。
如果你安装了较新的版本，而编译系统无法理解，你可能需要强制 rustbuild 使用较旧的版本。
理解，则可能需要强制 rustbuild 使用旧版本。
这可以通过在运行
引导程序。

```批处理
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
python x.py build
```

#### 指定 ABI

每个特定的 ABI 也可以在任一环境中使用（例如，在 PowerShell 中使用
例如，在 PowerShell 中使用 GNU ABI）。可用的
Windows 构建三元组有
- GNU ABI（使用 GCC）
    - i686-pc-windows-gnu
    - x86_64-pc-windows-gnu
- MSVC ABI
    - i686-pc-windows-msvc
    - x86_64-pc-windows-msvc

在调用 `x.py` 命令时，可通过指定 `--build=<triple>` 来指定三重编译。
命令时指定 `--build=<triple>` 或创建一个 `config.toml` 文件(参见
[在类 Unix 系统上构建](#在类-unix-系统上构建)中所述)，并通过
`--set build.build=<triple>` 到 `./configure`。

## 构建文档

如果你想构建文档，方法几乎一样：

```sh
./x.py doc
```

生成的文档将出现在所用 ABI 的 `build` 目录中的 `doc` 下。
目录中的 `doc` 下。也就是说，如果 ABI 是 `x86_64-pc-windows-msvc`，则目录
将是 `build\x86_64-pc-windows-msvc\doc`。

## 注意事项

由于 Rust 编译器是用 Rust 编写的，它必须由一个预编译的
"快照 "版本（在早期开发阶段制作）构建。
因此，源代码编译需要互联网连接来获取快照，还需要能执行可用快照二进制文件的操作系统。
能执行可用快照二进制文件的操作系统。

有关
支持的平台列表。
只有 "主机工具 "平台才有预编译的快照二进制文件；要为没有主机工具的平台编译，必须交叉编译快照二进制文件。
必须交叉编译。

您可能会发现其他平台也可以使用，但这些是我们官方支持的
编译环境最有可能正常工作。

## 获取帮助

聊天平台和论坛列表请参见 https://www.rust-lang.org/community。

## 投稿

请参见 [CONTRIBUTING.md](CONTRIBUTING.md)。

### 许可

Rust 主要根据 MIT 许可和
Apache License（2.0 版）的条款进行发布，部分内容受各种类 BSD
许可证。

参见 [LICENSE-APACHE](LICENSE-APACHE)、[LICENSE-MIT](LICENSE-MIT) 和
[COPYRIGHT](COPYRIGHT) 获取详细信息。

## 商标

[Rust 基金会][Rust 基金会]拥有并保护 Rust 和 Cargo
商标和徽标（以下简称 "Rust 商标"）。

如果您想使用这些名称或品牌，请阅读
[媒体指南][媒体指南]。

第三方徽标可能受第三方版权和商标的保护。请参阅
[许可证][许可证]了解详情。

[Rust 基金会]: https://foundation.rust-lang.org/
[媒体指南]: https://foundation.rust-lang.org/policies/logo-policy-and-media-guide/
[许可证]: https://www.rust-lang.org/policies/licenses

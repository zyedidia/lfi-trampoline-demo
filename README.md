# LFI Trampoline Demo

This is a demo that shows manual invocation of a function inside an LFI sandbox.

# Toolchain Setup

Install the LFI x86-64 toolchain. A prebuilt toolchain is available online:
https://github.com/zyedidia/lfi/releases/tag/v0.6.

To build a toolchain manually, first install the LFI tools

```
git clone https://github.com/zyedidia/lfi
cd lfi
meson setup build-tools -Dtools-only=true
cd build-tools
ninja
sudo meson install
```

In particular, you need to install `lfi-leg/lfi-leg` and
`lfi-postlink/lfi-postlink`.

Then you can build the LLVM toolchain:

```
git clone https://github.com/zyedidia/lfi-llvm-toolchain
cd lfi-llvm-toolchain
./download.sh
./build-lfi.sh $PWD/x86_64-lfi-clang x86_64
```

This will download and build LLVM along with the runtime libraries compiler-rt,
musl libc, libc++, and mimalloc.

When complete, you can put `x86_64-lfi-clang/lfi-clang` on your path to make
`x86_64-lfi-linux-musl-clang` and `x86_64-lfi-linux-musl-clang++` available
globally.

# Library Setup

Once you have a toolchain, you also need to install liblfi, which is the LFI
runtime.

```
git clone https://github.com/zyedidia/lfi # or use your previous clone
cd lfi
meson setup build-liblfi -Dliblfi-only=true
cd build-liblfi
ninja
sudo meson install
```

This should install `liblfi.a` along with the headers `lfi.h`, `lfi_tux.h`,
`lfi_arch.h`, and `lfi_host.h`.

# Build

Now in this repository you can run

```
make
```

This will build the sandboxed function in `sandbox/libadd.elf`, as well as the
code in `main.c` that initializes LFI and the trampoline in `trampoline.s`. The
`sandbox/libadd.elf` is embedded into the final binary via `incstub.s`.

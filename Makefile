SHELL := /bin/bash

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

main: lfi-clang lfi main.c incstub.s callback.S callback.c trampoline.S callback_aarch64.S callback_aarch64.c trampoline_aarch64.S
	PATH=$(PATH):$(ROOT_DIR)/lfi-clang/lfi-bin $(MAKE) -C sandbox -B
	if [[ "$(shell uname -i)" == "x86_64" ]]; then \
		cc main.c incstub.s callback.S callback.c trampoline.S -Og -o $@ -llfi -g -L lfi/build-liblfi/liblfi -I lfi/liblfi/include; \
	else \
		cc main.c incstub.s callback_aarch64.S callback_aarch64.c trampoline_aarch64.S -Og -o $@ -llfi -g -L lfi/build-liblfi/liblfi -I lfi/liblfi/include; \
	fi

lfi-clang.tar.gz:
	if [[ "$(shell uname -i)" == "x86_64" ]]; then \
		wget https://github.com/zyedidia/lfi/releases/download/v0.7/x86_64-lfi-clang.tar.gz && mv x86_64-lfi-clang.tar.gz $@; \
	else \
		wget https://github.com/zyedidia/lfi/releases/download/v0.7/aarch64-lfi-clang.tar.gz && mv aarch64-lfi-clang.tar.gz $@; \
	fi

lfi-clang: lfi-clang.tar.gz
	@if [ ! -e "$@" ]; then \
		mkdir -p $@ && tar -zxf $< -C $@ --strip-components=1; \
	fi

lfi:
	git clone git@github.com:zyedidia/lfi || git clone https://github.com/zyedidia/lfi
	cd lfi && git checkout update-lfi-ret
	cd lfi && meson setup build-liblfi -Dliblfi-only=true
	cd lfi/build-liblfi && ninja

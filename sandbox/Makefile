SHELL := /bin/bash

libadd.elf: add.c main.s main_aarch64.s
	if [[ "$(shell uname -i)" == "x86_64" ]]; then \
		x86_64-lfi-linux-musl-clang add.c main.s -O2 -o $@ -static-pie; \
	else \
		aarch64-lfi-linux-musl-clang add.c main_aarch64.s -O2 -o $@ -static-pie; \
	fi

SHELL := /bin/bash

libadd.elf: main.s add.c
	if [[ "$(shell uname -i)" == "x86_64" ]]; then \
		x86_64-lfi-linux-musl-clang $^ -O2 -o $@ -static-pie; \
	else \
		aarch64-lfi-linux-musl-clang $^ -O2 -o $@ -static-pie; \
	fi

SHELL := /bin/bash

main: main.c incstub.s callback.S callback.c trampoline.S callback_aarch64.S callback_aarch64.c trampoline_aarch64.S
	$(MAKE) -C sandbox -B
	if [[ "$(shell uname -i)" == "x86_64" ]]; then \
		cc main.c incstub.s callback.S callback.c trampoline.S -Og -o $@ -llfi -g; \
	else \
		cc main.c incstub.s callback_aarch64.S callback_aarch64.c trampoline_aarch64.S -Og -o $@ -llfi -g; \
	fi

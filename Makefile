main: main.c callback.S callback.c trampoline.S incstub.s
	$(MAKE) -C sandbox -B
	cc $^ -Og -o $@ -llfi -g

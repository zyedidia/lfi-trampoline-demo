main: main.c trampoline.s incstub.s
	$(MAKE) -C sandbox
	cc $^ -Og -o $@ -llfi -g

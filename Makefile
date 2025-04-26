main: main.c trampoline.s incstub.s
	$(MAKE) -C sandbox -B
	cc $^ -Og -o $@ -llfi -g

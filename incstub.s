.section .rodata
.global stub_start
.global stub_end
stub_start:
    .incbin "sandbox/libadd.elf"
stub_end:

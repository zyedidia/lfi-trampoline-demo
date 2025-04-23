.text

.global lfi_add
lfi_add:
	// save callee-saved registers
	pushq %r15
	pushq %r14
	pushq %r13
	pushq %r12
	pushq %rbx
	pushq %rbp

	// load lfi_myctx thread-local
	movq lfi_myctx@gottpoff(%rip), %r11
	movq %fs:(%r11), %r11

	// dummy push to keep the stack aligned
	pushq %rbp
	// push lfi_myctx->regs.rsp
	pushq 16(%r11)

	// save current stack to lfi_myctx->kstackp
	movq %rsp, 0(%r11)
	// load rsp from lfi_myctx->regs.rsp
	movq 16(%r11), %rsp
	// load r14 (base address) from lfi_myctx->regs.r14
	movq 16+14*8(%r11), %r14
	// also write base to %gs
	wrgsbase %r14

	// load address of the _lfi_retfn function that will make the return rtcall
	movq _lfi_retfn_addr@GOTPCREL(%rip), %r11
	movq (%r11), %r11
	// push this as the return address onto the user stack
	pushq %r11

	// load address of the add function
	movq add_addr@GOTPCREL(%rip), %r11
	movq (%r11), %r11
	// apply mask just to be safe
	andl $0xffffffe0, %r11d
	addq %r14, %r11

	// this function should return via a runtime call
	jmpq *%r11
	int3

.data

.global _funcs
_funcs:
.global add_addr
add_addr:
	.quad 0
.global _lfi_retfn_addr
_lfi_retfn_addr:
	.quad 0

.section .note.GNU-stack,"",@progbits

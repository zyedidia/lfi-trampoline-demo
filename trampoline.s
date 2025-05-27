.text

.global lfi_trampoline
lfi_trampoline:
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

	// push lfi_myctx->regs.rsp
	pushq 16(%r11)

	// push the trampoline return onto the host stack
	leaq .return(%rip), %r14
	pushq %r14

	// save current stack to lfi_myctx->kstackp
	movq %rsp, 0(%r11)
	// load rsp from lfi_myctx->regs.rsp
	movq 16(%r11), %rsp
	// load r14 (base address) from lfi_myctx->regs.r14
	movq 16+14*8(%r11), %r14
	// also write base to %gs
	wrgsbase %r14

	// load address of the lfi_retfn function that will make the return rtcall
	movq lfi_retfn@gottpoff(%rip), %r11
	movq %fs:(%r11), %r11
	andq $0xfffffffffffffff0, %rsp
	// push this as the return address onto the user stack
	pushq %r11

	// load address of the add function
	movq lfi_targetfn@gottpoff(%rip), %r11
	movq %fs:(%r11), %r11
	// apply mask just to be safe
	andl $0xffffffe0, %r11d
	addq %r14, %r11

	// this function should return via a runtime call
	jmpq *%r11
.return:
	popq %rbp
	movq %rbp, 16(%r11)
	popq %rbp
	popq %rbx
	popq %r12
	popq %r13
	popq %r14
	popq %r15
	ret

.section .note.GNU-stack,"",@progbits

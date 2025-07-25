#define PROC_REGS 16

.text

.global lfi_callback
lfi_callback:
	// Entrypoint for callbacks. Callback target is in %r10.
	movq lfi_myctx@gottpoff(%rip), %r11
	movq %fs:(%r11), %r11
	xchg 0(%r11), %rsp
	pushq %r12              // save r12 to use as temp
	movq 0(%r11), %r12      // move current sandbox stack pointer to r12
	pushq PROC_REGS(%r11)          // push old sandbox stack pointer to stack
	movq %r12, PROC_REGS(%r11)     // save current sandbox stack pointer

	pushq %r11 // needed for stack alignment and preserving r11
	callq *%r10
	popq %r11

	// restore %rsp
	movq PROC_REGS(%r11), %r10      // move current sandbox stack pointer to r10
	popq PROC_REGS(%r11)            // restore old sandbox stack pointer
	popq %r12                // restore r12
	movq %rsp, 0(%r11)       // make sure we don't clobber stack pointer
	movq %r10, %rsp          // restore stack pointer

	// return back to sandbox

	// This pop instruction could segfault if the sandbox has provided a bad stack.
.global lfi_callback_userpop
lfi_callback_userpop:
	popq %r11
	andl $0xffffffe0, %r11d
	orq %r14, %r11
	jmpq *%r11

.section .note.GNU-stack,"",@progbits

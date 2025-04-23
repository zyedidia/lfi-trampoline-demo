.text

.p2align 5
.global main
main:
	leaq _funcs(%rip), %rdi
	mov $60, %rax
	syscall

.p2align 5
.global _lfi_retfn
_lfi_retfn:
	//lfi:rtcall_return

.data

.global _funcs
_funcs:
	.quad add
	.quad _lfi_retfn

.section .note.GNU-stack,"",@progbits

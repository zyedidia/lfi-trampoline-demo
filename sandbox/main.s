.text

.p2align 4
.global main
main:
	mov x8, #94
	svc #0

.p2align 4
.global _lfi_retfn
_lfi_retfn:
	//lfi:rtcall_return

.data

.section .note.GNU-stack,"",@progbits

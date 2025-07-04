#define PROC_REGS 16

.text

.macro get_ctx
  mov x11, x0
  mov x9, x30
  adrp x0, :tlsdesc:lfi_myctx
  ldr x8, [x0, :tlsdesc_lo12:lfi_myctx]
  add x0, x0, :tlsdesc_lo12:lfi_myctx
  // this tls descriptor call must preserve all registers except x0
  .tlsdesccall lfi_myctx
  blr x8
  mrs x8, tpidr_el0
  ldr x8, [x8, x0]
  mov x30, x9
  mov x0, x11
.endm

.global lfi_callback
lfi_callback:
  // x18 was used to branch here, reset it to a valid value
  mov x18, x21

  get_ctx

  // get current user sp
  mov x12, sp
  // enable kernel sp
  ldr x11, [x8]
  mov sp, x11
  // save previous user sp and return address to stack
  ldr x11, [x8, PROC_REGS+16*15+8]
  stp x11, x30, [sp, #-16]!
  // save current user sp to ctx
  str x12, [x8, PROC_REGS+16*15+8]
  mov x22, x8

  blr x16

  // read previous user sp and return address from stack
  mov x8, x22
  ldp x11, x30, [sp], 16
  // read current user sp from ctx
  ldr x12, [x8, PROC_REGS+16*15+8]
  // restore previous user sp in ctx
  str x11, [x8, PROC_REGS+16*15+8]
  // make sure we don't clobber the kernel stack pointer
  mov x11, sp
  str x11, [x8]
  // restore sp to current user sp
  mov sp, x12

  add x30, x21, w30, uxtw
  ret

.section .note.GNU-stack,"",@progbits

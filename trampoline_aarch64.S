#define PROC_REGS 16
#define REG_BASE x21

.text

.macro get_tls_vars
  mov x11, x0
  mov x12, x30
  mrs x13, tpidr_el0

  // lfi_myctx in x8
  adrp x0, :tlsdesc:lfi_myctx
  ldr x8, [x0, :tlsdesc_lo12:lfi_myctx]
  add x0, x0, :tlsdesc_lo12:lfi_myctx
  .tlsdesccall lfi_myctx
  blr x8
  ldr x8, [x13, x0]

  // lfi_retfn in x9
  adrp x0, :tlsdesc:lfi_retfn
  ldr x9, [x0, :tlsdesc_lo12:lfi_retfn]
  add x0, x0, :tlsdesc_lo12:lfi_retfn
  .tlsdesccall lfi_retfn
  blr x9
  ldr x9, [x13, x0]

  // lfi_targetfn in x10
  adrp x0, :tlsdesc:lfi_targetfn
  ldr x10, [x0, :tlsdesc_lo12:lfi_targetfn]
  add x0, x0, :tlsdesc_lo12:lfi_targetfn
  .tlsdesccall lfi_targetfn
  blr x10
  ldr x10, [x13, x0]

  mov x30, x12
  mov x0, x11
.endm

.global lfi_trampoline
lfi_trampoline:
  stp d8, d9,   [sp, #-16]!
  stp d10, d11, [sp, #-16]!
  stp d12, d13, [sp, #-16]!
  stp d14, d15, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  stp x21, x22, [sp, #-16]!
  stp x23, x24, [sp, #-16]!
  stp x25, x26, [sp, #-16]!
  stp x27, x28, [sp, #-16]!
  stp x29, x30, [sp, #-16]!
  get_tls_vars

  ldr x12, [x8, PROC_REGS+16*15+8]
  // save user sp to stack
  ldr x13, [x8]
  stp x12, x13, [sp, #-16]!
  adr x30, .return
  stp xzr, x30, [sp, #-16]!
  // save kernel stack
  mov x11, sp
  str x11, [x8]
  // set user stack
  mov sp, x12
  // set return address to lfi_retfn
  mov x30, x9
  // set base pointer
  ldr REG_BASE, [x8, PROC_REGS+8*21]
  // set address pointer to a valid value
  mov x18, REG_BASE
  mov x8, #0
.entry:
  add x10, REG_BASE, w10, uxtw
  br x10
.return:
  // restore the user sp to its initial value
  ldp x22, xzr, [sp], 16
  str x22, [REG_BASE, PROC_REGS+16*15+8]
  // restore callee-saved registers
  ldp x29, x30, [sp], 16
  ldp x27, x28, [sp], 16
  ldp x25, x26, [sp], 16
  ldp x23, x24, [sp], 16
  ldp x21, x22, [sp], 16
  ldp x19, x20, [sp], 16
  ldp d14, d15, [sp], 16
  ldp d12, d13, [sp], 16
  ldp d10, d11, [sp], 16
  ldp d8, d9,   [sp], 16
  br x30

.section .note.GNU-stack,"",@progbits

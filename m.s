	.file	"m.c"
	.intel_syntax noprefix
# GNU C17 (GCC) version 14.1.1 20240507 (x86_64-pc-linux-gnu)
#	compiled by GNU C version 14.1.1 20240507, GMP version 6.3.0, MPFR version 4.2.1, MPC version 1.3.1, isl version isl-0.26-GMP

# GGC heuristics: --param ggc-min-expand=100 --param ggc-min-heapsize=131072
# options passed: -masm=intel -mtune=generic -march=x86-64
	.text
	.section	.rodata
.LC0:
	.string	"%d\n"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	push	rbp	#
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp	#,
	.cfi_def_cfa_register 6
	sub	rsp, 32	#,
# m.c:3: int main(void) {
	mov	rax, QWORD PTR fs:40	# tmp101, MEM[(<address-space-1> long unsigned int *)40B]
	mov	QWORD PTR -8[rbp], rax	# D.3214, tmp101
	xor	eax, eax	# tmp101
# m.c:4:     int ref = 10;
	mov	DWORD PTR -20[rbp], 10	# ref,
# m.c:5:     int *ptr = &ref;
	lea	rax, -20[rbp]	# tmp102,
	mov	QWORD PTR -16[rbp], rax	# ptr, tmp102
# m.c:6:     *ptr = 20;
	mov	rax, QWORD PTR -16[rbp]	# tmp103, ptr
	mov	DWORD PTR [rax], 20	# *ptr_4,
# m.c:8:     printf("%d\n", ref);
	mov	eax, DWORD PTR -20[rbp]	# ref.0_1, ref
	mov	esi, eax	#, ref.0_1
	lea	rax, .LC0[rip]	# tmp104,
	mov	rdi, rax	#, tmp104
	mov	eax, 0	#,
	call	printf@PLT	#
# m.c:10:     return 0;
	mov	eax, 0	# _7,
# m.c:11: }
	mov	rdx, QWORD PTR -8[rbp]	# tmp106, D.3214
	sub	rdx, QWORD PTR fs:40	# tmp106, MEM[(<address-space-1> long unsigned int *)40B]
	je	.L3	#,
	call	__stack_chk_fail@PLT	#
.L3:
	leave	
	.cfi_def_cfa 7, 8
	ret	
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (GNU) 14.1.1 20240507"
	.section	.note.GNU-stack,"",@progbits

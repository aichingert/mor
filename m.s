main:
.LFB0:
	push	rbp	#
	mov	rbp, rsp	#,
	sub	rsp, 32	#,
# m.c:1: int main(void) {
	mov	rax, QWORD PTR fs:40	# tmp100, MEM[(<address-space-1> long unsigned int *)40B]
	mov	QWORD PTR -8[rbp], rax	# D.2778, tmp100
	xor	eax, eax	# tmp100
# m.c:2:     int ref = 15;
	mov	DWORD PTR -20[rbp], 15	# ref,


# m.c:3:     int *ptr = &ref;
	lea	rax, -20[rbp]	# tmp101,
	mov	QWORD PTR -16[rbp], rax	# ptr, tmp101


# m.c:4:     *ptr = 20;
	mov	rax, QWORD PTR -16[rbp]	# tmp102, ptr
	mov	DWORD PTR [rax], 20	# *ptr_3,


# m.c:6:     return ref;
	mov	eax, DWORD PTR -20[rbp]	# _5, ref
# m.c:7: }
	mov	rdx, QWORD PTR -8[rbp]	# tmp104, D.2778
	sub	rdx, QWORD PTR fs:40	# tmp104, MEM[(<address-space-1> long unsigned int *)40B]
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

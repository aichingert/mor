.text
main:
.LFB0:
	push	rbp
	mov	rbp, rsp
# k.c:2:     int a = 10;

	mov	DWORD PTR -8[rbp], 10	# a,
# k.c:3:     int b = 10 - a;

	mov	eax, 10	# tmp103,
	sub	eax, DWORD PTR -8[rbp]	# b_2, a
	mov	DWORD PTR -4[rbp], eax	# b, b_2

# k.c:5:     return b;
	mov	eax, DWORD PTR -4[rbp]	# _3, b
# k.c:6: }
	pop	rbp	#
	ret	

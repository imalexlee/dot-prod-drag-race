format ELF64 executable 3

struc point x, y, z {
	.x dd x
	.y dd y
	.z dd z
}

segment readable writeable

point_ex	point	1.0, 2.0, 3.0
align 32
points_1	rd	3000					; array 1 to hold 1000 point structures
points_2	rd	3000					; array 2 to hold 1000 point structures
points_len 	= $ - points_2					; length of array
iteration_count = 10000000 

segment readable executable

fill_arrays:
	; for (int i = 0; i < 3000, i++)
	;	points_1[i] = point_ex;
	;	points_2[i] = point_ex;
.fill_loop:
	mov		edi, [point_ex.x]
	mov		[points_1 + rax], edi
	mov		[points_2 + rax], edi
	mov		edi, [point_ex.y]
	mov		[points_1 + rax + 4], edi
	mov		[points_2 + rax + 4], edi
	mov		edi, [point_ex.z]
	mov		[points_1 + rax + 8], edi 
	mov		[points_2 + rax + 8], edi 
	add		rax, 12					; increment by one 3d float vector
	cmp		rax, points_len
	jl		.fill_loop
	ret

entry $
	call 		fill_arrays
	xor		rdi, rdi				; j = 0
	mov		r8, points_len
.outer_loop:	
	xor		rax, rax				; i = 0
.inner_loop:
	; dot product. (x_1 * x_2) + (y_1 * y_2) + (z_1 * z_2)
	vmovss		xmm0, [points_1 + rax]			; move scalar
	vmovss		xmm1, [points_1 + rax + 4]		; move scalar
	vmovss		xmm2, [points_1 + rax + 8]		; move scalar
	vmulss		xmm0, xmm0, [points_2 + rax]		; multiply scalar
	vfmadd231ss	xmm0, xmm1, [points_2 + rax + 4]	; fused multiply and add
	vfmadd231ss	xmm0, xmm2, [points_2 + rax + 8]	; fused multiply and add
	; iteration logic
	add		rax, 12
	cmp		rax, points_len
	jl		.inner_loop
	inc		rdi
	cmp		rdi, iteration_count			; see if within 10,000,000 iterations
	jl		.outer_loop
	; exit with return code 0
	mov	rax, 60
	mov	rdi, 0
	syscall

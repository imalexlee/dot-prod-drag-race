format ELF64 executable 3

struc point x, y, z {
	.x dd x
	.y dd y
	.z dd z
}

struc points len {
	.x_arr rd len
	.y_arr rd len
	.z_arr rd len
}


segment readable writeable

point_ex	point	1.0, 2.0, 3.0
align 32
points_1	points	1000					; struct holds 3, 1000 element arrays for x, y, & z 
points_2	points	1000					; struct holds 3, 1000 element arrays for x, y, & z
points_len 	= ($ - points_2) / 3
iteration_count = 10000000 

segment readable executable

fill_arrays:
	; for (int i = 0; i < 1000, i++)
	;	points_1.x[i] = point_ex.x;
	;	points_2.x[i] = point_ex.x;
	;	points_1.y[i] = point_ex.y;
	;	points_2.y[i] = point_ex.y;
	;	points_1.z[i] = point_ex.z;
	;	points_2.z[i] = point_ex.z;
.fill_loop:
	mov		edi, [point_ex.x]
	mov		[points_1.x_arr + rax], edi
	mov		[points_2.x_arr + rax], edi
	mov		edi, [point_ex.y]
	mov		[points_1.y_arr + rax], edi
	mov		[points_2.y_arr + rax], edi
	mov		edi, [point_ex.z]
	mov		[points_1.z_arr + rax], edi
	mov		[points_2.z_arr + rax], edi
	add		rax, 4
	cmp		rax, points_len
	jl		.fill_loop
	ret

entry $
	call 		fill_arrays
	xor		rdi, rdi				; j = 0
.outer_loop:	
	xor		rax, rax				; i = 0
.inner_loop:
	; dot product. (x_1 * x_2) + (y_1 * y_2) + (z_1 * z_2)
	vmovaps		ymm0, [points_1 + rax ]			; move 8 aligned x values
	vmovaps		ymm1, [points_1 + rax + 4000]		; move 8 aligned y values. y_arr start = sizeof(float) * 1000
	vmovaps		ymm2, [points_1 + rax + 8000]		; move 8 aligned z values. z_arr start = sizeof(float) * 2000
	vmulps		ymm0, ymm0, [points_2 + rax]
	vfmadd231ps	ymm0, ymm1, [points_2 + rax + 4000]
	vfmadd231ps	ymm0, ymm2, [points_2 + rax + 8000]
	; iteration logic
	add		rax, 32
	cmp		rax, 4000
	jl		.inner_loop
	inc		rdi
	cmp		rdi, iteration_count			; see if within 10,000,000 iterations
	jl		.outer_loop	
	; exit with return code 0
	mov	rax, 60
	mov	rdi, 0
	syscall


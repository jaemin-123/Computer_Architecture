	.file	"program.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_c2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	1
	.globl	func
	.type	func, @function
func:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	mv	s0,a0
	add	a0,a1,a0
	bge	a1,zero,.L5
.L1:
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
.L5:
	addi	a1,a1,-1
	mv	a0,s0
	call	func
	add	a0,a0,s0
	j	.L1
	.size	func, .-func
	.align	1
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	sw	ra,12(sp)
	lui	a5,%hi(f)
	li	a4,2
	sw	a4,%lo(f)(a5)
	lui	a5,%hi(g)
	li	a4,3
	sw	a4,%lo(g)(a5)
	li	a1,3
	li	a0,2
	call	func
	lui	a5,%hi(y)
	sw	a0,%lo(y)(a5)
	lw	ra,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	main, .-main
	.globl	y
	.globl	g
	.globl	f
	.section	.sbss,"aw",@nobits
	.align	2
	.type	y, @object
	.size	y, 4
y:
	.zero	4
	.type	g, @object
	.size	g, 4
g:
	.zero	4
	.type	f, @object
	.size	f, 4
f:
	.zero	4
	.ident	"GCC: ('corev-openhw-gcc-win64-20230622') 12.0.1 20220422 (experimental)"

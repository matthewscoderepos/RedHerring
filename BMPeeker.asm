##############################
#         BMPeeker           #
#                            #
#       Calvin Crino         #
#                            #
##############################

# this program was created to test acessing an arbitrary BMP
# and returns critcal information to be used in RGB Herring

# see BMP Format Description Simple.html for format desc.

#############################################################
.data
readPrompt:	 	.asciiz "enter the full file path to the target bmp (c:\...\example.bmp): "
isntBMP:		.asciiz "File is not BMP"
fileSize:		.asciiz "Total File Size in bytes: "
pixelMapStart:		.asciiz "Pixel data begins at: "
imageDimensions:	.asciiz "Image Dimensions (WxH): "
pixelDepth:		.asciiz "Pixel color depth bits: "
imageCompression:	.asciiz "Compression detected !"
colorMap:		.asciiz "Color Map detected, Color count: "
finString:		.space 100

.macro tell (%string)
li $v0, 4
la $a0, %string
syscall
.end_macro

.macro listen (%fin, %length)
li $v0, 8
la $a0, %fin
li $a1, %length
syscall
.end_macro

.text

getFileName:
	tell (readPrompt)
	
	listen (finString, 100)
	
	# newline to null
	la $t1, finString
	li $t2, 10
	loop_1:
	lbu $t0, 0($t1)
	bne $t0, $t2, contiune_1
	sb $zero, 0($t1)
	contiune_1:	
	addi $t1, $t1, 1
	bne $t0, $zero, loop_1
	
	#open the file for read
	li   $v0, 13 
	la   $a0, finString
	li   $a1, 0
	li   $a2, 0
	syscall
	move $s0, $v0
	
	#allocate 54 bytes (header min size)
	li $v0, 9
	li $a0, 54	
	syscall
	move $s1, $v0	# save allocated memory pointer
	
	#read file header to buffer
	li   $v0, 14
	move $a0, $s0		# input file pointer
	move $a1, $s1		# input header buffer pointer
	li   $a2, 54		# min size header
	syscall
	
	lhu $t1, 0($s1)
	li $t0,	19778
	beq $t1, $t0, is_bmp
	tell (isntBMP)
	j end
	
is_bmp:	lw $t0, 0($s1)
	andi $t0, 0xFFFF0000
	lhu $t1, 2($s1)
	add $t0, $t1, $t0
	tell (fileSize)
	li $v0, 1
	move $a0, $t0
	syscall
	li $v0, 11
	li $a0, 10
	syscall
	
	
	
	
	
	
	
	
end:	li $v0, 10
	syscall
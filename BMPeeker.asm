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
pixelMapStart:	.asciiz "Pixel data begins at: "
imageDimensions:	.asciiz "Image Dimensions (WxH): "
pixelDepth:		.asciiz "Pixel color depth bits: "
imageCompression:	.asciiz "Compression detected !"
colorMap:		.asciiz "Color Map detected, Color count: "
finString:		.space 100

.macro tell (%string)		# prints a string to console via immediate adress 
li $v0, 4
la $a0, %string
syscall
.end_macro

.macro listen (%fin, %length)	# reads a string from user of length
li $v0, 8
la $a0, %fin
li $a1, %length
syscall
.end_macro

.macro chari (%char)		# prints a character to console via immediate value
li $v0, 11
li $a0, %char
syscall
.end_macro

.macro intr (%intr)		# prints an integer to screen via register value
li $v0, 1
move $a0, %intr
syscall
.end_macro

.macro intru (%uintr)		# prints an unsigned integer to screen via register value
li $v0, 36
move $a0, %uintr
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
	
	#allocate 56 bytes (header min size 54, padded by 2 for word align)
	li $v0, 9
	li $a0, 56	
	syscall
	move $s1, $v0	# save allocated memory pointer
	addi $s1, $s1, 2	# ignore padding bytes
	
	#read file header to buffer
	li   $v0, 14
	move $a0, $s0		# input file pointer
	move $a1, $s1		# input header buffer pointer
	li   $a2, 54		# min size header
	syscall
	
	# check if first two bytes = BM, bytes 0-1
	lhu $t1, 0($s1)				# load a half
	li $t0,	0x00004d42			# load hex value of BM, remember edianess 
	beq $t1, $t0, is_bmp			# if not equal, abort read
	tell (isntBMP)
	j end
	
is_bmp:		# read file size in bytes, bytes 2-5
	lw $t0, 2($s1)				# after first two header is now word aligned
	tell (fileSize)
	intru ($t0)
	chari (10)
	
			# read bytes to pixelmap, 10-13
	lw $t0, 10($s1)
	tell (pixelMapStart)
	intru ($t0)
	chari (10)
	
	tell (imageDimensions)		
			# read width in pixels, 18-21
	lw $t0, 18($s1)
	intru ($t0)					# value out
	chari (120)					# "x" out
			# read height in pixels, 22-25
	lw $t0, 22($s1)
	intru ($t0)					# value out
	chari (10)					# "\n" out
	
			# read color depth value, 28-29
	lhu $t0, 28($s1)
	tell (pixelDepth)
	intr ($t0)					# value out
	chari (10)					# "\n" out
	
			# check if there is compression, 30-33
	lw $t0, 30($s1)					# should be a value in range 0..3
	beq $t0, $zero, no_compression		# 0 = no compression
	tell (imageCompression)				# else report compression
	chari (10)
no_compression:
	
			# check if color table exists and its size, 46-49
	lw $t0, 46($s1)					# should be a value between 0..256
	beq $t0, $zero, no_color_table		# 0 = no color table
	tell (colorMap)					# else its a color table of $t0 values
	intru ($t0)						# report $t0
	chari (10)						# "\n" out
no_color_table:

end:	li $v0, 10
	syscall

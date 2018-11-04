##############################
#      RGB Herring           #
#                            #
#      Matthew Sutton        #
#       Calvin Crino         #
#        James Bors          #
#                            #
##############################
#$s0 holds active file location
#$s1 holds active file pointer
#$s2 holds input image header
#$s3 holds input image pixel map, and then $s3 - 4 holds size of input image pixel map
#$s4 holds message pointer

.include "Macros.asm"

.data
 MainMenu: .asciiz "RGB Herring\n\nChoose an Operation:\n1). encode a message\n2). decode a message\n3). quit\n\n>"
 InvalidInput: .asciiz "\nsorry response not expected\n\n" 
 EncodeMenu: .asciiz "Choose an Encoding Method:\n1).simple LSB\n0). abort\n\n>"
 DecodeMenu: .asciiz "Choose the Encoding key:\n1).simple LSB\n0). abort\n\n>"
 ImageFilePrompt: .asciiz "Enter the full file path to the Bitmap:\nEx: C:\\Users\\JohnDoe\Pictures\toEncodeBitmap.bmp\n\n>"
 InputMessage: .asciiz "Enter the message to encode:\n\tdoes not support newlines.\n\n>"
 ExportFilePrompt: .asciiz "Enter the full file path for the generated Bitmap:\nEx: C:\\Users\\JohnDoe\Pictures\secretMessageBitmap.bmp\n\n>"
 
 finString: .space 128
 foutString: .space 128
 
.text
main:
	tell (MainMenu, adr)
	readc ()
	li $t0, '1'
	beq $v0, $t0, StartEncode
	li $t0, '2'
	beq $v0, $t0, StartDecode
	li $t0, '3'
	beq $v0, $t0, exit
	tell (InvalidInput, adr)
	j main

StartEncode:
	# read in picture
	jal ReadPicture
	
	# read in message
	jal ReadMessage
	
	# prompt encoding options
	EncodingInputLoop:
	tell (EncodeMenu, adr)
	readc ()
	li $t0, '1'
	bne $v0, $t0, EncodeSkip1
	jal Encode1
	j exitEncode
	EncodeSkip1:
	li $t0, '3'
	beq $v0, $t0, main
	tell (InvalidInput, adr)
	j EncodingInputLoop
	exitEncode:
	
	# write picture
	jal WritePicture
	
	# return to main menu
	j main
	
StartDecode:
	# read in picture
	jal ReadPicture
	
	# prompt decoding method
	DecodingInputLoop:
	tell (DecodeMenu, adr)
	readc ()
	li $t0, '1'
	bne $v0, $t0, DecodeSkip1
	jal Decode1
	j exitDecode
	DecodeSkip1:
	li $t0, '3'
	beq $v0, $t0, main
	tell (InvalidInput, adr)
	j DecodingInputLoop
	exitDecode:
	
	# output message
	
	
	# return to main menu
	j main

ReadPicture:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	tell(ImageFilePrompt, adr)
	
	la $s0, finString
	listen ($s0, reg, 128, imd)
	
	move $a0, $s0
	jal SanitizeInput					# remove newline character
	
	openf ($s0, reg, READ)				# generates a file pointer
	move $s1, $v0					# save to active file pointer register
	
	#allocate 56 bytes (header min size 54, padded by 2 for word align)
	malloc (56, imd)
	move $s2, $v0					# save allocated memory pointer
	addi $s2, $s2, 2					# ignore padding bytes
	
	readf ($s1, reg, $s2, reg, 54, imd)		# header contents to header pointer
	
	#input validation of Image file
	lhu $t1, 0($s2)					# load a half
	li $t0,	0x00004d42				# load hex value of BM, remember edianess 
	bne $t1, $t0, exit
	
	
	# TO DO ADD DEPTH MANAGMENT
	lhu $t0, 28($s2)					# check for color depth 24
	li $t1, 24
	bne $t1, $t0, exit				# if not, abort
	
	#calculate pixel map size
	lw $t0, 2($s2) 					#load bytes in file
	uint ($t0, reg)
	lw $t1, 10($s2)					#load bytes to pixel map
	uint ($t1, reg)
	sub $t3, $t0, $t1					# bytes in file - bytes to map = bytes in map
	addi $s3, $t3, 4					# add space for size
	uint ($s3, reg)
	
	# allocate space for map load
	malloc ($s3, reg)
	move $s3, $v0					# $s3 is a space map size + 4 bytes
	sw $t3, 0($s3)						# save map size to first 4 bytes
	addi $s3, $s3, 4					# hide first 4 bytes for reading
	
	#read from file
	readf ($s1, reg, $s3, reg, $t3, reg)	# pixel map now in memory
	
	# Close the file 
	closef ($s1, reg)					# deactivate file pointer
	lw $ra 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
	
	
ReadMessage:	# TODO - add .txt file input, currently reads in at most 1024 characters from command line
	
	tell (InputMessage, adr)
	
	malloc (1024, imd)
	move $s4, $v0
	
	listen ($s4, reg, 1024, imd)
	jr $ra
	
	
Encode1:
	
	jr $ra
	
	
	
	
Decode1:
	
	jr $ra
	
	
	
	
WritePicture:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	tell (ExportFilePrompt, adr)
	
	la $s0, foutString
	listen ($s0, reg, 100, imd)
	
	move $a0, $s0
	jal SanitizeInput					# remove newline character

	#opens a new file with name given by user for writing
	openf (foutString, adr, WRITE)
	move $s1, $v0
	
	#begin writing from pictureBuffer
	writef ($s1, reg, $s2, reg, 54, imd)	# copy forward header
	lw $t3, -4($s6)
	writef ($s1, reg, $s3, reg, $t3, reg)	# copy in edited pixel map
	closef ($s1, reg)
	
	lw $ra 0($sp)
	addi $sp, $sp, 4
	jr $ra

SanitizeInput:
	lbu $t0, 0($a0)
	beqz $t0, nullReached
	addi $a0, $a0, 1
	j SanitizeInput
	nullReached:
	addi $a0, $a0, -1
	lbu $t0, 0($a0)
	li $t1, '\n'
	bne $t0, $t1, notNewline
	sb $zero, 0($a0)
	notNewline:	
	jr $ra

exit:
	li $v0, 10
	syscall


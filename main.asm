# # # # # # # # # # # # # # # #
#        RGBHerring           #
#                             #
#      Matthew Sutton         #
#       Calvin Crino          #
#        James Bors           #
#                             #
# # # # # # # # # # # # # # # #
#$s0 holds active file location
#$s1 holds active file pointer
#$s2 holds input image header
#$s3 holds input image pixel map, and then $s3 - 4 holds size of input image pixel map
#$s4 holds message pointer
#$s5 - $s7, reserved for encoding/decoding operations

.include "Macros.asm"


.data
 MainMenu: .asciiz "\nRGB Herring\n\nChoose an Operation:\n1). encode a message\n2). decode a message\n3). quit\n\n>"
 InvalidInput: .asciiz "\nsorry response not expected\n\n" 
 EncodeMenu: .asciiz "\nChoose an Encoding Method:\n1).chromatic LSB\n\t\tUse each bit in order to store the message.\n\t\tVery insecure.\n2).monochrome LSB\n\t\tPick a color: red, green, or blue\n\t\tEncodes the message in just that color's channel. \n\t\tMore secure than Chromatic LSB.\n3).keyed monochrome LSB\n\t\tProvide a key and the program will randomly select a single color\n\t\tfrom each pixel to store the message in.\n\t\tMuch more secure than chromatic LSB.\n4).keyed chromatic LSB\n\t\tProvide a key and the program will randomly select an encoding sequence in each pixel.\n\t\tVery secure. More secure than all other options.\n0). abort\n\n>"
 DecodeMenu: .asciiz "\nChoose the Encoding key:\n1).chromatic LSB\n2).monochrome LSB\n3).keyed monochrome LSB\n4).keyed chromatic LSB\n0). abort\n\n>"
 ImageFilePrompt: .asciiz "\nEnter the full file path to the Bitmap:\nEx: C:\\Users\\JohnDoe\\Pictures\\toEncodeBitmap.bmp\n\n>"
 InputMessage: .asciiz "\nEnter the message to encode:\n\tdoes not support newlines.\n\n>"
 ExportFilePrompt: .asciiz "\nEnter the full file path for the generated Bitmap:\nEx: C:\\Users\\JohnDoe\\Pictures\\secretMessageBitmap.bmp\n\n>"
 ImageEndOfFileE: .asciiz "\nWarning, message encoding terminated due to image End Of File\n"
 ImageEndOfFileD: .asciiz "\nWarning, message decoding terminated without reaching null character\n"
 chooseColor: .asciiz "\nWhich color would you like to encode in? R, B, or G? (Single letter, Capitalized only)\n"
 rgbQuestion: .asciiz "\nWhich color was used? R, B, or G? (Single letter, Capitalized only.) "
 KeyMessage: .asciiz "\nEnter the key: \n\tMax 8 characters ex: \"ApplePie\".\n\n>"
 depthError: .asciiz "\nOnly BMP's of color depth 24 may be used for encoding/decoding purposes. Please try again with a different file.\n"
 finString: .space 128
 foutString: .space 128
 
.text
main:
	add $a3, $0, $0
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
	EncodeSkip:
		li $t0, '1'
		bne $v0, $t0, EncodeSkip1
		jal EnChromaticLSB
		j exitEncode
	EncodeSkip1:
    	li $t0, '2'
    	bne $v0, $t0,EncodeSkip2
    	jal EnMonoLSB
    	j exitEncode	
	EncodeSkip2:
		li $t0, '3'
    	bne $v0, $t0,EncodeSkip3
    	jal EnKeyedMonoLSB
    	j exitEncode
	EncodeSkip3:	
		li $t0, '4'
    	bne $v0, $t0,EncodeSkip4
    	jal EnKeyedChromLSB
    	j exitEncode
	EncodeSkip4:	
		li $t0, '0'
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
	DecodeSkip:
		li $t0, '1'
		bne $v0, $t0, DecodeSkip1
		jal DeChromaticLSB
		j exitDecode
	DecodeSkip1:
		li $t0, '2'
		bne $v0, $t0, DecodeSkip2
		jal DeMonoLSB
		j exitDecode
	DecodeSkip2:
		li $t0, '3'
    	bne $v0, $t0,DecodeSkip3
    	jal DeKeyedMonoLSB
    	j exitDecode
	DecodeSkip3:
		li $t0, '4'
    	bne $v0, $t0,DecodeSkip4
    	jal DeKeyedChromLSB
    	j exitDecode
	DecodeSkip4:
		li $t0, '0'
		beq $v0, $t0, main
		tell (InvalidInput, adr)
		j DecodingInputLoop
	exitDecode:
	
	# output message
	char ('\n', imd)
	tell ($s4, reg)
	char ('\n', imd)
	
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
	
	
	#Added simple depth managment, just checks if 24 
	lhu $t0, 28($s2)					# check for color depth 24
	li $t1, 24
	beq $t1, $t0, Cont				# if not, abort
	tell(depthError, adr)
	j main

	Cont:
	#calculate pixel map size
	lw $t0, 2($s2) 					#load bytes in file
	lw $t1, 10($s2)					#load bytes to pixel map
	sub $t3, $t0, $t1					# bytes in file - bytes to map = bytes in map
	addi $s3, $t3, 4					# add space for size
	
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
	
	malloc (65536, imd)
	move $s4, $v0
	
	listen ($s4, reg, 65536, imd)
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
	lw $t3, -4($s3)
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

	.include "chromaticlSB.asm"
	.include "monoLSB.asm"
	.include "keyMonoLSB.asm"
	.include "keyChromLSB.asm"


exit:
	li $v0, 10
	syscall

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
#$s5 - $s7, reserved for encoding/decoding operations

.include "Macros.asm"

.data
 MainMenu: .asciiz "\nRGB Herring\n\nChoose an Operation:\n1). encode a message\n2). decode a message\n3). quit\n\n>"
 InvalidInput: .asciiz "\nsorry response not expected\n\n" 
 EncodeMenu: .asciiz "\nChoose an Encoding Method:\n1).simple LSB\n2).monochrome LSB\n3).random monochrome LSB\n0). abort\n\n>"
 DecodeMenu: .asciiz "\nChoose the Encoding key:\n1).simple LSB\n2).monochrome LSB\n3).random monochrome LSB\n0). abort\n\n>"
 ImageFilePrompt: .asciiz "\nEnter the full file path to the Bitmap:\nEx: C:\\Users\\JohnDoe\\Pictures\\toEncodeBitmap.bmp\n\n>"
 InputMessage: .asciiz "\nEnter the message to encode:\n\tdoes not support newlines.\n\n>"
 ExportFilePrompt: .asciiz "\nEnter the full file path for the generated Bitmap:\nEx: C:\\Users\\JohnDoe\\Pictures\\secretMessageBitmap.bmp\n\n>"
 ImageEndOfFileE: .asciiz "\nWarning, message encoding terminated due to image End Of File\n"
 ImageEndOfFileD: .asciiz "\nWarning, message decoding terminated without reaching null character\n"
 chooseColor: .asciiz "\nWhich color would you like to encode in? R, B, or G? (Single letter, Capitalized only)\n"
 rgbQuestion: .asciiz "\nWhich color was used? R, B, or G? (Single letter, Capitalized only.) "
 KeyMessage: .asciiz "\nEnter the secret key: \n\tdoes not support newlines.\n\n>"
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
	li $t0, '1'
	bne $v0, $t0, EncodeSkip1
	jal EnSimpleLSB
	j exitEncode
	EncodeSkip1:
    li $t0, '2'
    bne $v0, $t0,EncodeSkip2
    jal EnMonoLSB
    j exitEncode
	EncodeSkip2:
    li $t0, '3'
    bne $v0, $t0,EncodeSkip3
    jal EnRandomMonoLSB
    j exitEncode
	EncodeSkip3:	
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
	li $t0, '1'
	bne $v0, $t0, DecodeSkip1
	jal DeSimpleLSB
	j exitDecode
	DecodeSkip1:
	li $t0, '2'
	bne $v0, $t0, DecodeSkip2
	jal DeMonoLSB
	j exitDecode
	DecodeSkip2:
	li $t0, '3'
    bne $v0, $t0,DecodeSkip3
    jal DeRandomMonoLSB
    j exitDecode
	DecodeSkip3:
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
	
	
	# TODO ADD DEPTH MANAGMENT
	lhu $t0, 28($s2)					# check for color depth 24
	li $t1, 24
	bne $t1, $t0, exit				# if not, abort
	
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
	
	malloc (1024, imd)
	move $s4, $v0
	
	listen ($s4, reg, 1024, imd)
	jr $ra
	
ReadKey:

	tell (KeyMessage, adr)
	
	malloc (1024, imd)
	move $t8, $v0
	
	listen ($t8, reg, 1024, imd)

	jr $ra


EnSimpleLSB:
	
	
	lw $s5, 18($s2)					# gets the width of pixel map in pixels
	mul $s5, $s5, 3					# width of pixel map in bytes
	move $s6, $s5					# copy of width
	andi $t1, $s5, 0x00000003		# check if last 2 bits are not zero
	beqz $t1, ESLSB_aligned			# this evalutates false if and only if the byte count is not divisible by 4
	andi $s6, $s6, 0xfffffffc		# so then generated an adjusted width add padding until
	addi $s6, $s6, 4				# it is divisible by 4
	ESLSB_aligned:
	lw $s7, 22($s2)					# gets the height of pixel map in pixels
	slt $t0, $s7, $0
	beqz $t0, ESLSB_posHeight
	not $s7, $s7
	addi $s7, $s7, 1
	ESLSB_posHeight:
	#Sets up the pixel array so that we can work on it. Pads width, sets the height to be positive

	move $t5, $0					# ending flag
	move $t7, $0					# width index
	move $t8, $0					# height index
	#Sets t5, t7, and t8 to 0, all used for determining where we are in the pixel array

	ESLSB_nextByte:
	lbu $t0, 0($s4)					# get next message byte
	bnez $t5, ESLSB_Exit
	bnez $t0, ESLSB_Cont			# check if message is fully encoded yet
	addi $t5, $t5, 1
	#Loads 8 bits (1 byte) of the message into t0. If this fails and t0 is set to 0, t5 is set to 1 and the loop will exit on the next iteration 

	ESLSB_Cont:
	addi $s4, $s4, 1
	li $t9, 8						# message byte index, 8 bits left to encode
	#Moves the message pointer 1 byte forward because we loaded the byte already in the last loop, sets t9 to 8 (used to determine if we need to load another byte of message or not)


	ESLSB_nextBit:
	andi $t1, $t0, 1				# bit of message to append
	mult $t8, $s6					# 
	mflo $t6						#
	addu $t6, $t6, $t7				#
	addu $t6, $t6, $s3				# address of next channel to edit
	lbu $t2, 0($t6)					#loads the byte that we are changing into t2
	andi $t2, $t2, 0xfe				# discard LSB
	or $t2, $t2, $t1				# replace with message
	sb $t2, 0($t6)					#stores the byte in question into t6
	#Determines where in the pixel array we are at, loads the byte we are at and edits that byte to contain our message data


	add $t7, $t7, 1					# increment width index
	bne $t7, $s5, ESLSB_wnRange		# check its still within range
	add $t8, $t8, 1					# if not increment height index
	beq $t8, $s7, ESLSB_imageEnd	# check if height within range
	move $t7, $0					# reset width index
	#Determines if we are at the end of a line, if we are it resets the width index and moves us down a row. If we drop off the end of the pixel array we are out of image data

	ESLSB_wnRange:
	addi $t9, $t9, -1				# decrement byte index
	beqz $t9, ESLSB_nextByte		# if 0 then get next byte else
	srl $t0, $t0, 1
	j ESLSB_nextBit					# get next bit
	#Determines if we still have message data in our loaded byte, if we do not it loads a new byte and if we do it starts the message encode on the next bit

	ESLSB_imageEnd:
	tell (ImageEndOfFileE, adr)
	ESLSB_Exit:
	jr $ra
	
	
	
	
DeSimpleLSB:
	
	lw $t0, -4($s3)					# get map size
	div $t0, $t0, 8					# approximate max message size
	addi $t0, $t0, 1				# pad 1
	malloc ($t0, reg)				# 
	move $s4, $v0					# move to message pointer
	#allocates space for the encoded message
	
	lw $s5, 18($s2)					# gets the width of pixel map in pixels
	li $t1, 3						# 3 bytes per pixel
	mult $s5, $t1
	mflo $s5						# width of pixel map in bytes
	move $s6, $s5					# copy of width
	andi $t1, $s5, 0x00000003		# check if last 2 bits are not zero
	beqz $t1, DSLSB_aligned			# this evalutates true if and only if the byte count is not divisible by 4
	andi $s6, $s6, 0xfffffffc		# so then generated an adjusted width add padding until
	addi $s6, $s6, 4				# it is divisible by 4
	DSLSB_aligned:
	lw $s7, 22($s2)					# gets the height of pixel map in pixels
	slt $t0, $s7, $0
	beqz $t0, DSLSB_posHeight
	not $s7, $s7
	addi $s7, $s7, 1
	DSLSB_posHeight:
	#Sets up the pixel array so that we can work on it. Pads width, sets the height to be positive

	move $t5, $s4					# message index
	move $t7, $0					# width index
	move $t8, $0					# height index
	j DSLSB_skipIn
	#Sets t5 to the message pointer

	DSLSB_nextByte: 
	srl $t0, $t0, 1
	sb $t0, 0($t5)
	beqz $t0, DSLSB_Exit
	add $t5, $t5, 1
	#shifts t0 to the left, stores t0 in t5 (the message), if t0 = 0, were done

	DSLSB_skipIn:
	move $t0, $0					# reset message byte
	li $t9, 8						# message byte index, 8 bits left to decode
	#t0 = 0, bits we need to read = 8

	DSLSB_nextBit:
	mul $t6, $t8, $s6				# 
	addu $t6, $t6, $t7				#
	addu $t6, $t6, $s3				# address of next channel to read
	lbu $t1, 0($t6)					#loads a byte from t6 into t1
	andi $t1, $t1, 1				# discard everything but LSB
	sll $t1, $t1, 8					#shift t1 left 8 bits
	add $t0, $t0, $t1				# append LSB
	
	#checkBounds
	add $t7, $t7, 1					# increment width index
	bne $t7, $s5, DSLSB_wnRange		# check its still within range
	add $t8, $t8, 1					# if not increment height index
	beq $t8, $s7, DSLSB_imageEnd	# check if height within range
	li $t7, 0						# reset width index
	#Checking bounds, resets width and increases height when needed, if we drop off the image we end

	DSLSB_wnRange:
	addi $t9, $t9, -1				# decrement byte index
	beqz $t9, DSLSB_nextByte		# if 0 then get next byte else
	srl $t0, $t0, 1
	j DSLSB_nextBit					# get next bit
	#if we have bits left to decode get the next bit, otherwise get the next byte 

	DSLSB_imageEnd:
	tell (ImageEndOfFileD, adr)
	DSLSB_Exit:
	jr $ra
	

EnMonoLSB:
	tell(chooseColor, adr)
	readc()
	li $t0, 0x52
	beq $v0, $t0, R 
	li $t0, 0x47
	beq $v0, $t0, G
	li $t0, 0x42
	beq $v0, $t0, B


	R:
	addi $t3, $0, 0 #R is the 0th byte, skip 0
	j endRGB
	G:
	addi $t3, $0, 1 #G is the 2nd byte, skip 1
	j endRGB
	B:
	addi $t3, $0, 2 #B is the 3rd byte, skip 2
	
    endRGB:

	lw $s5, 18($s2)					# gets the width of pixel map in pixels
	mul $s5, $s5, 3					# width of pixel map in bytes
	move $s6, $s5					# copy of width
	andi $t1, $s5, 0x00000003		# check if last 2 bits are not zero
	beqz $t1, EMLSB_aligned			# this evalutates false if and only if the byte count is not divisible by 4
	andi $s6, $s6, 0xfffffffc		# so then generated an adjusted width add padding until
	addi $s6, $s6, 4				# it is divisible by 4
	EMLSB_aligned:
	lw $s7, 22($s2)					# gets the height of pixel map in pixels
	slt $t0, $s7, $0
	beqz $t0, EMLSB_posHeight
	not $s7, $s7
	addi $s7, $s7, 1
	EMLSB_posHeight:
	#Sets up the pixel array so that we can work on it. Pads width, sets the height to be positive

	move $t5, $0					# ending flag
	move $t7, $t3					# width index
	move $t8, $0					# height index
	#Sets t5, t7, and t8 to 0, all used for determining where we are in the pixel array

	EMLSB_nextByte:
	lbu $t0, 0($s4)					# get next message byte
	bnez $t5, EMLSB_Exit
	bnez $t0, EMLSB_Cont			# check if message is fully encoded yet
	addi $t5, $t5, 1
	#Loads 8 bits (1 byte) of the message into t0. If this fails and t0 is set to 0, t5 is set to 1 and the loop will exit on the next iteration 

	EMLSB_Cont:
	addi $s4, $s4, 1
	li $t9, 8						# message byte index, 8 bits left to encode
	#Moves the message pointer 1 byte forward because we loaded the byte already in the last loop, sets t9 to 8 (used to determine if we need to load another byte of message or not)


	EMLSB_nextBit:
	andi $t1, $t0, 1				# bit of message to append
	mult $t8, $s6					# 
	mflo $t6						#
	addu $t6, $t6, $t7				#
	addu $t6, $t6, $s3				# address of next channel to edit
	lbu $t2, 0($t6)					#loads the byte that we are changing into t2
	andi $t2, $t2, 0xfe				# discard LSB
	or $t2, $t2, $t1				# replace with message
	sb $t2, 0($t6)					#stores the byte in question into t6
	#Determines where in the pixel array we are at, loads the byte we are at and edits that byte to contain our message data


	add $t7, $t7, 3					# increment width index
	bne $t7, $s5, EMLSB_wnRange		# check its still within range
	add $t8, $t8, 1					# if not increment height index
	beq $t8, $s7, EMLSB_imageEnd	# check if height within range
	move $t7, $t3					# reset width index
	#Determines if we are at the end of a line, if we are it resets the width index and moves us down a row. If we drop off the end of the pixel array we are out of image data

	EMLSB_wnRange:
	addi $t9, $t9, -1				# decrement byte index
	beqz $t9, EMLSB_nextByte		# if 0 then get next byte else
	srl $t0, $t0, 1
	j EMLSB_nextBit					# get next bit
	#Determines if we still have message data in our loaded byte, if we do not it loads a new byte and if we do it starts the message encode on the next bit

	EMLSB_imageEnd:
	tell (ImageEndOfFileE, adr)
	EMLSB_Exit:
	jr $ra
	

DeMonoLSB:
	tell(rgbQuestion, adr)
	readc()
	li $t0, 0x52
	beq $v0, $t0, DR 
	li $t0, 0x47
	beq $v0, $t0, DG
	li $t0, 0x42
	beq $v0, $t0, DB


	DR:
	addi $t3, $0, 0 #R is the 0th byte, skip 0
	j dEndRGB
	DG:
	addi $t3, $0, 1 #G is the 2nd byte, skip 1
	j dEndRGB
	DB:
	addi $t3, $0, 2 #B is the 3rd byte, skip 2
	
	dEndRGB:


	lw $t0, -4($s3)					# get map size
	div $t0, $t0, 8					# approximate max message size
	addi $t0, $t0, 1				# pad 1
	malloc ($t0, reg)				# 
	move $s4, $v0					# move to message pointer
	#allocates space for the encoded message
	
	lw $s5, 18($s2)					# gets the width of pixel map in pixels
	li $t1, 3						# 3 bytes per pixel
	mult $s5, $t1
	mflo $s5						# width of pixel map in bytes
	move $s6, $s5					# copy of width
	andi $t1, $s5, 0x00000003		# check if last 2 bits are not zero
	beqz $t1, DMLSB_aligned			# this evalutates true if and only if the byte count is not divisible by 4
	andi $s6, $s6, 0xfffffffc		# so then generated an adjusted width add padding until
	addi $s6, $s6, 4				# it is divisible by 4
	DMLSB_aligned:
	lw $s7, 22($s2)					# gets the height of pixel map in pixels
	slt $t0, $s7, $0
	beqz $t0, DMLSB_posHeight
	not $s7, $s7
	addi $s7, $s7, 1
	DMLSB_posHeight:
	#Sets up the pixel array so that we can work on it. Pads width, sets the height to be positive

	move $t5, $s4					# message index
	move $t7, $t3					# width index
	move $t8, $0					# height index
	j DMLSB_skipIn
	#Sets t5 to the message pointer

	DMLSB_nextByte: 
	srl $t0, $t0, 1
	sb $t0, 0($t5)
	beqz $t0, DMLSB_Exit
	add $t5, $t5, 1
	#shifts t0 to the left, stores t0 in t5 (the message), if t0 = 0, were done

	DMLSB_skipIn:
	move $t0, $0					# reset message byte
	li $t9, 8						# message byte index, 8 bits left to decode
	#t0 = 0, bits we need to read = 8

	DMLSB_nextBit:
	mul $t6, $t8, $s6				# 
	addu $t6, $t6, $t7				#
	addu $t6, $t6, $s3				# address of next channel to read
	lbu $t1, 0($t6)					#loads a byte from t6 into t1
	andi $t1, $t1, 1				# discard everything but LSB
	sll $t1, $t1, 8					#shift t1 left 8 bits
	add $t0, $t0, $t1				# append LSB
	
	#checkBounds
	add $t7, $t7, 3					# increment width index
	bne $t7, $s5, DMLSB_wnRange		# check its still within range
	add $t8, $t8, 1					# if not increment height index
	beq $t8, $s7, DMLSB_imageEnd	# check if height within range
	move $t7, $t3						# reset width index
	#Checking bounds, resets width and increases height when needed, if we drop off the image we end

	DMLSB_wnRange:
	addi $t9, $t9, -1				# decrement byte index
	beqz $t9, DMLSB_nextByte		# if 0 then get next byte else
	srl $t0, $t0, 1
	j DMLSB_nextBit					# get next bit
	#if we have bits left to decode get the next bit, otherwise get the next byte 

	DMLSB_imageEnd:
	tell (ImageEndOfFileD, adr)
	DMLSB_Exit:
	jr $ra

EnRandomMonoLSB:

	tell (KeyMessage, adr)
	
	malloc (1024, imd)
	move $t8, $v0
	
	listen ($t8, reg, 1024, imd)

	addi $t0, $t0, 0x0F
	div $t8, $t0
	mfhi $t8

    #Seeding Random Number Generator
	li $v0, 40 
    move $a1, $t8
    li $a0, 1 
    syscall 


    li $v0, 42
    li $a0, 1
    li $a1, 2
    syscall     #generate a random number (0-2) based on given key
    move $t9, $a0


	move $t3, $0
    beq	$t9, $t3, EndRandomRGB  #if t9 = 0, Red
    addi $t3, $t3, 1
    beq $t9, $t3, EndRandomRGB  #If t9 = 1, Blue
    addi $t3, $t3, 1
    beq $t9, $t3, EndRandomRGB  #If t9 = 2, Green

	EndRandomRGB:

	lw $s5, 18($s2)					# gets the width of pixel map in pixels
	mul $s5, $s5, 3					# width of pixel map in bytes
	move $s6, $s5					# copy of width
	andi $t1, $s5, 0x00000003		# check if last 2 bits are not zero
	beqz $t1, ERMLSB_aligned			# this evalutates false if and only if the byte count is not divisible by 4
	andi $s6, $s6, 0xfffffffc		# so then generated an adjusted width add padding until
	addi $s6, $s6, 4				# it is divisible by 4
	ERMLSB_aligned:
	lw $s7, 22($s2)					# gets the height of pixel map in pixels
	slt $t0, $s7, $0
	beqz $t0, ERMLSB_posHeight
	not $s7, $s7
	addi $s7, $s7, 1
	ERMLSB_posHeight:
	#Sets up the pixel array so that we can work on it. Pads width, sets the height to be positive

	move $t5, $0					# ending flag
	move $t7, $t3					# width index
	move $t8, $0					# height index
	#Sets t5, t7, and t8 to 0, all used for determining where we are in the pixel array

	ERMLSB_nextByte:
	lbu $t0, 0($s4)					# get next message byte
	bnez $t5, ERMLSB_Exit
	bnez $t0, ERMLSB_Cont			# check if message is fully encoded yet
	addi $t5, $t5, 1
	#Loads 8 bits (1 byte) of the message into t0. If this fails and t0 is set to 0, t5 is set to 1 and the loop will exit on the next iteration 

	ERMLSB_Cont:
	addi $s4, $s4, 1
	li $t9, 8						# message byte index, 8 bits left to encode
	#Moves the message pointer 1 byte forward because we loaded the byte already in the last loop, sets t9 to 8 (used to determine if we need to load another byte of message or not)


	ERMLSB_nextBit:
	andi $t1, $t0, 1				# bit of message to append
	mult $t8, $s6					# 
	mflo $t6						#
	addu $t6, $t6, $t7				#
	addu $t6, $t6, $s3				# address of next channel to edit
	lbu $t2, 0($t6)					#loads the byte that we are changing into t2
	andi $t2, $t2, 0xfe				# discard LSB
	or $t2, $t2, $t1				# replace with message
	sb $t2, 0($t6)					#stores the byte in question into t6
	#Determines where in the pixel array we are at, loads the byte we are at and edits that byte to contain our message data


	add $t7, $t7, 3					# increment width index
	bne $t7, $s5, ERMLSB_wnRange		# check its still within range
	add $t8, $t8, 1					# if not increment height index
	beq $t8, $s7, ERMLSB_imageEnd	# check if height within range
	move $t7, $t3					# reset width index
	#Determines if we are at the end of a line, if we are it resets the width index and moves us down a row. If we drop off the end of the pixel array we are out of image data

	ERMLSB_wnRange:
	addi $t9, $t9, -1				# decrement byte index
	beqz $t9, ERMLSB_nextByte		# if 0 then get next byte else
	srl $t0, $t0, 1
	j ERMLSB_nextBit					# get next bit
	#Determines if we still have message data in our loaded byte, if we do not it loads a new byte and if we do it starts the message encode on the next bit

	ERMLSB_imageEnd:
	tell (ImageEndOfFileE, adr)
	ERMLSB_Exit:
	jr $ra

DeRandomMonoLSB:
	
	tell (KeyMessage, adr)
	
	malloc (1024, imd)
	move $t8, $v0
	
	listen ($t8, reg, 1024, imd)

	addi $t0, $t0, 0x0F
	div $t8, $t0
	mfhi $t8
	

    #Seeding Random Number Generator
	li $v0, 40 
    move $a1, $t8
    li $a0, 1 
    syscall 


    dRandomLoop:
    li $v0, 42
    li $a0, 1
    li $a1, 2
    syscall     #generate a random number (0-2) based on given key
    move $t9, $a0


	move $t3, $0
    beq	$t9, $t3, dEndRandomRGB  #if t9 = 0, Red
    addi $t3, $t3, 1
    beq $t9, $t3, dEndRandomRGB  #If t9 = 1, Blue
    addi $t3, $t3, 1
    beq $t9, $t3, dEndRandomRGB  #If t9 = 2, Green
    j dRandomLoop #This statement shouldnt ever execute

	dEndRandomRGB:

	lw $t0, -4($s3)					# get map size
	div $t0, $t0, 8					# approximate max message size
	addi $t0, $t0, 1				# pad 1
	malloc ($t0, reg)				# 
	move $s4, $v0					# move to message pointer
	#allocates space for the encoded message
	
	lw $s5, 18($s2)					# gets the width of pixel map in pixels
	li $t1, 3						# 3 bytes per pixel
	mult $s5, $t1
	mflo $s5						# width of pixel map in bytes
	move $s6, $s5					# copy of width
	andi $t1, $s5, 0x00000003		# check if last 2 bits are not zero
	beqz $t1, DRMLSB_aligned			# this evalutates true if and only if the byte count is not divisible by 4
	andi $s6, $s6, 0xfffffffc		# so then generated an adjusted width add padding until
	addi $s6, $s6, 4				# it is divisible by 4
	DRMLSB_aligned:
	lw $s7, 22($s2)					# gets the height of pixel map in pixels
	slt $t0, $s7, $0
	beqz $t0, DRMLSB_posHeight
	not $s7, $s7
	addi $s7, $s7, 1
	DRMLSB_posHeight:
	#Sets up the pixel array so that we can work on it. Pads width, sets the height to be positive

	move $t5, $s4					# message index
	move $t7, $t3					# width index
	move $t8, $0					# height index
	j DRMLSB_skipIn
	#Sets t5 to the message pointer

	DRMLSB_nextByte: 
	srl $t0, $t0, 1
	sb $t0, 0($t5)
	beqz $t0, DRMLSB_Exit
	add $t5, $t5, 1
	#shifts t0 to the left, stores t0 in t5 (the message), if t0 = 0, were done

	DRMLSB_skipIn:
	move $t0, $0					# reset message byte
	li $t9, 8						# message byte index, 8 bits left to decode
	#t0 = 0, bits we need to read = 8

	DRMLSB_nextBit:
	mul $t6, $t8, $s6				# 
	addu $t6, $t6, $t7				#
	addu $t6, $t6, $s3				# address of next channel to read
	lbu $t1, 0($t6)					#loads a byte from t6 into t1
	andi $t1, $t1, 1				# discard everything but LSB
	sll $t1, $t1, 8					#shift t1 left 8 bits
	add $t0, $t0, $t1				# append LSB
	
	#checkBounds
	add $t7, $t7, 3					# increment width index
	bne $t7, $s5, DRMLSB_wnRange		# check its still within range
	add $t8, $t8, 1					# if not increment height index
	beq $t8, $s7, DRMLSB_imageEnd	# check if height within range
	move $t7, $t3						# reset width index
	#Checking bounds, resets width and increases height when needed, if we drop off the image we end

	DRMLSB_wnRange:
	addi $t9, $t9, -1				# decrement byte index
	beqz $t9, DRMLSB_nextByte		# if 0 then get next byte else
	srl $t0, $t0, 1
	j DRMLSB_nextBit					# get next bit
	#if we have bits left to decode get the next bit, otherwise get the next byte 

	DRMLSB_imageEnd:
	tell (ImageEndOfFileD, adr)
	DRMLSB_Exit:
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

exit:
	li $v0, 10
	syscall

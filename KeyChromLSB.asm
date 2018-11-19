# # # # # # # # # # # # # # # # # # 
#	Keyed Chromatic LSB	  #
#				  #
#				  #
# # # # # # # # # # # # # # # # # #

.text
EnKeyedChromLSB:
	
	push ($s0)					#make extra register space
	push ($s1)
	push ($ra)
	
	tell (KeyMessage, adr)				# ask for key
	malloc (8, imd)
	move $t0, $v0
	listen ($t0, reg, 8, imd)			# listen to key
	lw $t1, 0($t0)					#load first 4 characters
	lw $t0, 4($t0)					#load second 4 characters
	addu $t0, $t0, $t1				#sum values
	seedrand (0, imd, $t0, reg)			#seed id 0 rand to key
	
	lw $s5, 18($s2)					# gets the width of pixel map in pixels
	mul $s5, $s5, 3					# width of pixel map in bytes
	move $s6, $s5
	andi $t1, $s6, 0x00000003			# check if last 2 bits are not zero
	beqz $t1, EKCLSB_aligned			# this evalutates false if and only if the byte count is not divisible by 4
	andi $s6, $s6, 0xfffffffc		# so then generated an adjusted width add padding until
	addi $s6, $s6, 4				# it is divisible by 4
	EKCLSB_aligned:
	lw $s7, 22($s2)					# gets the height of pixel map in pixels
	slt $t0, $s7, $0
	beqz $t0, EKCLSB_posHeight
	not $s7, $s7
	addi $s7, $s7, 1
	EKCLSB_posHeight:
	#Sets up the pixel array so that we can work on it. Pads width, sets the height to be positive

	move $t5, $0					# ending flag
	move $t7, $0					# width index
	move $t8, $0					# height index
	#Sets t5, t7, and t8 to 0, all used for determining where we are in the pixel array
	
	EKCLSB_nextpix:
	randomIntRange (0, imd, 5, imd)
	bne $a0, $0, EKCLSB_skip1	# rand = 0 then
	li $a0, 0xE4			# rand = RGB, 11-10-01-00
	j EKCLSB_nextpix2
	EKCLSB_skip1:
	addi $a0, $a0, -1
	bne $a0, $0, EKCLSB_skip2	# rand = 1 then
	li $a0, 0xD2			# rand = RBG, 11-01-00-10
	j EKCLSB_nextpix2
	EKCLSB_skip2:
	addi $a0, $a0, -1
	bne $a0, $0, EKCLSB_skip3	# rand = 2 then
	li $a0, 0x9C			# rand = GRB, 10-01-11-00
	j EKCLSB_nextpix2
	EKCLSB_skip3:
	addi $a0, $a0, -1
	bne $a0, $0, EKCLSB_skip4	# rand = 3 then
	li $a0, 0x87			# rand = GBR, 10-00-01-11
	j EKCLSB_nextpix2
	EKCLSB_skip4:
	addi $a0, $a0, -1
	bne $a0, $0, EKCLSB_skip5	# rand = 4 then
	li $a0, 0x63			# rand = BRG, 01-10-00-11
	j EKCLSB_nextpix2
	EKCLSB_skip5:			# rand = 5 so
	li $a0, 0x4E			# rand = BGR, 01-00-11-10
	EKCLSB_nextpix2:
	mult $t8, $s6					# 
	mflo $t6					#
	addu $t6, $t6, $t7				#
	addu $t6, $t6, $s3				# base address of pixel to edit
	
	andi $a1, $a0, 0xC0
	sra $a1, $a1, 6
	addi $a1, $a1, -1
	beq $a1, $0, EKCLSB_Blue
	addi $a1, $a1, -1
	beq $a1, $0, EKCLSB_Green
	j EKCLSB_Red
	
	EKCLSB_Blue:
	jal EKCLSB_getnextbit
	lbu $t2, 2($t6)					#loads the byte that we are changing into t2
	andi $t2, $t2, 0xfe				# discard LSB
	or $t2, $t2, $t1				# replace with message
	sb $t2, 2($t6)					#stores the byte in question into t6
	#Determines where in the pixel array we are at, loads the byte we are at and edits that byte to contain our message data
	
	andi $a1, $a0, 0x03
	beq $a1, $0, EKCLSB_pixend
	addi $a1, $a1, -2
	beq $a1, $0, EKCLSB_Green
	j EKCLSB_Red
	

	EKCLSB_Green:
	jal EKCLSB_getnextbit
	lbu $t2, 1($t6)					#loads the byte that we are changing into t2
	andi $t2, $t2, 0xfe				# discard LSB
	or $t2, $t2, $t1				# replace with message
	sb $t2, 1($t6)					#stores the byte in question into t6
	#Determines where in the pixel array we are at, loads the byte we are at and edits that byte to contain our message data
	
	andi $a1, $a0, 0x0C
	sra $a1, $a1, 2
	beq $a1, $0, EKCLSB_pixend
	addi $a1, $a1, -1
	beq $a1, $0, EKCLSB_Blue
	j EKCLSB_Red
	
	
	EKCLSB_Red:
	jal EKCLSB_getnextbit
	lbu $t2, 0($t6)					#loads the byte that we are changing into t2
	andi $t2, $t2, 0xfe				# discard LSB
	or $t2, $t2, $t1				# replace with message
	sb $t2, 0($t6)					#stores the byte in question into t6
	#Determines where in the pixel array we are at, loads the byte we are at and edits that byte to contain our message data
	
	andi $a1, $a0, 0x30
	sra $a1, $a1, 4
	beq $a1, $0, EKCLSB_pixend
	addi $a1, $a1, -1
	beq $a1, $0, EKCLSB_Blue
	j EKCLSB_Green
	
	EKCLSB_pixend:
	add $t7, $t7, 3					# increment width index
	bne $t7, $s5, EKCLSB_wnRange		# check its still within range
	add $t8, $t8, 1					# if not increment height index
	beq $t8, $s7, EKCLSB_imageEnd	# check if height within range
	move $t7, $0					# reset width index
	#Determines if we are at the end of a line, if we are it resets the width index and moves us down a row. If we drop off the end of the pixel array we are out of image data

	EKCLSB_wnRange:
	j EKCLSB_nextpix					# loop to next pixel
	#Determines if we still have message data in our loaded byte, if we do not it loads a new byte and if we do it starts the message encode on the next bit

	EKCLSB_imageEnd:
	tell (ImageEndOfFileE, adr)
	EKCLSB_Exit:
	popr ($ra)
	popr ($s1)
	popr ($s0)
	
	j $ra

EKCLSB_getnextbit:
	bne $t9, 0 EKCLSB_bitsleft			# check if there are more bits left in the byte
	lbu $t0, 0($s4)					# if not, get next message byte
	bnez $t5, EKCLSB_Exit
	bnez $t0, EKCLSB_Cont			# check if message is fully encoded yet
	addi $t5, $t5, 1
	#Loads 8 bits (1 byte) of the message into t0. If this fails and t0 is set to 0, t5 is set to 1 and the loop will exit on the next iteration 
	EKCLSB_Cont:
	addi $s4, $s4, 1
	li $t9, 8						# message byte index, 8 bits left to encode
	#Moves the message pointer 1 byte forward because we loaded the byte already in the last loop, sets t9 to 8 (used to determine if we need to load another byte of message or not)
	EKCLSB_bitsleft:
	andi $t1, $t0, 1				# bit of message to append	
	addi $t9, $t9, -1				# decrement byte index
	srl $t0, $t0, 1
	j $ra




DeKeyedChromLSB:
	
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
	beqz $t1, DKCLSB_aligned			# this evalutates true if and only if the byte count is not divisible by 4
	andi $s6, $s6, 0xfffffffc		# so then generated an adjusted width add padding until
	addi $s6, $s6, 4				# it is divisible by 4
	DKCLSB_aligned:
	lw $s7, 22($s2)					# gets the height of pixel map in pixels
	slt $t0, $s7, $0
	beqz $t0, DKCLSB_posHeight
	not $s7, $s7
	addi $s7, $s7, 1
	DKCLSB_posHeight:
	#Sets up the pixel array so that we can work on it. Pads width, sets the height to be positive

	move $t5, $s4					# message index
	move $t7, $0					# width index
	move $t8, $0					# height index
	j DKCLSB_skipIn
	#Sets t5 to the message pointer

	DKCLSB_nextByte: 
	srl $t0, $t0, 1
	sb $t0, 0($t5)
	beqz $t0, DKCLSB_Exit
	add $t5, $t5, 1
	#shifts t0 to the left, stores t0 in t5 (the message), if t0 = 0, were done

	DKCLSB_skipIn:
	move $t0, $0					# reset message byte
	li $t9, 8						# message byte index, 8 bits left to decode
	#t0 = 0, bits we need to read = 8

	DKCLSB_nextBit:
	mul $t6, $t8, $s6				# 
	addu $t6, $t6, $t7				#
	addu $t6, $t6, $s3				# address of next channel to read
	lbu $t1, 0($t6)					#loads a byte from t6 into t1
	andi $t1, $t1, 1				# discard everything but LSB
	sll $t1, $t1, 8					#shift t1 left 8 bits
	add $t0, $t0, $t1				# append LSB
	
	#checkBounds
	add $t7, $t7, 1					# increment width index
	bne $t7, $s5, DKCLSB_wnRange		# check its still within range
	add $t8, $t8, 1					# if not increment height index
	beq $t8, $s7, DKCLSB_imageEnd	# check if height within range
	li $t7, 0						# reset width index
	#Checking bounds, resets width and increases height when needed, if we drop off the image we end

	DKCLSB_wnRange:
	addi $t9, $t9, -1				# decrement byte index
	beqz $t9, DKCLSB_nextByte		# if 0 then get next byte else
	srl $t0, $t0, 1
	j DKCLSB_nextBit					# get next bit
	#if we have bits left to decode get the next bit, otherwise get the next byte 

	DKCLSB_imageEnd:
	tell (ImageEndOfFileD, adr)
	DKCLSB_Exit:
	j $ra
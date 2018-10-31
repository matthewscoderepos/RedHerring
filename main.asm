##############################
#      Red Herring           #
#                            #
#      Matthew Sutton        #
#       Calvin Crino         #
#        James Bors          #
#                            #
##############################
#$S0 holds input file location
#$S1 holds new file name. 
#$S2 holds original picture data

.include "Macros.asm"

.data
 keyQuestion: .asciiz "What is the key? "
 methodQuestion: .asciiz "What encoding method would you like to use? "
 rbgQuestion: .asciiz "Red, Green, or Blue? "
 fileLocation: .asciiz "Where is the picture located? "
 showFileLocation: .asciiz "You entered this file location:\n"
 hiddenMessage: .asciiz "Please provide the message to be hidden in the picture: "
 newFileName: .asciiz "Please provide a name for the new picture: "
 finString: .space 100
 foutString: .space 100
 
.text
main:

userInputFileLocation:
	# $s0 holds file location

	tell (fileLocation, adr) 	#Ask user string
	
	la $s0, finString		#pointing s0 to finstring
	listen ($s0, reg, 100, imd)	#reading user input
	
	
	#Full disclosure, I got this loop from StackOverflow. We need to strip the newline chars that are added to inputs and this does the job.
	xor $a2, $a2, $a2
	loop:
	lbu $a3, finString($a2)  
	addiu $a2, $a2, 1
	bnez $a3, loop      	  # Search the NULL char code
   	beq $a1, $a2, skip   	  # Check whether the buffer was fully loaded
	subiu $a2, $a2, 2   	  # Otherwise 'remove' the last character
	sb $0, finString($a2)     # and put a NULL instead
	skip:

readPicture:
	# $s2 holds old picture data
	#open file 
	openf ($s0, reg, READ)
	move $s2, $v0
	
	#allocate 56 bytes (header min size 54, padded by 2 for word align)
	malloc (56, imd)
	move $s3, $v0	# save allocated memory pointer
	addi $s3, $s3, 2	# ignore padding bytes

	
	#read from file
	readf ($s2, reg, $s3, reg, 54, imd)
	
	#input validation
	lhu $t1, 0($s3)				# load a half
	li $t0,	0x00004d42			# load hex value of BM, remember edianess 
	bne $t1, $t0, exit
	
	lhu $t0, 28($s3)			# check for color depth 24
	li $t1, 24
	bne $t1, $t0, exit			# if not, abort
	
	#calculate pixel map size
	lw $t0, 2($s3) 				#load bytes in file
	lw $t1, 10($s3)				#load bytes to pixel map
	sub $s6, $t0, $t1			# bytes in file - bytes to map = bytes in map
	
	# allocate space for map load
	malloc ($s6, reg)
	move $s7, $v0
	
	#read from file
	readf ($s2, reg, $s7, reg, $s6, reg)	#pixel map now in memory
	
	# Close the file 
	closef ($s2, reg)
	
	# at this point we'll need the message to start encoding
	
	
userInputNewFileName:
	# $s1 holds new file name
	
	tell (newFileName, adr)
	
	la $s1, foutString
	listen ($s1, reg, 100, imd)
	
	#Full disclosure, I got this loop from StackOverflow. We need to strip the newline chars that are added to inputs and this does the job.
	xor $a2, $a2, $a2
	loop2:
	lbu $a3, foutString($a2)  
   	addiu $a2, $a2, 1
   	bnez $a3, loop2		# Search the NULL char code
   	beq $a1, $a2, skip2   	# Check whether the buffer was fully loaded
   	subiu $a2, $a2, 2   	# Otherwise 'remove' the last character
   	sb $0, foutString($a2)  # and put a NULL instead
	skip2:

	
openNewFile:
	#opens a new file with name given by user for writing
	openf (foutString, adr, WRITE)
	move $s2, $v0
	
	#begin writing from pictureBuffer
	writef ($s2, reg, $s3, reg, 54, imd)		#copy forward header
	writef ($s2, reg, $s7, reg, $s6, reg)		#copy in edited pixel map
	closef ($s2, reg)
	
exit:
	li $v0, 10
	syscall


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


###### WE WILL NEED TO LOAD THE HEADER SEPERATELY TO GATHER ITS INFO. THE PICTURE LOADING AND COPYING WAS A LOT HARDER THAN I THOUGHT. #########


.data
 keyQuestion: .asciiz "What is the key? "
 methodQuestion: .asciiz "What encoding method would you like to use? "
 rbgQuestion: .asciiz "Red, Green, or Blue? "
 fileLocation: .asciiz "Where is the picture located? "
 showFileLocation: .asciiz "You entered this file location:\n"
 hiddenMessage: .asciiz "Please provide the message to be hidden in the picture: "
 newFileName: .asciiz "Please provide a name for the new picture: "
 finString: .ascii "                                                                                                     "
 foutString: .ascii "                                                                                                     "
 pictureBuffer: .space 150000
 
.text
main:

userInputFileLocation:
	# $s0 holds file location

	li $v0, 4
	la $a0, fileLocation 	#Ask user string
	syscall
	
	li $v0, 8 		#User input of picture location
	la $a0, finString
	li $a1, 100 		#hardcoded max size of string
	move $s0, $a0 		#Moving file location into s0
	syscall
	
	
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
	li   $v0, 13       	 # system call for open file
	la   $a0, finString      # board file name
	li   $a1, 0       	 # Open for reading
	li   $a2, 0
	syscall           	 # open a file (file descriptor returned in $v0)
	move $s2, $v0     	 # save the file descriptor 

	#read from file
	li   $v0, 14     	 # system call for read from file
	move $a0, $s2     	 # file descriptor 
	la   $a1, pictureBuffer  # address of buffer to which to read
	li   $a2, 150000    	 #hardcoded, I belive that the size of the picture is in the header somewhere, so if we pull that out we can not hardcode here.
	syscall            	 # read from file

	# Close the file 
	li   $v0, 16      	 # system call for close file
	move $a0, $s2     	 # file descriptor to close
	syscall            	 # close file	


userInputNewFileName:
	# $s1 holds new file name
	
	li $v0, 4
	la $a0, newFileName 	#Ask user string
	syscall
	
	li $v0, 8		#User input of new name
	la $a0, foutString
	li $a1, 100		#hardcoded max size of string
	move $s1, $a0		#moving new name into s1
	syscall
	
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
	li $v0, 13
	la $a0, foutString
	li $a1, 1
	syscall
	move $s2, $v0
	#begin writing from pictureBuffer
	li $v0, 15
	move $a0, $s2
	la $a1, pictureBuffer
	li $a2, 150000 		#hardcoded, I belive that the size of the picture is in the header somewhere, so if we pull that out we can not hardcode here.
	syscall
	
	li $v0, 16
	move $a0, $s2
	syscall
	
exit:
	li $v0, 10
	syscall


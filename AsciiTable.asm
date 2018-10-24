# # # # # # # # # # # # # #
# Test Implementation of  #
# an ascii look up table  #
#  for use in RGBHerring  #
# # # # # # # # # # # # # #

.include "Macros.asm"

.data		     # each line 16 characters , for actual implementation each value A
		     # would be replaced by the ascii character with the desired binary value
asciiToEncode: 	.ascii "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
		.ascii "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
		.ascii " \0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
		.ascii "0123456789\0\0\0\0\0\0"
		.ascii "\0ABCDEFGHIJKLMNO"
		.ascii "PQRSTUVWXYZ\0\0\0\0\0"
		.ascii "\0ABCDEFGHIJKLMNO"
		.ascii "PQRSTUVWXYZ\0\0\0\0\0"
testString: .ascii "this is a test string 123" #25 chars long


.text

la $s0, asciiToEncode		# load in map start
la $s1, testString		# load in text start
addi $s2, $s1, 25		# get end condition
loop: 
beq $s1, $s2, exit		# if text pointer = end exit
lb $t0, 0($s1)			# load value at text
add $t0, $t0, $s0		# get location in map
lb $t0, 0($t0)			# load value at map
char ($t0, reg)			# output character
addi $s1, $s1, 1		# inc text pointer
j loop				# loop
exit:
li $v0, 10
syscall
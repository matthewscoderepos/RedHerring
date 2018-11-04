# # # # # # # # # # # # # # # # # #
#  Macros for use in RGB herring  #
# # # # # # # # # # # # # # # # # #
#
# Macros for syscalls take the general form
# name_of_syscall (value_a0, type_a0, value_a1, type_a1, . . .)
#	type is either reg (register), imd (immediate), or adr (address)
#	value is a source, can be a register, immediate, or address. must agree with type
#
#	ex. calling tell on address string, 
#	tell (string, adr)
#
#	use .include "Macros.asm" to import in code

.macro reg (%dest, %reg)
move %dest, %reg
.end_macro

.macro imd (%dest, %imd)
li %dest, %imd
.end_macro

.macro adr (%dest, %adr)
la %dest, %adr
.end_macro

.macro tell (%str_s, %form)
li $v0, 4
%form ($a0, %str_s)
syscall
.end_macro

.macro listen (%fin, %form1, %length, %form2)
li $v0, 8
%form1 ($a0, %fin)
%form2 ($a1, %length)
syscall
.end_macro

.macro readc ()
li $v0, 12
syscall
.end_macro

.macro char (%char, %form)
li $v0, 11
%form ($a0, %char)
syscall
.end_macro

.macro int (%int, %form)
li $v0, 1
%form ($a0, %int)
syscall
.end_macro

.macro uint (%uint, %form)
li $v0, 36
%form ($a0, %uint)
syscall
.end_macro

.macro malloc (%size, %form)
li $v0, 9
%form ($a0, %size)
syscall
.end_macro

.eqv	READ 0
.eqv   WRITE 1
.macro openf (%filename, %form, %flag)
li $v0, 13
%form ($a0, %filename)
li $a1, %flag
li $a2, 0
syscall
.end_macro

.macro readf (%fileptr, %form1, %bufferptr, %form2, %readcnt, %form3)
li $v0, 14
%form1 ($a0, %fileptr)
%form2 ($a1, %bufferptr)
%form3 ($a2, %readcnt)
syscall
.end_macro

.macro writef (%fileptr, %form1, %bufferptr, %form2, %writecnt, %form3)
li $v0, 15
%form1 ($a0, %fileptr)
%form2 ($a1, %bufferptr)
%form3 ($a2, %writecnt)
syscall
.end_macro

.macro closef (%fileptr, %form1)
li $v0, 16
%form1 ($a0, %fileptr)
syscall
.end_macro

.macro seedrand (%randid, %form1, %randseed, %form2)
li $v0, 40
%form1 ($a0, %randid)
%form2 ($a1, %randseed)
syscall
.end_macro

.macro randomIntRange (%randid, %form1, %upperbound, %form2)
li $v0, 42
%form1 ($a0, %randid)
%form2 ($a1, %upperbound)
syscall
.end_macro








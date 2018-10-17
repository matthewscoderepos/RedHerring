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



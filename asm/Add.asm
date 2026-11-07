; Adds 15 and 26 in registers, then exits through MS-DOS.
.model tiny			;smallest memory model for the program
.stack 30			;program stack = 30 bytes
.code				;start of the code segment
Start:

	mov ax, 15		; AX register contents = 15

	mov dx, 26		; DX register contents = 26

	add ax, dx		; add AX and DX, storing the result in AX (the first operand)

	mov ax, 4c00h		;load the program termination function into AX

	int 21h			;now exit the program by calling interrupt 21h

End Start
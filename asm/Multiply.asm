; Multiplies 15 by 320 using shifts and additions, then exits through MS-DOS.
.model tiny			;smallest memory model for the program
.stack 30			;program stack = 30 bytes
.code				;start of the code segment
Start:

	mov ax, 15		; AX register = 15

	xor di, di		; DI register = 0

	shl ax, 6		; shift left by 6
				; that is, multiply by 2^6, or 64
				; AX is now 15 * 64 = 960

	add di, ax		; DI register = DI + AX = 0 + 960 = 960

	shl ax, 2		; shift left by 2
				; that is, multiply AX by 4 (since 2^2 = 4)
				; AX is now 960 * 4 = 3840

	add di, ax		; DI register = DI + AX = 960 + 3840 = 4800
				; this is equivalent to multiplying
				; 15 * 320
				; because 64 + 4 * (64) = 64 + 256 = 320
				; every natural number can be expressed as
				; a sum of powers of two

	mov ax, 4c00h		;load the program termination function into AX

	int 21h			;now exit the program by calling interrupt 21h

End Start
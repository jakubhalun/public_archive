; Displays the first 256 bytes of the program environment using MS-DOS services.
;***http://halun.pl/***

.model tiny
.code
	org 100h
Start:
	mov ah, 62h		;function 62h...
	int 21h			;...of interrupt 21h: get the PSP address
	mov es, bx		;load the PSP address into ES

	mov bx, es:[2Ch]	;load PSP field 2Ch (the environment address) into BX
	mov es, bx		;load the environment address into ES

	mov cx, 256
	xor si, si
	mov ah, 02h
DisplayBytes:
	mov dl, es:[si]		;display the environment contents character by character
	int 21h
	inc si
	loop DisplayBytes 

	mov ax, 4c00h		;exit the program
	int 21h
End Start

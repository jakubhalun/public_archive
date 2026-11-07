; Displays a text file on the screen using MS-DOS services.
;***http://halun.pl/***
.model tiny

.stack 64

.data
	Message1 db 'Program wyswietla zawartosc plikow tekstowych',13,10,'$'
	Message2 db 13,10,'Napisz [dysk:][sciezka]nazwapliku',13,10,'$'
	CommandLineLength db ?			;command line length
	FileName db 15 dup (?)
	FileHandle dw ?
	Error2 db 'Nie znaleziono pliku',13,10,'$'
	Error3 db 'Nie znaleziono sciezki',13,10,'$'
	Error4 db 'Zbyt wiele otwartych plikow',13,10,'$'
	Error5 db 'Dostep niemozliwy',13,10,'$'
	IOBuffer db 256 dup (?)

.code

NoParameters PROC
	mov ah, 09h
	lea dx, Message1
	int 21h
	lea dx, Message2
	int 21h
	ret
ENDP


FileOpenError PROC
	cmp ax, 2
	je OpenError2
	cmp ax, 3
	je OpenError3
	cmp ax, 4
	je OpenError4
	cmp ax, 5
	je OpenError5
OpenError2:	lea dx, Error2
	jmp DisplayMessage
OpenError3:	lea dx, Error3
	jmp DisplayMessage
OpenError4:	lea dx, Error4
	jmp DisplayMessage
OpenError5:	lea dx, Error5
	jmp DisplayMessage
DisplayMessage:
	mov ah, 09h
	int 21h
	jmp ExitProgram
ENDP


CheckParameter PROC
	mov ah, 62h			;find the PSP address
	int 21h
	mov es, bx			;load the PSP address into ES
	mov bl,ES:[80h]
	cmp bl, 0			;check whether parameters are present
	jne ParametersPresent
	call NoParameters
	jmp ExitProgram			;exit if there are no parameters
ParametersPresent:
	mov CommandLineLength, bl
	ret
ENDP


LoadFileName PROC
	mov bx, 81h			;load the command line offset
	mov si, bx			;...into SI
	mov cl, CommandLineLength		;load the command line length
	lea di, FileName		;load the offset of the FileName array
CopyLoop1:
	mov al, es:[si]
	cmp al, 20h
	je SpaceFound
	mov ds:[di], al
	inc di
SpaceFound:	dec cx
	inc si
	jcxz EndCopyLoop1
	jmp CopyLoop1
EndCopyLoop1:
	mov ah, 0			;append a zero byte to the string
	mov ds:[di], ah
	xor si, si
	xor di, di
	ret
ENDP


OpenFile PROC
	lea dx, FileName
	mov ax, 3d00h
	int 21h
	jnb NoError
	call FileOpenError
NoError:
	mov FileHandle, ax
	ret
ENDP


FileToScreen PROC
ReadFileLoop:
	lea dx, IOBuffer
	mov bx, FileHandle		;load the file handle
	mov ah, 3fh		;read from the file
	mov cx,	256		;load the number of bytes to read
	int 21h
	cmp ax, 0
	je EndReadFileLoop
	mov cx, ax
	call PrintBuffer
	jmp ReadFileLoop
EndReadFileLoop:
	ret
ENDP


PrintBuffer PROC
	xor si, si
ScreenLoop:
	mov dl, IOBuffer[si]
	mov ah, 02h		;print a character
	int 21h
	inc si
	dec cx
	jcxz EndScreenLoop
	jmp ScreenLoop
EndScreenLoop:
	xor si, si
	ret
ENDP


CloseFile PROC
	mov ah, 3Eh
	mov bx, FileHandle
	int 21h
	ret
ENDP


Start:					;program entry point
	mov ax, @data
	mov ds, ax
	call CheckParameter
	call LoadFileName
	call OpenFile
	call FileToScreen
CloseBeforeExit:
	call CloseFile
ExitProgram:	mov ax, 4c00h			;exit the program
	int 21h


End Start

; Unfinished program intended to reverse file contents using MS-DOS services.
; The data-reading routine is empty in this archived version.
;***http://halun.pl/***
.model small
.stack 128
.386
.data
	InputFileName db 15 dup (?)
	OutputFileName db 15 dup (?)
	InputFileHandle dw ?
	OutputFileHandle dw ?
	Buffer db 256 dup (?)
	Character db ?
	CommandLineLength db ?
	DataLength dw 0
	FilePositionHigh dw 0
	FilePositionLow dw 0
	Message1 db 'Program sluzy do odwracania zawartosci plikow tekstowych',13,10,13,10,'$'
	Message2 db 'Wywolanie:    ODWROC  plik1 plik2',13,10,13,10,'$'
	Message3 db 'plik1 - plik do odczytu',13,10,'$'
	Message4 db 'plik2 - plik w ktorym odwrocona zawartosc pierwszego bedzie zapisana',13,10,'$'
	Message5 db 'BLAD: NIEPRAWIDLOWE PARAMETRY',13,10,13,10,'$'
	Message6 db 'BLAD: NIE MOZNA OTWORZYC PLIKU DO ODCZYTU',13,10,'$'
	Message7 db 'BLAD: NIE MOZNA UTWORZYC PLIKU DO ZAPISU',13,10,'$'
.code
ShowHelp PROC
	mov ah, 09h
	lea dx, Message1
	int 21h
	lea dx, Message2
	int 21h
	lea dx, Message3
	int 21h
	lea dx, Message4
	int 21h
	jmp ExitProgram
ENDP

CheckParameters PROC
	mov ah, 62h			;get the PSP address
	int 21h
	mov es, bx			;and save it in ES
	xor ax, ax
	mov al, es:[80h]
	cmp al, 2
	jna NoParameters		;if the input line is no longer than 2 characters
	mov cx, ax
	ret
NoParameters:
	call ShowHelp
	jmp ExitProgram
ENDP

GetParameters PROC
	mov si, 81h
	xor di, di
ParameterLoop1:
	mov al, es:[si]
	cmp al, 20h
	jne ParameterLoop2		;continue if the character is not a space
	inc si
	dec cx
	jz ParameterError		;finish if this is the end of the input line
	jmp ParameterLoop1
ParameterLoop2:
	mov al, es:[si]
	cmp al, 20h
	je ParameterLoop3		;stop reading the first name at a space
	mov InputFileName[di], al
	mov InputFileName[di+1], 0
	inc si
	inc di
	dec cx
	jz ParameterError
	jmp ParameterLoop2
ParameterLoop3:
	xor di, di
	mov al, es:[si]
	cmp al, 20h
	jne ParameterLoop4		;continue if the character is not a space
	inc si
	dec cx
	jz ParameterError		;finish if this is the end of the input line
	jmp ParameterLoop3
ParameterLoop4:
	mov al, es:[si]
	cmp al, 20h
	je EndParameterLoop		;stop reading the second name at a space
	mov OutputFileName[di], al
	mov OutputFileName[di+1], 0
	inc si
	inc di
	dec cx
	jz EndParameterLoop
	jmp ParameterLoop4
EndParameterLoop:
	xor si, si
	xor di, di
	ret
ParameterError:
	lea dx, Message5
	mov ah, 09h
	int 21h
	call ShowHelp
ENDP

OpenInputFile PROC
	mov ax, 3d00h
	lea dx, InputFileName
	int 21h
	jc InputFileError
	mov InputFileHandle, ax
	ret
InputFileError:
	lea dx, Message6
	mov ah, 09h
	int 21h
	jmp ExitProgram
ENDP

OpenOutputFile PROC
	mov ah, 5bh
	lea dx, OutputFileName
	xor cx, cx
	int 21h
	jc OutputFileError
	mov OutputFileHandle, ax
	ret
OutputFileError:
	lea dx, Message7
	mov ah, 09h
	int 21h
	jmp ExitProgram
ENDP

ReadData PROC

	ret
ENDP

WriteData PROC
	cmp DataLength, 0
	je EndWriteLoop
	mov cx, DataLength
	mov si, cx
WriteLoop:
	push cx
	mov bx, OutputFileHandle
	mov ah, 40h
	mov cx, 1
	mov al, Buffer[si]
	cmp al, 13
	je CarriageReturn
	cmp al, 10
	je LineFeed
	mov Character, al
	jmp WriteCharacter
CarriageReturn:
	mov Character, 10
	jmp WriteCharacter
LineFeed:
	mov Character, 13
WriteCharacter:
	lea dx, Character
	int 21h
	pop cx
	dec si
	dec cx
	jz EndWriteLoop
	jmp WriteLoop
EndWriteLoop:
	ret
ENDP

FileToFile PROC
	mov bx, InputFileHandle
	mov ax, 4202h
	xor cx, cx
	xor dx, dx
	int 21h
	mov FilePositionHigh, dx
	mov FilePositionLow, ax
FileToFileLoop:
	call ReadData
	call WriteData
	cmp DataLength, 0
	je EndFileToFile
	jmp FileToFileLoop	
EndFileToFile:
	ret
ENDP

CloseFiles PROC
	mov ah, 3eh
	mov bx, InputFileHandle
	int 21h
	mov ah, 3eh
	mov bx, OutputFileHandle
	int 21h
	ret
ENDP

Start:
	mov ax, @data
	mov ds, ax
	call CheckParameters
	call GetParameters
	call OpenInputFile
	call OpenOutputFile
	call FileToFile
ExitProgram:
	call CloseFiles
	mov ax, 4c00h
	int 21h
End Start
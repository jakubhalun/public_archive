; Identifies COM/EXE files and displays EXE header information using MS-DOS services.
; Includes optional Windows header checks and logging to a file.
;********************************************************************
;*     ExeInfo                                                      *
;*     Copyright (C) 2001 Jakub Halun				    *
;*     http://jhal.republika.pl					    *
;********************************************************************
.model small
jumps
.stack 64
.code
Start:
	mov ax, @data
	mov ds, ax
	call CheckParameters
	call OpenFiles
	call CheckFile
ExitProgram:
	call CloseFiles
	mov ax, 4c00h
	int 21h

ShowHelp PROC
	mov ah, 9h
	lea dx, Message0
	int 21h
	lea dx, Message1
	int 21h
	lea dx, Message2
	int 21h
	lea dx, Message3
	int 21h
	lea dx, Message5
	int 21h
	jmp ExitProgram
	ret
ENDP

CheckParameters PROC
	xor di, di
	xor si, si
	mov ah, 62h
	int 21h
	mov es, bx
	cmp byte ptr es:[80h], 2
	jb Help
	xor cx, cx
	mov cl, es:[80h]
ScanParameters:
	inc si
	cmp si, cx
	ja EndParameterCheck
	cmp byte ptr es:[si+80h], ' '
	je ScanParameters
	cmp byte ptr es:[si+80h], '/'
	je ParseOption
	mov al, es:[si+80h]
	mov InputFileName[di], al
	inc di
	jmp ScanParameters
ParseOption:
	xor di, di
	cmp InputFileName[0], 0
	je Help
	inc si
	cmp si, cx
	ja Help
	cmp byte ptr es:[si+80h], 'w'
	je EnableWindowsCheck
	cmp byte ptr es:[si+80h], 'W'
	je EnableWindowsCheck
	cmp byte ptr es:[si+80h], 'l'
	je EnableLogging
	cmp byte ptr es:[si+80h], 'L'
	je EnableLogging
	jmp ScanParameters
EnableWindowsCheck:
	mov WindowsCheckEnabled, 1
	jmp ScanParameters
EnableLogging:
	mov LoggingEnabled, 1
	inc si
	cmp si, cx
	ja Help
	cmp byte ptr es:[si+80h], ':'
	jne Help
	inc si
	cmp si, cx
	ja Help
	cmp byte ptr es:[si+80h], ' '
	je Help
	cmp byte ptr es:[si+80h], '/'
	je Help
LogNameLoop:
	mov al, es:[si+80h]
	cmp al, ' '
	je EndLogNameLoop
	cmp al, '/'
	je EndLogNameLoop
	mov OutputFileName[di], al
	inc di
	inc si
	cmp si, cx
	ja EndParameterCheck
	jmp LogNameLoop
EndLogNameLoop:
	xor di, di
	jmp ScanParameters
Help:
	call ShowHelp
EndParameterCheck:
	xor di, di
	xor si, si
	cmp InputFileName[0], 0
	je Help
	ret
ENDP

OpenFiles PROC
	lea dx, InputFileName
	mov ax, 3d00h		;open the file
	int 21h
	jc InputFileError
	mov FileHandle, ax
	xor si, si
CheckNameLength:
	cmp InputFileName[si], 0
	je EndNameLengthCheck
	inc si
	jmp CheckNameLength
EndNameLengthCheck:
	inc si
	inc si
	mov FileNameLength, si
	mov InputFileName[si-2], 13
	mov InputFileName[si-1], 10
	mov InputFileName[si], '$'
	xor si, si
	cmp LoggingEnabled, 1		;check whether to create a log file
	je CreateLogFile
ReturnFromOpen:
	ret
CreateLogFile:
	mov ax, 5b00h		;create a new file
	lea dx, OutputFileName
	xor cx, cx
	int 21h
	jc OutputFileError
	mov OutputFileHandle, ax
	jmp ReturnFromOpen
InputFileError:
	cmp ax, 2
	je InputError2
	cmp ax, 3
	je InputError3
	cmp ax, 4
	je InputError4
	cmp ax, 5
	je InputError5
OutputFileError:
	cmp ax, 2
	je OutputError2
	cmp ax, 3
	je OutputError3
	cmp ax, 4
	je OutputError4
	cmp ax, 5
	je OutputError5
	cmp ax, 80
	je OutputError80
InputError2:
	mov ah, 09h
	lea dx, Error0
	int 21h
	lea dx, Error2
	int 21h
	jmp ExitProgram
InputError3:
	mov ah, 09h
	lea dx, Error0
	int 21h
	lea dx, Error3
	int 21h
	jmp ExitProgram
InputError4:
	mov ah, 09h
	lea dx, Error0
	int 21h
	lea dx, Error4
	int 21h
	jmp ExitProgram
InputError5:
	mov ah, 09h
	lea dx, Error0
	int 21h
	lea dx, Error5
	int 21h
	jmp ExitProgram
OutputError2:
	mov ah, 09h
	lea dx, Error00
	int 21h
	lea dx, Error2
	int 21h
	jmp ExitProgram
OutputError3:
	mov ah, 09h
	lea dx, Error00
	int 21h
	lea dx, Error3
	int 21h
	jmp ExitProgram
OutputError4:
	mov ah, 09h
	lea dx, Error00
	int 21h
	lea dx, Error4
	int 21h
	jmp ExitProgram
OutputError5:
	mov ah, 09h
	lea dx, Error00
	int 21h
	lea dx, Error5
	int 21h
	jmp ExitProgram
OutputError80:
	mov ah, 09h
	lea dx, Error0
	int 21h
	lea dx, Error80	
	int 21h
ReadCharacter:
	mov ah, 07h		;read a character
	int 21h
	cmp al, 116
	je Overwrite
	cmp al, 110
	je DoNotOverwrite
	jmp ReadCharacter
Overwrite:
	mov ah, 3ch		;create a file, overwriting the old one
	lea dx, OutputFileName
	int 21h
	jc OutputFileError
	mov OutputFileHandle, ax
	jmp ReturnFromOpen
DoNotOverwrite:
	mov ah, 09h
	lea dx, Message80
	int 21h
	mov ah, 0ah		;read a line from the keyboard
	mov OutputFileName[0], 128	;maximum string length
	lea dx, OutputFileName
	int 21h
	xor ax, ax
	mov al, OutputFileName[1]
	mov di, ax		;length of the string read
	mov OutputFileName[di+2], 0
	xor di, di
	lea dx, OutputFileName + 2
	mov ax, 5b00h		;create a new file
	xor cx, cx
	int 21h
	jc OutputFileError
	mov OutputFileHandle, ax
	jmp ReturnFromOpen
ENDP

WriteString MACRO StringLength, StringAddress
	mov bx, OutputFileHandle
	mov ah, 40h
	mov cx, StringLength
	lea dx, StringAddress
	int 21h
	jc WriteError
ENDM

ReadAndPrintData MACRO Address
	mov si, Address
	call ReadData
	mov ah, 09h
	lea dx, HexText
	int 21h
ENDM

H2D MACRO
	call Hex2Dec
	mov ah, 09h
	lea dx, DecimalText
	int 21h
ENDM

CheckFile PROC
	xor di, di
	mov ah, 3fh
	mov bx, FileHandle
	mov cx, 256
	lea dx, Buffer
	int 21h
	cmp Buffer[0], 0e9h	;COM file
	je COMFile
	cmp Buffer[0], 0ebh
	je COMFile
	cmp Buffer[0], 0b8h
	je COMFile
	cmp Buffer[0], 0bbh
	je COMFile
	cmp Buffer[0], 'M'
	jne UnknownFormat		;unknown file format
	cmp Buffer[1], 'Z'
	jne UnknownFormat	
	mov ah, 09h
	lea dx, Message9
	int 21h
	lea dx, InputFileName
	int 21h
	lea dx, MessageA
	int 21h
	lea dx, Message7
	int 21h
	cmp LoggingEnabled, 1
	je WriteEXE1
	jmp SkipEXE1
WriteEXE1:
	WriteString 13, Message9
	WriteString FileNameLength, InputFileName
	WriteString 8, MessageA
	WriteString 21, Message7
SkipEXE1:
	mov ah, 09h
	lea dx, HeaderMessage1
	int 21h
	ReadAndPrintData 2
	H2D
	cmp LoggingEnabled, 1
	je WriteEXE2
	jmp SkipEXE2
WriteEXE2:
	WriteString 26, HeaderMessage1
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXE2:
	mov ah, 09h
	lea dx, HeaderMessage2
	int 21h
	ReadAndPrintData 4
	H2D
	cmp LoggingEnabled, 1
	je WriteEXE3
	jmp SkipEXE3
WriteEXE3:
	WriteString 56, HeaderMessage2
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXE3:
	mov ah, 09h
	lea dx, HeaderMessage3
	int 21h
	ReadAndPrintData 6
	H2D
	cmp LoggingEnabled, 1
	je WriteEXE4
	jmp SkipEXE4
WriteEXE4:
	WriteString 42, HeaderMessage3
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXE4:
	mov ah, 09h
	lea dx, HeaderMessage4
	int 21h
	ReadAndPrintData 8
	H2D
	cmp LoggingEnabled, 1
	je WriteEXE5
	jmp SkipEXE5
WriteEXE5:
	WriteString 32, HeaderMessage4
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXE5:
	mov ah, 09h
	lea dx, HeaderMessage5
	int 21h
	ReadAndPrintData 10
	H2D
	cmp LoggingEnabled, 1
	je WriteEXE6
	jmp SkipEXE6
WriteEXE6:
	WriteString 58, HeaderMessage5
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXE6:
	mov ah, 09h
	lea dx, HeaderMessage6
	int 21h
	ReadAndPrintData 12
	H2D
	cmp LoggingEnabled, 1
	je WriteEXE7
	jmp SkipEXE7
WriteEXE7:
	WriteString 59, HeaderMessage6
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXE7:
	mov ah, 09h
	lea dx, HeaderMessage7
	int 21h
	ReadAndPrintData 14
	H2D
	cmp LoggingEnabled, 1
	je WriteEXE8
	jmp SkipEXE8
WriteEXE8:
	WriteString 26, HeaderMessage7
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXE8:
	mov ah, 09h
	lea dx, HeaderMessage8
	int 21h
	ReadAndPrintData 16
	H2D
	cmp LoggingEnabled, 1
	je WriteEXE9
	jmp SkipEXE9
WriteEXE9:
	WriteString 41, HeaderMessage8
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXE9:
	mov ah, 09h
	lea dx, HeaderMessage9
	int 21h
	ReadAndPrintData 18
	H2D
	cmp LoggingEnabled, 1
	je WriteEXEA
	jmp SkipEXEA
WriteEXEA:
	WriteString 22, HeaderMessage9
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXEA:
	mov ah, 09h
	lea dx, HeaderMessageA
	int 21h
	ReadAndPrintData 20
	H2D
	cmp LoggingEnabled, 1
	je WriteEXEB
	jmp SkipEXEB
WriteEXEB:
	WriteString 41, HeaderMessageA
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXEB:
	mov ah, 09h
	lea dx, HeaderMessageB
	int 21h
	ReadAndPrintData 22
	H2D
	cmp LoggingEnabled, 1
	je WriteEXEC
	jmp SkipEXEC
WriteEXEC:
	WriteString 26, HeaderMessageB
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXEC:
	mov ah, 09h
	lea dx, HeaderMessageC
	int 21h
	ReadAndPrintData 24
	H2D
	cmp LoggingEnabled, 1
	je WriteEXED
	jmp SkipEXED
WriteEXED:
	WriteString 32, HeaderMessageC
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXED:
	mov ah, 09h
	lea dx, HeaderMessageD
	int 21h
	ReadAndPrintData 26
	H2D
	cmp LoggingEnabled, 1
	je WriteEXEE
	jmp SkipEXEE
WriteEXEE:
	WriteString 16, HeaderMessageD
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipEXEE:
	cmp WindowsCheckEnabled, 1
	je CheckWindows
	jmp EndWindowsCheck
CheckWindows:
	cmp Buffer[3ch], 0
	je NoWindows
	xor ax, ax
	mov al, Buffer[3ch]	;get the Windows program header offset
	mov si, ax
	cmp Buffer[si], 'P'
	jne NoPE
	cmp Buffer[si+1], 'E'
	jne NoPE
	jmp WindowsFound
NoPE:
	cmp Buffer[si], 'N'
	jne NoWindows
	cmp Buffer[si+1], 'E'
	jne NoWindows
	mov ah, 09h
	lea dx, HeaderMessageE
	int 21h
	lea dx, HeaderMessageJ
	int 21h
	mov si, 3ch
	call ReadData
	call Hex2Dec
	mov ah, 09h
	lea dx, HexText
	int 21h
	lea dx, DecimalText
	int 21h
	cmp LoggingEnabled, 1
	je WriteNEInfo
	jmp EndWindowsCheck
WriteNEInfo:
	WriteString 41, HeaderMessageE
	WriteString 34, HeaderMessageJ
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
	jmp EndWindowsCheck
WindowsFound:
	lea dx, HeaderMessageE
	mov ah, 09h
	int 21h
	lea dx, HeaderMessageJ
	int 21h
	mov si, 3ch
	call ReadData
	mov FileNameLength, bx	;save the header address
	call Hex2Dec
	mov si, bx
	mov ah, 09h
	lea dx, HexText
	int 21h
	lea dx, DecimalText
	int 21h
	cmp LoggingEnabled, 0
	je SkipWindowsLog
	WriteString 41, HeaderMessageE
	WriteString 34, HeaderMessageJ
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
SkipWindowsLog:
	mov si, FileNameLength
	add si, 4
	mov FileNameLength, si	;save the value of SI
	call ReadData
	mov ah, 09h
	cmp bx, 0h
	je PUnknown
	cmp bx, 14Ch
	je CPU386
	cmp bx, 14Dh
	je CPU486
	cmp bx, 14Eh
	je CPU586
	cmp bx, 162h
	je PMark1
	cmp bx, 163h
	je PMark2
	cmp bx, 166h
	je PMark3
	jmp SkipProcessorInfo
PUnknown:
	lea dx, HeaderMessageG
	int 21h
	lea dx, HeaderMessageH1
	int 21h
	cmp LoggingEnabled, 1
	je PUnknownWrite
	jmp SkipProcessorInfo
PUnknownWrite:
	WriteString 49, HeaderMessageG
	WriteString 11, HeaderMessageH1
	jmp SkipProcessorInfo
CPU386:
	lea dx, HeaderMessageG
	int 21h
	lea dx, HeaderMessageH2
	int 21h
	cmp LoggingEnabled, 1
	je CPU386Write
	jmp SkipProcessorInfo
CPU386Write:
	WriteString 49, HeaderMessageG
	WriteString 8, HeaderMessageH2
	jmp SkipProcessorInfo
CPU486:
	lea dx, HeaderMessageG
	int 21h
	lea dx, HeaderMessageH3
	int 21h
	cmp LoggingEnabled, 1
	je CPU486Write
	jmp SkipProcessorInfo
CPU486Write:
	WriteString 49, HeaderMessageG
	WriteString 8, HeaderMessageH3
	jmp SkipProcessorInfo
CPU586:
	lea dx, HeaderMessageG
	int 21h
	lea dx, HeaderMessageH4
	int 21h
	cmp LoggingEnabled, 1
	je CPU586Write
	jmp SkipProcessorInfo
CPU586Write:
	WriteString 49, HeaderMessageG
	WriteString 8, HeaderMessageH4
	jmp SkipProcessorInfo
PMark1:
	lea dx, HeaderMessageG
	int 21h
	lea dx, HeaderMessageH5
	int 21h
	cmp LoggingEnabled, 1
	je PMark1Write
	jmp SkipProcessorInfo
PMark1Write:
	WriteString 49, HeaderMessageG
	WriteString 29, HeaderMessageH5
	jmp SkipProcessorInfo
PMark2:
	lea dx, HeaderMessageG
	int 21h
	lea dx, HeaderMessageH6
	int 21h
	cmp LoggingEnabled, 1
	je PMark2Write
	jmp SkipProcessorInfo
PMark2Write:
	WriteString 49, HeaderMessageG
	WriteString 23, HeaderMessageH6
	jmp SkipProcessorInfo
PMark3:
	lea dx, HeaderMessageG
	int 21h
	lea dx, HeaderMessageH7
	int 21h
	cmp LoggingEnabled, 1
	je PMark3Write
	jmp SkipProcessorInfo
PMark3Write:
	WriteString 49, HeaderMessageG
	WriteString 24, HeaderMessageH7
	jmp SkipProcessorInfo
SkipProcessorInfo:
	mov si, FileNameLength	;restore the value of SI
	inc si
	inc si
	call ReadData
	call Hex2Dec
	mov ah, 09h
	lea dx, HeaderMessageI
	int 21h
	lea dx, HexText
	int 21h
	lea dx, DecimalText
	int 21h
	cmp LoggingEnabled, 1
	je WriteObjectCount
	jmp EndObjectCount
WriteObjectCount:
	WriteString 34, HeaderMessageI
	WriteString HexTextLength, HexText
	WriteString DecimalTextLength, DecimalText
EndObjectCount:
	jmp EndWindowsCheck
NoWindows:
	lea dx, HeaderMessageF
	mov ah, 09h
	int 21h
	cmp LoggingEnabled, 0
	je EndWindowsCheck
	WriteString 46, HeaderMessageF
EndWindowsCheck:
	ret
UnknownFormat:
	mov ah, 09h
	lea dx, Message9
	int 21h
	lea dx, InputFileName
	int 21h
	lea dx, MessageA
	int 21h
	lea dx, Message6
	int 21h
	cmp LoggingEnabled, 1
	je WriteUnknown1
	jmp SkipUnknown1
WriteUnknown1:
	mov bx, OutputFileHandle
	WriteString 13, Message9
	WriteString FileNameLength, InputFileName
	WriteString 8, MessageA
	WriteString 31, Message6
SkipUnknown1:
	jmp ExitProgram
COMFile:
	mov ah, 09h
	lea dx, Message9
	int 21h	
	lea dx, InputFileName
	int 21h
	lea dx, MessageA
	int 21h
	lea dx, Message8
	int 21h
	cmp LoggingEnabled, 1
	je WriteCOM1
	jmp SkipCOM1
WriteCOM1:
	mov bx, OutputFileHandle
	WriteString 13, Message9
	WriteString FileNameLength, InputFileName
	WriteString 8, MessageA
	WriteString 21, Message8
SkipCOM1:
	jmp ExitProgram
WriteError:
	lea dx, ErrorWrite
	mov ah, 09h
	int 21h
	jmp ExitProgram
ENDP

ReadData PROC
	xor cx, cx
	xor di, di
	mov bh, Buffer[si+1]
	mov bl, Buffer[si]
	xor ax, ax
	push bx
	mov dh, bh
	shr bh, 4
	cmp bh, 0
	je NextHexDigit1
	mov al, bh
	mov si, ax
	mov bh, HexDigits[si]
	mov HexText[di], bh
	inc cx
	inc di
	mov DigitFlag, 1
NextHexDigit1:
	mov bh, dh
	and bh, 0fh
	cmp bh, 0
	je CheckHexDigit2
	jmp OutputHexDigit2
CheckHexDigit2:
	cmp DigitFlag, 1
	je OutputHexDigit2
	jmp NextHexDigit2
OutputHexDigit2:
	mov al, bh
	mov si, ax
	mov bh, HexDigits[si]
	mov HexText[di], bh
	inc cx
	inc di
NextHexDigit2:
	mov dh, bl
	shr bl, 4
	cmp bl, 0
	je CheckHexDigit3
	jmp OutputHexDigit3
CheckHexDigit3:
	cmp DigitFlag, 1
	je OutputHexDigit3
	jmp NextHexDigit3
OutputHexDigit3:
	mov al, bl
	mov si, ax
	mov bl, HexDigits[si]
	mov HexText[di], bl
	inc cx
	inc di
NextHexDigit3:
	mov bl, dh
	and bl, 0fh
	mov al, bl
	mov si, ax
	mov bl, HexDigits[si]
	mov HexText[di], bl
	inc cx
	inc di
	pop bx
	mov HexText[di], 'h'
	inc di
	inc cx
	mov HexText[di], ' '
	inc di
	inc cx
	mov HexText[di], '$'
	xor si, si
	xor di, di
	mov HexTextLength, cx
	xor cx, cx
	mov DigitFlag, 0
	ret
ENDP

Hex2Dec PROC
	lea bp, DecimalText
	mov ax, bx
	cmp ax, 0
	jne ContinueDecimalConversion
	mov byte ptr ds:[bp], 13
	mov byte ptr ds:[bp+1], 10
	mov byte ptr ds:[bp+2], '$'
	mov Divisor, 0
	jmp EndDecimalConversion
ContinueDecimalConversion:
	mov Divisor, 10000
	xor dx, dx
H2D2:
	div Divisor
	push ax
	or al, DigitFlag
	pop ax
	jz NextDecimalDigit
	mov DigitFlag, 1
	add al, 30h
	mov ds:[bp], al
	inc bp
NextDecimalDigit:
	push dx
	xor dx, dx
	mov ax, Divisor
	mov bx, 10
	div bx
	mov Divisor, ax
	pop ax
EndDecimalConversion:
	cmp Divisor, 0
	jne H2D2
	mov byte ptr ds:[bp], 13
	mov byte ptr ds:[bp+1], 10
	mov byte ptr ds:[bp+2], '$'
	inc bp
	lea dx, DecimalTextLength
	sub bp, dx
	sub bp, 7
	mov DecimalTextLength, bp	;save the string length
	xor bp, bp
	xor dx, dx
	mov DigitFlag, 0
	ret
ENDP

CloseFiles PROC
	mov ah, 3eh
	mov bx, FileHandle
	int 21h
	mov ah, 3eh
	mov bx, OutputFileHandle
	int 21h
	ret
ENDP

.data
	Message0 db 'ExeInfo',13,10,'Copyright (C) 2001 Jakub Halun',13,10,'Program rozpoznaje typ pliku programu (COM/EXE)',13,10,'$'
	Message1 db 'i jezeli jest to program EXE, podaje informacje na jego temat.',13,10,'$'
	Message2 db 13,10,'EXEINFO [Dysk:][Sciezka]Nazwa_Pliku [/L:nazwa_pliku] [/W]',13,10,13,10,'$'
	Message3 db '/L:nazwa_pliku - zapisuje wygenerowane przez program komunikaty do nazwa_pliku',13,10,'$'
	Message5 db '/W - sprawdza, czy plik nie zawiera programu MS Windows',13,10,'$'
	Message6 db 'Nierozpoznany format pliku.',13,10,13,10,'$'
	Message7 db 'Program typu EXE.',13,10,13,10,'$'
	Message8 db 'Program typu COM.',13,10,13,10,'$'
	Message9 db 'NAZWA PLIKU: $'
	MessageA db 'FORMAT: $'
	HeaderMessage1 db 'Dlugosc ostatniej strony: $'
	HeaderMessage2 db 'Dlugosc programu razem z naglowkiem w stronach (512 B): $'
	HeaderMessage3 db 'Liczba elementow w tablicy przemieszczen: $'
	HeaderMessage4 db 'Rozmiar naglowka w paragrafach: $'
	HeaderMessage5 db 'Minimalna pamiec potrzebna ponad program (w paragrafach): $'
	HeaderMessage6 db 'Maksymalna pamiec potrzebna ponad program (w paragrafach): $'
	HeaderMessage7 db 'Przesuniecie segmentu SS: $'
	HeaderMessage8 db 'Wartosc rejestru SP na poczatku procesu: $'
	HeaderMessage9 db 'Suma kontrolna pliku: $'
	HeaderMessageA db 'Wartosc rejestru IP na poczatku procesu: $'
	HeaderMessageB db 'Przesuniecie segmentu CS: $'
	HeaderMessageC db 'Poczatek tablicy przemieszczen: $'
	HeaderMessageD db 'Numer nakladki: $'
	HeaderMessageE db 13,10,'Plik zawiera program typu MS Windows.',13,10,'$'
	HeaderMessageF db 13,10,'Plik nie zawiera programu typu MS Windows.',13,10,'$'
	HeaderMessageG db 'Typ procesora wymagany przez program MS Windows: $'
	HeaderMessageH1 db 'nieznany.',13,10,'$'
	HeaderMessageH2 db '80386.',13,10,'$'
	HeaderMessageH3 db '80486.',13,10,'$'
	HeaderMessageH4 db '80586.',13,10,'$'
	HeaderMessageH5 db 'MIPS Mark I (R2000, R3000).',13,10,'$'
	HeaderMessageH6 db 'MIPS Mark II (R6000).',13,10,'$'
	HeaderMessageH7 db 'MIPS Mark III (R4000).',13,10,'$'
	HeaderMessageI db 'Liczba wpisow w tablicy obiektow: $'
	HeaderMessageJ db 'Offset naglowka programu Windows: $'
	HexDigits db '0123456789ABCDEF'
	Buffer db 256 dup(?)
	Nonzero  db 0
	FileNameLength dw 0
	HexTextLength dw 0
	DecimalTextLength dw 0
	HexText db 6 dup(0)
	DecimalText db 12 dup(0)
	OutputFileName db 128 dup(0)
	InputFileName db 128 dup(0)
	Divisor dw ?
	DigitFlag db 0
	FileHandle dw ?
	OutputFileHandle dw ?
	Error0 db 'Blad. $'
	Error00 db 'Blad pliku do zapisu (LOG). $'
	Error80 db 'Plik do zapisu juz istnieje. Nadpisac istniejacy plik T/N',13,10,'$'
	Message80 db 'Podaj nowa nazwe dla tworzonego pliku: $'
	Error2 db 'Brak pliku o podanej nazwie.',13,10,'$'
	Error3 db 'Nie znaleziono sciezki dostepu.',13,10,'$'
	Error4 db 'Za duzo plikow otwartych rownoczesnie.',13,10,'$'
	Error5 db 'Brak uprawnien dostepu do pliku.',13,10,'$'
	ErrorWrite db 'Blad przy zapisie do pliku.',13,10,'$'
	WindowsCheckEnabled db ?
	LoggingEnabled db 0
End Start

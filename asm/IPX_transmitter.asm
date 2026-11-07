; Reads files using MS-DOS services and sends them over IPX.
; Intended to work together with IPX_receiver.asm.
;* IPX Transmitter/Receiver - Transmitter program
;* 2001 by Jakub Halun
;* http://halun.pl

.model small
jumps
.stack 64
.code
Start:
	mov ax, @data
	mov ds, ax
	call CheckIPX
	call SendFiles
ExitProgram:
	mov bx, 1h
	mov dx, 7777h
	int 7ah			;close the socket
	mov ax, 4c00h
	int 21h			;exit the program

SendFiles PROC
	mov ah, 09h
	lea dx, MessageI1
	int 21h
	lea dx, MessageI2
	int 21h
	lea dx, MessageI3
	int 21h
SendNextFile:
	mov di, 256
ClearNameBuffer:
	mov NameBuffer[di], 0	;clear NameBuffer
	dec di
	jz EndClearNameBuffer
	jmp ClearNameBuffer
EndClearNameBuffer:
	mov ah, 09h
	lea dx, Message8
	int 21h
	mov ah, 0ah
	mov NameBuffer[0], 128
	lea dx, NameBuffer
	int 21h			;get the name of the file to send
	xor ax, ax
	mov al, NameBuffer[1]
	mov di, ax
	mov si, ax
	mov NameBuffer[di+2], 0
	xor di, di
	mov ah, 09h
	lea dx, Message8
	sub dx, 3
	int 21h			;move to the next line
	mov ax, 3d00h	
	lea dx, NameBuffer + 2
	int 21h
	jc FileOpenError
	mov FileHandle, ax
	add si, 2
RemovePathLoop:
	cmp byte ptr NameBuffer[si], '\'	;remove any path from the file name
	je SkipPathSeparator
	cmp byte ptr NameBuffer[si], ':'
	je SkipPathSeparator
	dec si
	cmp si, 2
	je CopyBaseName
	jmp RemovePathLoop
SkipPathSeparator:
	inc si 
CopyBaseName:
	mov al, NameBuffer[si]
	mov Packet.Payload[di], al
	inc si
	inc di
	cmp al, 0
	je EndRemovePath
	jmp CopyBaseName
EndRemovePath:
	xor si, si
	add di, 30
	mov PacketSize, di
	xor di, di

	mov ax, 4202h
	xor cx, cx
	xor dx, dx
	mov bx, FileHandle
	int 21h				;get the file size
	mov PacketCount, 546
	div PacketCount
	add ax, 3
	mov PacketCount, ax			;and save it as the number of packets to send
	mov ax, 4200h
	mov bx, FileHandle
	xor cx, cx
	xor dx, dx
	int 21h				;return to the beginning of the file
	mov SentPacketCount, 0

	call PrepareToSend
	mov ah, 09h
	lea dx, MessageA
	int 21h
	call SendPacket
	mov ah, 09h
	lea dx, MessageB
	int 21h
	call PrepareToReceive
	call ReceivePacket
	cmp Packet.Payload[0], 1
	je TransferRefused
	jmp TransferData
TransferRefused:
	mov ah, 09h
	lea dx, Message6
	int 21h
	jmp CloseSentFile
TransferData:
	mov di, 128			;delay between packets
DelayLoop1:				;if your processor has a clock
	mov cx, 0ffffh			;speed below 200 MHz,
DelayLoop2:				;decrease this value
	dec cx
	jnz DelayLoop2
	dec di
	jnz DelayLoop1
	mov ah, 3fh
	mov bx, FileHandle
	mov cx, 546
	lea dx, Packet.Payload
	int 21h
	cmp ax, 0			;if 0 bytes were read (end of file),
	je EndTransfer			;end the transmission
	add ax, 30
	mov PacketSize, ax
	call PrepareToSend
	call SendPacket
	jmp TransferData
EndTransfer:
	mov Packet.Payload[0], 3		;a packet containing this sequence
	mov Packet.Payload[1], 6		;signals to the receiver
	mov Packet.Payload[2], 9		;that transmission of the file
	mov Packet.Payload[3], '~'		;has finished
	mov Packet.Payload[4], 66
	mov PacketSize, 35
	call PrepareToSend
	call SendPacket
CloseSentFile:
	mov ah, 3eh
	mov bx, FileHandle
	int 21h
FinishSending:
	mov ah, 09h
	lea dx, MessageC
	int 21h
ReadCharacter:
	mov ah, 07h
	int 21h
	cmp al, 116
	je ExitProgram
	cmp al, 110
	je SendNextFile
	jmp ReadCharacter
	ret
FileOpenError:
	cmp ax, 2
	je Error2
	cmp ax, 3
	je Error3
	cmp ax, 4
	je Error4
	cmp ax, 5
	je Error5
	jmp FinishSending
Error2:
	mov ah, 09h
	lea dx, Message92
	int 21h
	jmp FinishSending
Error3:
	mov ah, 09h
	lea dx, Message93
	int 21h
	jmp FinishSending
Error4:
	mov ah, 09h
	lea dx, Message94
	int 21h
	jmp FinishSending
Error5:
	mov ah, 09h
	lea dx, Message95
	int 21h
	jmp FinishSending
ENDP

PrepareToSend PROC
	lea si, Packet.SourceNetwork
	push ds
	pop es
	mov bx, 9
	int 7ah					;get the local addresses
	mov Packet.Checksum, 0ffffh
	mov ax, PacketSize
	mov Packet.PacketLength, ax
	mov Packet.PacketType, 0
	mov cx, 4
	xor di, di
SendInitLoop1:
	mov IPXWorkspace[di], 0
	mov Packet.DestinationNetwork[di], 0
	mov ECB.LinkAddress[di], 0
	mov ECB.EventServiceRoutine[di], 0
	inc di
	dec cx
	jz EndSendInitLoop1
	jmp SendInitLoop1
EndSendInitLoop1:
	mov cx, 6
	xor di, di
SendInitLoop2:
	mov ECB.DestinationAddress[di], 0ffh
	mov Packet.DestinationNode[di], 0ffh
	inc di
	dec cx
	jz EndSendInitLoop2
	jmp SendInitLoop2
EndSendInitLoop2:
	xor di, di
	mov cx, 12
SendInitLoop3:
	mov ECB.DriverWorkspace[di], 0
	inc di
	dec cx
	jz EndSendInitLoop3
	jmp SendInitLoop3
EndSendInitLoop3:
	mov Packet.TransportControl, 0
	mov Packet.DestinationSocket, 7777h
	mov Packet.SourceSocket, 7777h
	mov ECB.SocketNumber, 7777h
	mov ECB.FragmentCount, 1
	mov ECB.CompletionCode, 0
	mov ECB.InUseFlag, 0
	mov ax, PacketSize
	mov ECB.LocalSize, ax
	mov ax, ds
	mov ECB.LocalAddress[3], ah
	mov ECB.LocalAddress[2], al
	lea ax, Packet
	mov ECB.LocalAddress[1], ah
	mov ECB.LocalAddress[0], al
	ret
ENDP

CheckIPX PROC
	mov ax, 7a00h
	int 2fh				;check whether IPX is installed
	cmp al, 0ffh
	jne NoIPX
	xor ax, ax
	mov dx, 7777h			;assign socket number 7777h
	xor bx, bx
	int 7ah
	cmp al,	0
	jne SocketNumberError
	ret
NoIPX:
	mov ah, 09h
	lea dx, Message0
	int 21h
	jmp ExitProgram
SocketNumberError:
	mov ah, 09h
	lea dx, Message7
	int 21h
	jmp ExitProgram
ENDP

SendPacket PROC
	mov ah, 09h
	lea dx, Message4
	int 21h
	mov bx, 0003h
	lea si, ECB
	int 7ah
SendWaitLoop:
	mov bx, 000ah
	int 7ah
	lea si, ECB.InUseFlag
	cmp byte ptr es:[si], 0
	jne SendWaitLoop
	inc SentPacketCount
	mov bx, SentPacketCount
	call Hex2Dec
	mov ah, 09h
	lea dx, MessageE
	int 21h
	lea dx, MessageG
	int 21h
	mov bx, PacketCount
	call Hex2Dec
	mov ah, 09h
	lea dx, MessageE
	int 21h
	lea dx, MessageF
	int 21h
EndPacketStatus:
	lea dx, Message5
	int 21h
	ret
ENDP

PrepareToReceive PROC
	xor si, si
	xor di, di
	mov ECB.CompletionCode, 0
	mov ECB.InUseFlag, 1dh
	mov ECB.SocketNumber, 7777h
	mov ECB.FragmentCount, 1
	mov ax, ds
	mov ECB.LocalAddress[3], ah
	mov ECB.LocalAddress[2], al
	lea ax, Packet
	mov ECB.LocalAddress[1], ah
	mov ECB.LocalAddress[0], al
	mov ECB.LocalSize, 576
	mov Packet.Checksum, 0
	mov Packet.PacketLength, 0
	mov Packet.TransportControl, 0
	mov Packet.PacketType, 0
	mov Packet.DestinationSocket, 0
	mov Packet.SourceSocket, 0
	mov cx, 4
	xor di, di
ReceiveInitLoop1:
	mov Packet.DestinationNetwork[di], 0
	mov Packet.SourceNetwork[di], 0
	mov ECB.LinkAddress[di], 0
	mov ECB.EventServiceRoutine[di], 0
	mov ECB.IPXWorkspace[di], 0
	inc di
	dec cx
	jz EndReceiveInitLoop1
	jmp ReceiveInitLoop1	
EndReceiveInitLoop1:
	xor di, di
	mov cx, 6
ReceiveInitLoop2:
	mov ECB.DestinationAddress[di], 0 
	mov Packet.DestinationNode[di], 0
	mov Packet.SourceNode[di], 0
	inc di
	dec cx
	jz EndReceiveInitLoop2
	jmp ReceiveInitLoop2
EndReceiveInitLoop2:
	xor di, di
	mov cx, 12
ReceiveInitLoop3:
	mov ECB.IPXWorkspace[di], 0
	inc di
	dec cx
	jz EndReceiveInitLoop3
	jmp ReceiveInitLoop3
EndReceiveInitLoop3:
	ret
ENDP

ReceivePacket PROC
	mov bx, 4
	push ds
	pop es
	lea si, ECB
	int 7ah
ReceiveWaitLoop:
	mov bx, 0ah
	int 7ah
	lea si, ECB.InUseFlag
	cmp byte ptr es:[si], 0
	jne ReceiveWaitLoop
	mov ah, 09h
	lea dx, MessageD
	sub dx, 3
	int 21h
	ret
ENDP

Hex2Dec PROC
	lea bp, MessageE
	mov ax, bx

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
	mov byte ptr ds:[bp], '$'
	xor bp, bp
	xor dx, dx
	xor ax, ax
	mov DigitFlag, 0
	ret
ENDP

.data
	Message0 db 'Blad. Sterownik IPX nie jest zainstalowany w systemie.',13,10,'$'
	Message1 db 'Blad. Nie mozna wyslac pakietu.',13,10,'$'
	Message2 db 'Podaj nazwe pliku: $'
	Message3 db 'Zakonczyc prace programu? T/N',13,10,'$'
	Message4 db 'Wysylanie pakietu $'
	Message5 db ' OK',13,10,'$'
	Message6 db 'Blad. Odbiornik nie moze przyjac pliku.',13,10,'$'
	Message7 db 'Blad przy realizacji przyznania numeru procesu.',13,10,'$'
	MessageI1 db 'IPX Nadajnik/Odbiornik',13,10,'$'
	MessageI2 db 'Program nadawczy',13,10,'$'
	MessageI3 db 'Copyright (c) 2001 Jakub Halun',13,10,13,10,'$'
	Message8 db 'Podaj nazwe pliku do wyslania.',13,10,'(maksymalnie 128 znakow wraz ze sciezka): $'
	Message9 db 'Plik zostal otwarty bez bledow.',13,10,'$'
	Message92 db 'Blad. Brak pliku o podanej nazwie.',13,10,'$'
	Message93 db 'Blad. Nie znaleziona sciezka dostepu.',13,10,'$'
	Message94 db 'Blad. Zbyt wiele plikow otwartych rownoczesnie.',13,10,'$'
	Message95 db 'Blad. Brak uprawnien do otwarcia pliku.',13,10,'$'
	MessageA db 'Przeslanie informacji do odbiornika.',13,10,'$'
	MessageB db 'Oczekiwanie na odpowiedz odbiornika...$'
	MessageC db 'Zakonczyc prace programu T/N',13,10,'$'
	MessageD db 13,10,'Odbiornik gotowy do odebrania pliku.',13,10,'$'
	MessageE db 32 dup(?)
	MessageG db ' z $'
	MessageF db '... $'
	IPXSeg dw ?
	IPXOffs dw ?
	FileHandle dw 0
	PacketSize dw ?
	NameBuffer db 130 dup(0)
	StringLength dw ?
	PacketCount dw 546
	SentPacketCount dw ?
	Divisor dw ?
	DigitFlag db 0
	IPXPacket STRUC
		Checksum dw 0
		PacketLength dw 0
		TransportControl db 0
		PacketType db 0
		DestinationNetwork db 4 dup(0)
		DestinationNode db 6 dup(0)
		DestinationSocket dw 0
		SourceNetwork db 4 dup(0)
		SourceNode db 6 dup(0)
		SourceSocket dw 0
		Payload db 546 dup(0)
	IPXPacket ENDS
	Packet IPXPacket ?
	ECBBlock	STRUC
		LinkAddress db 4 dup(0)
		EventServiceRoutine db 4 dup(0)
		InUseFlag db 0
		CompletionCode db 0
		SocketNumber dw 0
		IPXWorkspace db 4 dup(0)
		DriverWorkspace db 12 dup(0)
		DestinationAddress db 6 dup(0)	;destination node address
		FragmentCount dw 0
		LocalAddress db 4 dup(0)	;IPX packet address
		LocalSize dw 0		;IPX packet size
	ECBBlock ENDS
	ECB ECBBlock ?
End Start
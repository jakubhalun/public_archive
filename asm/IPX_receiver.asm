; Receives files over IPX and saves them using MS-DOS services.
; Intended to work together with IPX_transmitter.asm.
;* IPX Transmitter/Receiver - Receiver program
;* 2001 by Jakub Halun
;* http://halun.pl

.model small
.stack 64
jumps
.code
Start:
	mov ax, @data
	mov ds, ax
	call CheckIPX
	call ReceiveFiles
ExitProgram:
	mov bx, 1
	mov dx, 7777h			;close the socket
	int 7ah
	mov ax, 4c00h
	int 21h

ReceiveFiles PROC
	mov ah, 09h
	lea dx, MessageI1
	int 21h
	lea dx, MessageI2
	int 21h
	lea dx, MessageI3
	int 21h
ReceiveNextFile:
	mov ah, 09h
	lea dx, Message5
	int 21h
	call PrepareToReceive
	call ReceivePacket
	mov cx, 60
	xor si, si
	xor di, di
CopyFileName:
	mov al, Packet.Payload[si]		;copy the file name from the received packet to the Message2 buffer
	cmp al, 0			;the buffer will be used to display the name
	je EndCopyFileName
	mov Message2[di], al
	inc si
	inc di
	dec cx
	jz EndCopyFileName
	jmp CopyFileName	
EndCopyFileName:
	mov Message2[di], 13
	mov Message2[di+1], 10
	mov Message2[di+2], '$'
	xor si, si
	xor di, di
	mov ah, 09h
	lea dx, Message1
	int 21h
	lea dx, Message2
	int 21h
	lea dx, Message7
	int 21h

ReadCharacter1:
	mov ah, 07h
	int 21h
	cmp al, 116
	je AcceptFile
	cmp al, 110
	je RefuseFile
	jmp ReadCharacter1
AcceptFile:
	mov ah, 5bh
	lea dx, Packet.Payload
	xor cx, cx
	int 21h
	jc FileWriteError
	mov FileHandle, ax
ConfirmReceive:
	mov Packet.Payload[0], 0		;if the program is to receive the file,
	mov PacketSize, 31		;send the transmitter a packet containing
	mov ah, 09h			;0 in byte zero of the data field
	lea dx, Message4			;to signal readiness to receive the file
	int 21h
	lea dx, MessageA
	int 21h
	call PrepareToSend
	call SendPacket
ReceiveDataLoop:
	call PrepareToReceive
	call ReceivePacket
	cmp Packet.Payload[0], 3		;check for the final packet (containing
	jne WriteReceivedData			;the sequence: 3,6,9,'~',66)
	cmp Packet.Payload[1], 6
	jne WriteReceivedData
	cmp Packet.Payload[2], 9
	jne WriteReceivedData
	cmp Packet.Payload[3], '~'
	jne WriteReceivedData
	cmp Packet.Payload[4], 66
	jne WriteReceivedData
	jmp ReceiveComplete
WriteReceivedData:
	mov ah, 40h
	mov bx, FileHandle
	lea dx, Packet.Payload
	mov cx, Packet.PacketLength
	xchg ch, cl			;convert from high-low byte order (used
	sub cx, 30			;in the IPX header) to low-high (Intel's standard)
	int 21h				;and write this many bytes (after subtracting
	jmp ReceiveDataLoop				;the header length) to the file
RefuseFile:
	mov Packet.Payload[0], 1		;if the program is not to receive the file, send
	mov PacketSize, 31		;the transmitter a packet with 1 in byte zero of the data field
	call PrepareToSend
	call SendPacket
	jmp FinishReceive
FileWriteError:
	cmp ax, 80
	jne OtherWriteError
	mov ah, 09h
	lea dx, Message2A
	int 21h
	lea dx, Message2B
	int 21h
ReadCharacter2:
	mov ah, 07h
	int 21h
	cmp al, 116
	je Overwrite
	cmp al, 110
	je DoNotOverwrite
	jmp ReadCharacter2
Overwrite:
	mov ah, 3ch
	lea dx, Packet.Payload
	xor cx, cx
	int 21h
	jc FileWriteError
	mov FileHandle, ax
	jmp ConfirmReceive
DoNotOverwrite:
	mov ah, 09h
	lea dx, Message9
	int 21h
	mov ah, 0ah		;read a line from the keyboard
	mov NameBuffer[0], 128	;maximum string length
	lea dx, NameBuffer
	int 21h
	xor ax, ax
	mov al, NameBuffer[1]
	mov di, ax		;length of the string read
	mov NameBuffer[di+2], 0
	xor di, di
	lea dx, NameBuffer + 2
	mov ax, 5b00h		;create a new file
	xor cx, cx
	int 21h
	jc FileWriteError
	mov FileHandle, ax
	mov ah, 09h
	lea dx, Message9
	sub dx, 3
	int 21h
	jmp ConfirmReceive
OtherWriteError:
	mov ah, 09h
	lea dx, Message8
	int 21h
	jmp RefuseFile
ReceiveComplete:
	mov ah, 09
	lea dx, MessageB
	int 21h
FinishReceive:
	mov ah, 3eh
	mov bx, FileHandle
	int 21h
	mov ah, 09h
	lea dx, Message3
	int 21h
ReadCharacter3:
	mov ah, 07h
	int 21h
	cmp al, 116
	je EndReceiveProcedure
	cmp al, 110
	je ReceiveNextFile
	jmp ReadCharacter3
EndReceiveProcedure:
	ret
ENDP


PrepareToReceive PROC
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
	mov Packet.PacketLength, 0		;clear all IPX header fields
	mov Packet.TransportControl, 0	;when receiving
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


CheckIPX PROC
	mov ax, 7a00h
	int 2fh				;check whether IPX is installed
	cmp al, 0ffh
	jne NoIPX
	xor bx, bx
	xor ax, ax
	mov dx, 7777h
	int 7ah				;open socket number 7777h
	cmp ax, 0
	jne SocketError
	ret
NoIPX:
	mov ah, 09h
	lea dx, Message0
	int 21h
	jmp ExitProgram
SocketError:
	mov ah, 09h
	lea dx, Message6
	int 21h
	jmp ExitProgram
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
	ret
ENDP


PrepareToSend PROC
	lea si, Packet.SourceNetwork
	push ds
	pop es
	mov bx, 9
	int 7ah				;get the local addresses
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


SendPacket PROC
	mov bx, 0003h
	lea si, ECB
	int 7ah
SendWaitLoop:
	mov bx, 000ah
	int 7ah
	lea si, ECB.InUseFlag
	cmp byte ptr es:[si], 0
	jne SendWaitLoop
	ret
ENDP


.data
	Message0 db 'Blad. Sterownik IPX nie jest zainstalowany w systemie.',13,10,'$'
	Message1 db 'Odbior pliku: $'
	Message2 db 64 dup(?)
	Message2A db 'Blad. Plik o takiej nazwie juz istnieje.',13,10,'$'
	Message2B db 'Nadpisac istniejacy plik? T/N',13,10,'$'
	Message3 db 'Zakonczyc prace programu? T/N',13,10,'$'
	Message4 db 'Potwierdzenie wyslane do nadajnika.',13,10,'$'
	Message5 db 'Oczekiwanie na transmisje nadajnika...',13,10,'$'
	Message6 db 'Blad podczas otwierania koncowki.',13,10,'$'
	Message7 db 'Odebrac plik? T/N',13,10,'$'
	Message8 db 'Blad przy zapisie pliku.',13,10,'$'
	Message9 db 'Podaj nowa nazwe dla pliku: ',13,10,'$'
	MessageI1 db 'IPX Nadajnik/Odbiornik',13,10,'$'
	MessageI2 db 'Program odbiorczy',13,10,'$'
	MessageI3 db 'Copyright (c) 2001 Jakub Halun',13,10,13,10,'$'
	MessageA db 'Odbior pliku... $'
	MessageB db ' OK',13,10,'$'
	NameBuffer db 128 dup(?)
	PacketSize dw ?
	FileHandle dw ?
	ECBBlock	STRUC				;before initialization, all fields
		LinkAddress db 4 dup(0)		;of the ECB control block and the IPX
		EventServiceRoutine db 4 dup(0)	;packet header must be cleared
		InUseFlag db 0
		CompletionCode db 0
		SocketNumber dw 0
		IPXWorkspace db 4 dup(0)
		DriverWorkspace db 12 dup(0)
		DestinationAddress db 6 dup(0)	;destination node address
		FragmentCount dw 0	;1 if the packet header and data are in one structure
		LocalAddress db 4 dup(0)	;IPX packet address
		LocalSize dw 0		;IPX packet size
	ECBBlock ENDS
	ECB ECBBlock ?
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
End Start
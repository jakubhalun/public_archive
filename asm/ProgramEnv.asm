;***http://halun.pl/***

.model tiny
.code
	org 100h
Start:
	mov ah, 62h		;funkcja 62h...
	int 21h			;...przerwania 21h - pobranie adresu PSP	
	mov es, bx		;zaladuj adres PSP do rejestru ES

	mov bx, es:[2Ch]	;zaladuj zawartosc pola 2Ch w PSP (adres otoczenia) do rejestru BX
	mov es, bx		;zaladuj adres otoczenia do rejestru ES

	mov cx, 256
	xor si, si
	mov ah, 02h
WyswietlBajty:
	mov dl, es:[si]		;wyswietlaj zawartosc otoczenia znak po znaku
	int 21h
	inc si
	loop WyswietlBajty 

	mov ax, 4c00h		;zamknij program
	int 21h
End Start

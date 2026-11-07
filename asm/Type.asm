;***http://halun.pl/***
.model tiny

.stack 64

.data
	Kom1 db 'Program wyswietla zawartosc plikow tekstowych',13,10,'$'
	Kom2 db 13,10,'Napisz [dysk:][sciezka]nazwapliku',13,10,'$'
	DlLiniiParam db ?			;dlugosc linii parametrow
	NazwaPliku db 15 dup (?)
	DojscieDoPliku dw ?
	Blad2 db 'Nie znaleziono pliku',13,10,'$'
	Blad3 db 'Nie znaleziono sciezki',13,10,'$'
	Blad4 db 'Zbyt wiele otwartych plikow',13,10,'$'
	Blad5 db 'Dostep niemozliwy',13,10,'$'
	BuforOperacji db 256 dup (?)

.code

BrakParametrow PROC
	mov ah, 09h
	lea dx, Kom1
	int 21h
	lea dx, Kom2
	int 21h
	ret
ENDP


BladOtwieraniaPliku PROC
	cmp ax, 2
	je B2
	cmp ax, 3
	je B3
	cmp ax, 4
	je B4
	cmp ax, 5
	je B5
B2:	lea dx, Blad2
	jmp WyswKom
B3:	lea dx, Blad3
	jmp WyswKom
B4:	lea dx, Blad4
	jmp WyswKom
B5:	lea dx, Blad5
	jmp WyswKom
WyswKom:
	mov ah, 09h
	int 21h
	jmp Koniec
ENDP


CzyJestParametr PROC
	mov ah, 62h			;znajdz adres bloku PSP
	int 21h
	mov es, bx			;zaladuj adres bloku PSP do ES
	mov bl,ES:[80h]
	cmp bl, 0			;sprawdz, czy sa parametry		
	jne SaParametry
	call BrakParametrow
	jmp Koniec			;jezeli bez parametrow - zakoncz
SaParametry:
	mov DlLiniiParam, bl
	ret
ENDP


ZaladujNazwePliku PROC
	mov bx, 81h			;zaladuj przesuniecie linii parametrow
	mov si, bx			;...do rejestru SI
	mov cl, DlLiniiParam		;zaladuj dlugosc linii parametrow
	lea di, NazwaPliku		;zaladuj offset tablicy NazwaPliku
Petla1:
	mov al, es:[si]
	cmp al, 20h
	je Spacja
	mov ds:[di], al
	inc di
Spacja:	dec cx
	inc si
	jcxz KoniecPetli1
	jmp petla1
KoniecPetli1:
	mov ah, 0			;zaladuj na koniec lancucha znak '0'
	mov ds:[di], ah
	xor si, si
	xor di, di
	ret
ENDP


ZaladujPlik PROC
	lea dx, nazwapliku
	mov ax, 3d00h
	int 21h
	jnb NieMaBledu
	call BladOtwieraniaPliku
NieMaBledu:
	mov DojscieDoPliku, ax
	ret
ENDP


Plik2Ekran PROC
WyPlik:
	lea dx, BuforOperacji
	mov bx, DojscieDoPliku		;zaladuj numer dojscia do pliku
	mov ah, 3fh		;funkcja czytania z pliku
	mov cx,	256		;zaladuj ilosc bajtow do odczytania
	int 21h
	cmp ax, 0
	je WyPlikK
	mov cx, ax
	call NaEkran
	jmp WyPlik
WyPlikK:
	ret
ENDP


NaEkran PROC
	xor si, si
PetlaEkran:
	mov dl, BuforOperacji[si]
	mov ah, 02h		;wypisz znak
	int 21h
	inc si
	dec cx
	jcxz KPetlaEkran
	jmp PetlaEkran
KPetlaEkran:
	xor si, si
	ret
ENDP


ZamknijPlik PROC
	mov ah, 3Eh
	mov bx, DojscieDoPliku
	int 21h
	ret
ENDP


Start:					;rozpoczecie pracy programu
	mov ax, @data
	mov ds, ax
	call CzyJestParametr
	call ZaladujNazwePliku
	call ZaladujPlik
	call Plik2Ekran
Zamknij:
	call ZamknijPlik
Koniec:	mov ax, 4c00h			;zakonczenie pracy programu
	int 21h


End Start

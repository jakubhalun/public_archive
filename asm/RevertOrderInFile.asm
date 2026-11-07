;***http://halun.pl/***
.model small
.stack 128
.386
.data
	Plik1 db 15 dup (?)
	Plik2 db 15 dup (?)
	Uchwyt1 dw ?
	Uchwyt2 dw ?
	Bufor db 256 dup (?)
	Znak db ?
	DlLiniiParam db ?
	Dlugosc dw 0
	Wsk1 dw 0
	Wsk2 dw 0
	Kom1 db 'Program sluzy do odwracania zawartosci plikow tekstowych',13,10,13,10,'$'
	Kom2 db 'Wywolanie:    ODWROC  plik1 plik2',13,10,13,10,'$'
	Kom3 db 'plik1 - plik do odczytu',13,10,'$'
	Kom4 db 'plik2 - plik w ktorym odwrocona zawartosc pierwszego bedzie zapisana',13,10,'$'
	Kom5 db 'BLAD: NIEPRAWIDLOWE PARAMETRY',13,10,13,10,'$'
	Kom6 db 'BLAD: NIE MOZNA OTWORZYC PLIKU DO ODCZYTU',13,10,'$'
	Kom7 db 'BLAD: NIE MOZNA UTWORZYC PLIKU DO ZAPISU',13,10,'$'
.code
Pomoc PROC
	mov ah, 09h
	lea dx, Kom1
	int 21h
	lea dx, Kom2
	int 21h
	lea dx, Kom3
	int 21h
	lea dx, Kom4
	int 21h
	jmp Koniec
ENDP

CzySaParametry PROC
	mov ah, 62h			;pobierz adres PSP
	int 21h
	mov es, bx			;i zapisz go w ES
	xor ax, ax
	mov al, es:[80h]
	cmp al, 2
	jna BrakParametrow		;jezeli wiersze WE nie dluzszy niz 2
	mov cx, ax
	ret
BrakParametrow:
	call Pomoc
	jmp Koniec
ENDP

PobierzParametry PROC
	mov si, 81h
	xor di, di
PetlaPar1:
	mov al, es:[si]
	cmp al, 20h
	jne PetlaPar2		;jezeli znak rozny niz spacja przejdz dalej
	inc si
	dec cx
	jz BladP		;jezeli koniec wiersza wejsciowego - zakoncz
	jmp PetlaPar1
PetlaPar2:
	mov al, es:[si]
	cmp al, 20h
	je PetlaPar3		;gdy spacja - zakoncz pobieranie pierwszej nazwy
	mov Plik1[di], al
	mov Plik1[di+1], 0
	inc si
	inc di
	dec cx
	jz BladP
	jmp PetlaPar2
PetlaPar3:
	xor di, di
	mov al, es:[si]
	cmp al, 20h
	jne PetlaPar4		;jezeli znak rozny niz spacja przejdz dalej
	inc si
	dec cx
	jz BladP		;jezeli koniec wiersza wejsciowego - zakoncz
	jmp PetlaPar3
PetlaPar4:
	mov al, es:[si]
	cmp al, 20h
	je KPetliP		;gdy spacja - zakoncz pobieranie drugiej nazwy
	mov Plik2[di], al
	mov Plik2[di+1], 0
	inc si
	inc di
	dec cx
	jz KPetliP
	jmp PetlaPar4
KPetliP:
	xor si, si
	xor di, di
	ret
BladP:
	lea dx, Kom5
	mov ah, 09h
	int 21h
	call Pomoc
ENDP

OtworzDoOdczytu PROC
	mov ax, 3d00h
	lea dx, Plik1
	int 21h
	jc BlPlik1
	mov Uchwyt1, ax
	ret
BlPlik1:
	lea dx, Kom6
	mov ah, 09h
	int 21h
	jmp Koniec
ENDP

OtworzDoZapisu PROC
	mov ah, 5bh
	lea dx, Plik2
	xor cx, cx
	int 21h
	jc BlPlik2
	mov Uchwyt2, ax
	ret
BlPlik2:
	lea dx, Kom7
	mov ah, 09h
	int 21h
	jmp Koniec
ENDP

OdczytajDane PROC

	ret
ENDP

ZapiszDane PROC
	cmp Dlugosc, 0
	je KPetliZapisu
	mov cx, Dlugosc
	mov si, cx
PetlaZap:
	push cx
	mov bx, Uchwyt2
	mov ah, 40h
	mov cx, 1
	mov al, Bufor[si]
	cmp al, 13
	je Zn13
	cmp al, 10
	je Zn10
	mov Znak, al
	jmp ZnK
Zn13:
	mov Znak, 10
	jmp ZnK
Zn10:
	mov Znak, 13
ZnK:
	lea dx, Znak
	int 21h
	pop cx
	dec si
	dec cx
	jz KPetliZapisu
	jmp PetlaZap
KPetliZapisu:
	ret
ENDP

Plik2Plik PROC
	mov bx, Uchwyt1
	mov ax, 4202h
	xor cx, cx
	xor dx, dx
	int 21h
	mov Wsk1, dx
	mov Wsk2, ax
P2PPetla:
	call OdczytajDane
	call ZapiszDane
	cmp Dlugosc, 0
	je P2PKoniec
	jmp P2pPetla	
P2PKoniec:
	ret
ENDP

ZamknijPliki PROC
	mov ah, 3eh
	mov bx, Uchwyt1
	int 21h
	mov ah, 3eh
	mov bx, Uchwyt2
	int 21h
	ret
ENDP

Start:
	mov ax, @data
	mov ds, ax
	call CzySaParametry
	call PobierzParametry
	call OtworzDoOdczytu
	call OtworzDoZapisu
	call Plik2Plik
Koniec:
	call ZamknijPliki
	mov ax, 4c00h
	int 21h
End Start
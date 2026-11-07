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
	call SprawdzParam
	call OtworzPliki
	call SprawdzPlik
Koniec:
	call ZamknijPliki
	mov ax, 4c00h
	int 21h

Pomoc PROC
	mov ah, 9h
	lea dx, Kom0
	int 21h
	lea dx, Kom1
	int 21h
	lea dx, Kom2
	int 21h
	lea dx, Kom3
	int 21h
	lea dx, Kom5
	int 21h
	jmp Koniec
	ret
ENDP

SprawdzParam PROC
	xor di, di
	xor si, si
	mov ah, 62h
	int 21h
	mov es, bx
	cmp byte ptr es:[80h], 2
	jb Help
	xor cx, cx
	mov cl, es:[80h]
Sprawdz:
	inc si
	cmp si, cx
	ja KPParam
	cmp byte ptr es:[si+80h], ' '
	je Sprawdz
	cmp byte ptr es:[si+80h], '/'
	je Parametr
	mov al, es:[si+80h]
	mov Plik[di], al
	inc di
	jmp Sprawdz
Parametr:
	xor di, di
	cmp Plik[0], 0
	je Help
	inc si
	cmp si, cx
	ja Help
	cmp byte ptr es:[si+80h], 'w'
	je Wind
	cmp byte ptr es:[si+80h], 'W'
	je Wind
	cmp byte ptr es:[si+80h], 'l'
	je ZpPl
	cmp byte ptr es:[si+80h], 'L'
	je ZpPl
	jmp Sprawdz
Wind:
	mov WinT, 1
	jmp Sprawdz
ZpPl:
	mov ZapisT, 1
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
ZpPlPetla:
	mov al, es:[si+80h]
	cmp al, ' '
	je KZpPlPetla
	cmp al, '/'
	je KZpPlPetla
	mov PlikDoZ[di], al
	inc di
	inc si
	cmp si, cx
	ja KPParam
	jmp ZpPlPetla
KZpPlPetla:
	xor di, di
	jmp Sprawdz
Help:
	call Pomoc
KPParam:
	xor di, di
	xor si, si
	cmp Plik[0], 0
	je Help
	ret
ENDP

OtworzPliki PROC
	lea dx, Plik
	mov ax, 3d00h		;otwarcie pliku
	int 21h
	jc BladX
	mov Uchwyt, ax
	xor si, si
SprDlN:
	cmp Plik[si], 0
	je KSprDlN
	inc si
	jmp SprDlN
KSprDlN:
	inc si
	inc si
	mov DlNazwyPl, si
	mov Plik[si-2], 13
	mov Plik[si-1], 10
	mov Plik[si], '$'
	xor si, si
	cmp ZapisT, 1		;sprawdz czy utworzyc plik.log
	je PlikDZap
Powrot1:
	ret
PlikDZap:
	mov ax, 5b00h		;tworzenie nowego pliku
	lea dx, PlikDoZ
	xor cx, cx
	int 21h
	jc BladY
	mov UchwytZ, ax
	jmp Powrot1
BladX:
	cmp ax, 2
	je BladX2
	cmp ax, 3
	je BladX3
	cmp ax, 4
	je BladX4
	cmp ax, 5
	je BladX5
BladY:
	cmp ax, 2
	je BladY2
	cmp ax, 3
	je BladY3
	cmp ax, 4
	je BladY4
	cmp ax, 5
	je BladY5
	cmp ax, 80
	je BladY80
BladX2:
	mov ah, 09h
	lea dx, Blad0
	int 21h
	lea dx, Blad2
	int 21h
	jmp Koniec
BladX3:
	mov ah, 09h
	lea dx, Blad0
	int 21h
	lea dx, Blad3
	int 21h
	jmp Koniec
BladX4:
	mov ah, 09h
	lea dx, Blad0
	int 21h
	lea dx, Blad4
	int 21h
	jmp Koniec
BladX5:
	mov ah, 09h
	lea dx, Blad0
	int 21h
	lea dx, Blad5
	int 21h
	jmp Koniec
BladY2:
	mov ah, 09h
	lea dx, Blad00
	int 21h
	lea dx, Blad2
	int 21h
	jmp Koniec
BladY3:
	mov ah, 09h
	lea dx, Blad00
	int 21h
	lea dx, Blad3
	int 21h
	jmp Koniec
BladY4:
	mov ah, 09h
	lea dx, Blad00
	int 21h
	lea dx, Blad4
	int 21h
	jmp Koniec
BladY5:
	mov ah, 09h
	lea dx, Blad00
	int 21h
	lea dx, Blad5
	int 21h
	jmp Koniec
BladY80:
	mov ah, 09h
	lea dx, Blad0
	int 21h
	lea dx, Blad80	
	int 21h
CzytajZnak:
	mov ah, 07h		;czytaj znak
	int 21h
	cmp al, 116
	je Nadpisz
	cmp al, 110
	je NieNadpisuj
	jmp CzytajZnak
Nadpisz:
	mov ah, 3ch		;tworzenie pliku z nadpisaniem starego
	lea dx, PlikDoZ
	int 21h
	jc BladY
	mov UchwytZ, ax
	jmp Powrot1
NieNadpisuj:
	mov ah, 09h
	lea dx, Kom80
	int 21h
	mov ah, 0ah		;odczyt wiersza z klawiatury
	mov PlikDoZ[0], 128	;maksymalna dlugosc ciagu
	lea dx, PlikDoZ
	int 21h
	xor ax, ax
	mov al, PlikDoZ[1]
	mov di, ax		;dlugosc odczytanego ciagu
	mov PlikDoZ[di+2], 0
	xor di, di
	lea dx, PlikDoZ + 2
	mov ax, 5b00h		;tworzenie nowego pliku
	xor cx, cx
	int 21h
	jc BladY
	mov UchwytZ, ax
	jmp Powrot1
ENDP

Zapisuj MACRO DlugoscC, NazwaC
	mov bx, UchwytZ
	mov ah, 40h
	mov cx, DlugoscC
	lea dx, NazwaC
	int 21h
	jc BladPrzyZ
ENDM

PobD MACRO adr
	mov si, adr
	call PobierzDane
	mov ah, 09h
	lea dx, DaneD1
	int 21h
ENDM

H2D MACRO
	call Hex2Dec
	mov ah, 09h
	lea dx, DaneD2
	int 21h
ENDM

SprawdzPlik PROC
	xor di, di
	mov ah, 3fh
	mov bx, Uchwyt
	mov cx, 256
	lea dx, Bufor
	int 21h
	cmp Bufor[0], 0e9h	;plik typu COM
	je PlikCOM
	cmp Bufor[0], 0ebh
	je PlikCOM
	cmp Bufor[0], 0b8h
	je PlikCOM
	cmp Bufor[0], 0bbh
	je PlikCOM
	cmp Bufor[0], 'M'
	jne Nieznany		;nieznany format pliku
	cmp Bufor[1], 'Z'
	jne Nieznany	
	mov ah, 09h
	lea dx, Kom9
	int 21h
	lea dx, Plik
	int 21h
	lea dx, KomA
	int 21h
	lea dx, Kom7
	int 21h
	cmp ZapisT, 1
	je ZapisEXE1
	jmp OminEXE1
ZapisEXE1:
	Zapisuj 13, Kom9
	Zapisuj DlNazwyPl, Plik
	Zapisuj 8, KomA
	Zapisuj 21, Kom7
OminEXE1:
	mov ah, 09h
	lea dx, Km1
	int 21h
	PobD 2
	H2D
	cmp ZapisT, 1
	je ZapisEXE2
	jmp OminEXE2
ZapisEXE2:
	Zapisuj 26, Km1
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXE2:
	mov ah, 09h
	lea dx, Km2
	int 21h
	PobD 4
	H2D
	cmp ZapisT, 1
	je ZapisEXE3
	jmp OminEXE3
ZapisEXE3:
	Zapisuj 56, Km2
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXE3:
	mov ah, 09h
	lea dx, Km3
	int 21h
	PobD 6
	H2D
	cmp ZapisT, 1
	je ZapisEXE4
	jmp OminEXE4
ZapisEXE4:
	Zapisuj 42, Km3
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXE4:
	mov ah, 09h
	lea dx, Km4
	int 21h
	PobD 8
	H2D
	cmp ZapisT, 1
	je ZapisEXE5
	jmp OminEXE5
ZapisEXE5:
	Zapisuj 32, Km4
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXE5:
	mov ah, 09h
	lea dx, Km5
	int 21h
	PobD 10
	H2D
	cmp ZapisT, 1
	je ZapisEXE6
	jmp OminEXE6
ZapisEXE6:
	Zapisuj 58, Km5
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXE6:
	mov ah, 09h
	lea dx, Km6
	int 21h
	PobD 12
	H2D
	cmp ZapisT, 1
	je ZapisEXE7
	jmp OminEXE7
ZapisEXE7:
	Zapisuj 59, Km6
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXE7:
	mov ah, 09h
	lea dx, Km7
	int 21h
	PobD 14
	H2D
	cmp ZapisT, 1
	je ZapisEXE8
	jmp OminEXE8
ZapisEXE8:
	Zapisuj 26, Km7
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXE8:
	mov ah, 09h
	lea dx, Km8
	int 21h
	PobD 16
	H2D
	cmp ZapisT, 1
	je ZapisEXE9
	jmp OminEXE9
ZapisEXE9:
	Zapisuj 41, Km8
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXE9:
	mov ah, 09h
	lea dx, Km9
	int 21h
	PobD 18
	H2D
	cmp ZapisT, 1
	je ZapisEXEA
	jmp OminEXEA
ZapisEXEA:
	Zapisuj 22, Km9
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXEA:
	mov ah, 09h
	lea dx, KmA
	int 21h
	PobD 20
	H2D
	cmp ZapisT, 1
	je ZapisEXEB
	jmp OminEXEB
ZapisEXEB:
	Zapisuj 41, KmA
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXEB:
	mov ah, 09h
	lea dx, KmB
	int 21h
	PobD 22
	H2D
	cmp ZapisT, 1
	je ZapisEXEC
	jmp OminEXEC
ZapisEXEC:
	Zapisuj 26, KmB
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXEC:
	mov ah, 09h
	lea dx, KmC
	int 21h
	PobD 24
	H2D
	cmp ZapisT, 1
	je ZapisEXED
	jmp OminEXED
ZapisEXED:
	Zapisuj 32, KmC
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXED:
	mov ah, 09h
	lea dx, KmD
	int 21h
	PobD 26
	H2D
	cmp ZapisT, 1
	je ZapisEXEE
	jmp OminEXEE
ZapisEXEE:
	Zapisuj 16, KmD
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OminEXEE:
	cmp WinT, 1
	je SprWin
	jmp NieSprW
SprWin:
	cmp Bufor[3ch], 0
	je NieMaWin
	xor ax, ax
	mov al, Bufor[3ch]	;pobierz przesuniecie naglowka programu Windows
	mov si, ax
	cmp Bufor[si], 'P'
	jne NoPE
	cmp Bufor[si+1], 'E'
	jne NoPE
	jmp JestWin
NoPE:
	cmp Bufor[si], 'N'
	jne NieMaWin
	cmp Bufor[si+1], 'E'
	jne NieMaWin
	mov ah, 09h
	lea dx, KmE
	int 21h
	lea dx, KmJ
	int 21h
	mov si, 3ch
	call PobierzDane
	call Hex2Dec
	mov ah, 09h
	lea dx, DaneD1
	int 21h
	lea dx, DaneD2
	int 21h
	cmp ZapisT, 1
	je Om2
	jmp NieSprW
Om2:
	Zapisuj 41, KmE
	Zapisuj 34, KmJ
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
	jmp NieSprW
JestWin:
	lea dx, KmE
	mov ah, 09h
	int 21h
	lea dx, KmJ
	int 21h
	mov si, 3ch
	call PobierzDane
	mov DlNazwyPl, bx	;zapisz adres naglowka
	call Hex2Dec
	mov si, bx
	mov ah, 09h
	lea dx, DaneD1
	int 21h
	lea dx, DaneD2
	int 21h
	cmp ZapisT, 0
	je OmZ
	Zapisuj 41, KmE
	Zapisuj 34, KmJ
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
OmZ:
	mov si, DlNazwyPl
	add si, 4
	mov DlNazwyPl, si	;zapisz wartosc SI
	call PobierzDane
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
	jmp POmin
PUnknown:
	lea dx, KmG
	int 21h
	lea dx, KmH1
	int 21h
	cmp ZapisT, 1
	je PUnknownZ
	jmp POmin
PUnknownZ:
	Zapisuj 49, KmG
	Zapisuj 11, KmH1
	jmp POmin
CPU386:
	lea dx, KmG
	int 21h
	lea dx, KmH2
	int 21h
	cmp ZapisT, 1
	je CPU386Z
	jmp POmin
CPU386Z:
	Zapisuj 49, KmG
	Zapisuj 8, KmH2
	jmp POmin
CPU486:
	lea dx, KmG
	int 21h
	lea dx, KmH3
	int 21h
	cmp ZapisT, 1
	je CPU486Z
	jmp POmin
CPU486Z:
	Zapisuj 49, KmG
	Zapisuj 8, KmH3
	jmp POmin
CPU586:
	lea dx, KmG
	int 21h
	lea dx, KmH4
	int 21h
	cmp ZapisT, 1
	je CPU586Z
	jmp POmin
CPU586Z:
	Zapisuj 49, KmG
	Zapisuj 8, KmH4
	jmp POmin
PMark1:
	lea dx, KmG
	int 21h
	lea dx, KmH5
	int 21h
	cmp ZapisT, 1
	je PMark1Z
	jmp POmin
PMark1Z:
	Zapisuj 49, KmG
	Zapisuj 29, KmH5
	jmp POmin
PMark2:
	lea dx, KmG
	int 21h
	lea dx, KmH6
	int 21h
	cmp ZapisT, 1
	je PMark2Z
	jmp POmin
PMark2Z:
	Zapisuj 49, KmG
	Zapisuj 23, KmH6
	jmp POmin
PMark3:
	lea dx, KmG
	int 21h
	lea dx, KmH7
	int 21h
	cmp ZapisT, 1
	je PMark3Z
	jmp POmin
PMark3Z:
	Zapisuj 49, KmG
	Zapisuj 24, KmH7
	jmp POmin
POmin:
	mov si, DlNazwyPl	;przywroc wartosc SI
	inc si
	inc si
	call PobierzDane
	call Hex2Dec
	mov ah, 09h
	lea dx, KmI
	int 21h
	lea dx, DaneD1
	int 21h
	lea dx, DaneD2
	int 21h
	cmp ZapisT, 1
	je POminZ
	jmp Om1
POminZ:
	Zapisuj 34, KmI
	Zapisuj DlDanych1, DaneD1
	Zapisuj DlDanych2, DaneD2
Om1:
	jmp NieSprW
NieMaWin:
	lea dx, KmF
	mov ah, 09h
	int 21h
	cmp ZapisT, 0
	je NieSprW
	Zapisuj 46, KmF
NieSprW:
	ret
Nieznany:
	mov ah, 09h
	lea dx, Kom9
	int 21h
	lea dx, Plik
	int 21h
	lea dx, KomA
	int 21h
	lea dx, Kom6
	int 21h
	cmp ZapisT, 1
	je ZapisNZ1
	jmp OminNZ1
ZapisNZ1:
	mov bx, UchwytZ
	Zapisuj 13, Kom9
	Zapisuj DlNazwyPl, Plik
	Zapisuj 8, KomA
	Zapisuj 31, Kom6
OminNZ1:
	jmp Koniec
PlikCOM:
	mov ah, 09h
	lea dx, Kom9
	int 21h	
	lea dx, Plik
	int 21h
	lea dx, KomA
	int 21h
	lea dx, Kom8
	int 21h
	cmp ZapisT, 1
	je ZapisCOM1
	jmp OminCOM1
ZapisCOM1:
	mov bx, UchwytZ
	Zapisuj 13, Kom9
	Zapisuj DlNazwyPl, Plik
	Zapisuj 8, KomA
	Zapisuj 21, Kom8
OminCOM1:
	jmp Koniec
BladPrzyZ:
	lea dx, BladZ
	mov ah, 09h
	int 21h
	jmp Koniec
ENDP

PobierzDane PROC
	xor cx, cx
	xor di, di
	mov bh, Bufor[si+1]
	mov bl, Bufor[si]
	xor ax, ax
	push bx
	mov dh, bh
	shr bh, 4
	cmp bh, 0
	je Dalej1
	mov al, bh
	mov si, ax
	mov bh, Tablica[si]
	mov DaneD1[di], bh
	inc cx
	inc di
	mov Flaga, 1
Dalej1:
	mov bh, dh
	and bh, 0fh
	cmp bh, 0
	je Dal2
	jmp ODal2
Dal2:
	cmp Flaga, 1
	je ODal2
	jmp Dalej2
ODal2:
	mov al, bh
	mov si, ax
	mov bh, Tablica[si]
	mov DaneD1[di], bh
	inc cx
	inc di
Dalej2:
	mov dh, bl
	shr bl, 4
	cmp bl, 0
	je Dal3
	jmp ODal3
Dal3:
	cmp Flaga, 1
	je ODal3
	jmp Dalej3
ODal3:
	mov al, bl
	mov si, ax
	mov bl, Tablica[si]
	mov DaneD1[di], bl
	inc cx
	inc di
Dalej3:
	mov bl, dh
	and bl, 0fh
	mov al, bl
	mov si, ax
	mov bl, Tablica[si]
	mov DaneD1[di], bl
	inc cx
	inc di
	pop bx
	mov DaneD1[di], 'h'
	inc di
	inc cx
	mov DaneD1[di], ' '
	inc di
	inc cx
	mov DaneD1[di], '$'
	xor si, si
	xor di, di
	mov DlDanych1, cx
	xor cx, cx
	mov Flaga, 0
	ret
ENDP

Hex2Dec PROC
	lea bp, DaneD2
	mov ax, bx
	cmp ax, 0
	jne DalejH2D
	mov byte ptr ds:[bp], 13
	mov byte ptr ds:[bp+1], 10
	mov byte ptr ds:[bp+2], '$'
	mov Dzielnik, 0
	jmp KoniecH2D
DalejH2D:
	mov Dzielnik, 10000
	xor dx, dx
H2D2:
	div Dzielnik
	push ax
	or al, Flaga
	pop ax
	jz ZapisH2D
	mov Flaga, 1
	add al, 30h
	mov ds:[bp], al
	inc bp
ZapisH2D:
	push dx
	xor dx, dx
	mov ax, Dzielnik
	mov bx, 10
	div bx
	mov Dzielnik, ax
	pop ax
KoniecH2D:
	cmp Dzielnik, 0
	jne H2D2
	mov byte ptr ds:[bp], 13
	mov byte ptr ds:[bp+1], 10
	mov byte ptr ds:[bp+2], '$'
	inc bp
	lea dx, DlDanych2
	sub bp, dx
	sub bp, 7
	mov DlDanych2, bp	;zapisz dlugosc ciagu znakow
	xor bp, bp
	xor dx, dx
	mov Flaga, 0
	ret
ENDP

ZamknijPliki PROC
	mov ah, 3eh
	mov bx, Uchwyt
	int 21h
	mov ah, 3eh
	mov bx, UchwytZ
	int 21h
	ret
ENDP

.data
	Kom0 db 'ExeInfo',13,10,'Copyright (C) 2001 Jakub Halun',13,10,'Program rozpoznaje typ pliku programu (COM/EXE)',13,10,'$'
	Kom1 db 'i jezeli jest to program EXE, podaje informacje na jego temat.',13,10,'$'
	Kom2 db 13,10,'EXEINFO [Dysk:][Sciezka]Nazwa_Pliku [/L:nazwa_pliku] [/W]',13,10,13,10,'$'
	Kom3 db '/L:nazwa_pliku - zapisuje wygenerowane przez program komunikaty do nazwa_pliku',13,10,'$'
	Kom5 db '/W - sprawdza, czy plik nie zawiera programu MS Windows',13,10,'$'
	Kom6 db 'Nierozpoznany format pliku.',13,10,13,10,'$'
	Kom7 db 'Program typu EXE.',13,10,13,10,'$'
	Kom8 db 'Program typu COM.',13,10,13,10,'$'
	Kom9 db 'NAZWA PLIKU: $'
	KomA db 'FORMAT: $'
	Km1 db 'Dlugosc ostatniej strony: $'
	Km2 db 'Dlugosc programu razem z naglowkiem w stronach (512 B): $'
	Km3 db 'Liczba elementow w tablicy przemieszczen: $'
	Km4 db 'Rozmiar naglowka w paragrafach: $'
	Km5 db 'Minimalna pamiec potrzebna ponad program (w paragrafach): $'
	Km6 db 'Maksymalna pamiec potrzebna ponad program (w paragrafach): $'
	Km7 db 'Przesuniecie segmentu SS: $'
	Km8 db 'Wartosc rejestru SP na poczatku procesu: $'
	Km9 db 'Suma kontrolna pliku: $'
	KmA db 'Wartosc rejestru IP na poczatku procesu: $'
	KmB db 'Przesuniecie segmentu CS: $'
	KmC db 'Poczatek tablicy przemieszczen: $'
	KmD db 'Numer nakladki: $'
	KmE db 13,10,'Plik zawiera program typu MS Windows.',13,10,'$'
	KmF db 13,10,'Plik nie zawiera programu typu MS Windows.',13,10,'$'
	KmG db 'Typ procesora wymagany przez program MS Windows: $'
	KmH1 db 'nieznany.',13,10,'$'
	KmH2 db '80386.',13,10,'$'
	KmH3 db '80486.',13,10,'$'
	KmH4 db '80586.',13,10,'$'
	KmH5 db 'MIPS Mark I (R2000, R3000).',13,10,'$'
	KmH6 db 'MIPS Mark II (R6000).',13,10,'$'
	KmH7 db 'MIPS Mark III (R4000).',13,10,'$'
	KmI db 'Liczba wpisow w tablicy obiektow: $'
	KmJ db 'Offset naglowka programu Windows: $'
	Tablica db '0123456789ABCDEF'
	Bufor db 256 dup(?)
	RozneOdZ  db 0
	DlNazwyPl dw 0
	DlDanych1 dw 0
	DlDanych2 dw 0
	DaneD1 db 6 dup(0)
	DaneD2 db 12 dup(0)
	PlikDoZ db 128 dup(0)
	Plik db 128 dup(0)
	Dzielnik dw ?
	Flaga db 0
	Uchwyt dw ?
	UchwytZ dw ?
	Blad0 db 'Blad. $'
	Blad00 db 'Blad pliku do zapisu (LOG). $'
	Blad80 db 'Plik do zapisu juz istnieje. Nadpisac istniejacy plik T/N',13,10,'$'
	Kom80 db 'Podaj nowa nazwe dla tworzonego pliku: $'
	Blad2 db 'Brak pliku o podanej nazwie.',13,10,'$'
	Blad3 db 'Nie znaleziono sciezki dostepu.',13,10,'$'
	Blad4 db 'Za duzo plikow otwartych rownoczesnie.',13,10,'$'
	Blad5 db 'Brak uprawnien dostepu do pliku.',13,10,'$'
	BladZ db 'Blad przy zapisie do pliku.',13,10,'$'
	WinT db ?
	ZapisT db 0
End Start

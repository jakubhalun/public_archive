;* IPX Nadajnik/Odbiornik - Program nadawczy
;* 2001 by Jakub Halun
;* http://halun.pl

.model small
jumps
.stack 64
.code
Start:
	mov ax, @data
	mov ds, ax
	call SprawdzIPX
	call Wysylaj
Koniec:
	mov bx, 1h
	mov dx, 7777h
	int 7ah			;zamknij koncowke
	mov ax, 4c00h
	int 21h			;zamknij program

Wysylaj PROC
	mov ah, 09h
	lea dx, KomI1
	int 21h
	lea dx, KomI2
	int 21h
	lea dx, KomI3
	int 21h
Wysyl:
	mov di, 256
WyczyscNazwa:
	mov Nazwa[di], 0	;wyzeruj bufor Nazwa
	dec di
	jz KWyczyscNazwa
	jmp WyczyscNazwa
KWyczyscNazwa:
	mov ah, 09h
	lea dx, Kom8
	int 21h
	mov ah, 0ah
	mov Nazwa[0], 128
	lea dx, Nazwa
	int 21h			;pobierz nazwe pliku do wyslania
	xor ax, ax
	mov al, Nazwa[1]
	mov di, ax
	mov si, ax
	mov Nazwa[di+2], 0
	xor di, di
	mov ah, 09h
	lea dx, Kom8
	sub dx, 3
	int 21h			;przejdz do nastepnej linii
	mov ax, 3d00h	
	lea dx, Nazwa + 2
	int 21h
	jc BladOtwPliku
	mov Uchwyt, ax
	add si, 2
UsuwajS:
	cmp byte ptr Nazwa[si], '\'	;usun ewentualna sciezke z nazwy pliku
	je UsunSc1
	cmp byte ptr Nazwa[si], ':'
	je UsunSc1
	dec si
	cmp si, 2
	je UsunSc2
	jmp UsuwajS
UsunSc1:
	inc si 
UsunSc2:
	mov al, Nazwa[si]
	mov Pakiet.Dane[di], al
	inc si
	inc di
	cmp al, 0
	je KUsunSc
	jmp UsunSc2
KUsunSc:
	xor si, si
	add di, 30
	mov DlugoscD, di
	xor di, di

	mov ax, 4202h
	xor cx, cx
	xor dx, dx
	mov bx, Uchwyt
	int 21h				;sprawdz wielkosc pliku
	mov IloscP, 546
	div IloscP
	add ax, 3
	mov IloscP, ax			;i zachowaj jako liczbe wysylanych pakietow
	mov ax, 4200h
	mov bx, Uchwyt
	xor cx, cx
	xor dx, dx
	int 21h				;wroc na poczatek pliku
	mov PIloscP, 0

	call PrzygDoNadaw
	mov ah, 09h
	lea dx, KomA
	int 21h
	call WyslijPakiet
	mov ah, 09h
	lea dx, KomB
	int 21h
	call PrzygDoOdbioru
	call OdbierzPakiet
	cmp Pakiet.Dane[0], 1
	je Odmowa
	jmp Przesyl
Odmowa:
	mov ah, 09h
	lea dx, Kom6
	int 21h
	jmp ZakWy
Przesyl:
	mov di, 128			;opoznienie przesylania pakietow
Opoznij1:				;jezeli masz procesor o czestotliwosci
	mov cx, 0ffffh			;taktowania mniejszej niz 200 MHz,
Opoznij2:				;zmniejsz ta wartosc
	dec cx
	jnz Opoznij2
	dec di
	jnz Opoznij1
	mov ah, 3fh
	mov bx, Uchwyt
	mov cx, 546
	lea dx, Pakiet.Dane
	int 21h
	cmp ax, 0			;jezeli pobrano 0 bajtow (koniec pliku)
	je KPrzesyl			;zakoncz transmisje
	add ax, 30
	mov DlugoscD, ax
	call PrzygDoNadaw
	call WyslijPakiet
	jmp Przesyl
KPrzesyl:
	mov Pakiet.Dane[0], 3		;pakiet zawierajacy taki lancuch znakow
	mov Pakiet.Dane[1], 6		;bedzie dla odbiornika sygnalem
	mov Pakiet.Dane[2], 9		;informujacym o zakonczeniu transmisji
	mov Pakiet.Dane[3], '~'		;pliku
	mov Pakiet.Dane[4], 66
	mov DlugoscD, 35
	call PrzygDoNadaw
	call WyslijPakiet
ZakWy:
	mov ah, 3eh
	mov bx, Uchwyt
	int 21h
ZakonczWy:
	mov ah, 09h
	lea dx, KomC
	int 21h
CzytajZnak:
	mov ah, 07h
	int 21h
	cmp al, 116
	je Koniec
	cmp al, 110
	je Wysyl
	jmp CzytajZnak
	ret
BladOtwPliku:
	cmp ax, 2
	je Blad2
	cmp ax, 3
	je Blad3
	cmp ax, 4
	je Blad4
	cmp ax, 5
	je Blad5
	jmp ZakonczWy
Blad2:
	mov ah, 09h
	lea dx, Kom92
	int 21h
	jmp ZakonczWy
Blad3:
	mov ah, 09h
	lea dx, Kom93
	int 21h
	jmp ZakonczWy
Blad4:
	mov ah, 09h
	lea dx, Kom94
	int 21h
	jmp ZakonczWy
Blad5:
	mov ah, 09h
	lea dx, Kom95
	int 21h
	jmp ZakonczWy
ENDP

PrzygDoNadaw PROC
	lea si, Pakiet.Siec_Zrodlowa
	push ds
	pop es
	mov bx, 9
	int 7ah					;ustal adresy lokalne
	mov Pakiet.Suma_Kontrolna, 0ffffh
	mov ax, DlugoscD
	mov Pakiet.Dlugosc_Pakietu, ax
	mov Pakiet.Typ_Pakietu, 0
	mov cx, 4
	xor di, di
PetlaZ1:
	mov Prz_Robocza_IPX[di], 0
	mov Pakiet.Siec_Docelowa[di], 0
	mov ECB.Lacze[di], 0
	mov ECB.PodPr_Obs_zd[di], 0
	inc di
	dec cx
	jz KPetlaZ1
	jmp PetlaZ1
KPetlaZ1:
	mov cx, 6
	xor di, di
PetlaZ2:
	mov ECB.Adres_Docelowy[di], 0ffh
	mov Pakiet.Wezel_Docelowy[di], 0ffh
	inc di
	dec cx
	jz KPetlaZ2
	jmp PetlaZ2
KPetlaZ2:
	xor di, di
	mov cx, 12
PetlaZ3:
	mov ECB.Prz_Robocza_St[di], 0
	inc di
	dec cx
	jz KPetlaZ3
	jmp PetlaZ3
KPetlaZ3:
	mov Pakiet.Kontrola_Transportu, 0
	mov Pakiet.Proces_Docelowy, 7777h
	mov Pakiet.Proces_Zrodlowy, 7777h
	mov ECB.Nr_Procesu, 7777h
	mov ECB.Liczba_Frag, 1
	mov ECB.Zakonczenie, 0
	mov ECB.Fl_Kontrolna, 0
	mov ax, DlugoscD
	mov ECB.Rozmiar_Lokalny, ax
	mov ax, ds
	mov ECB.Adres_Lokalny[3], ah
	mov ECB.Adres_Lokalny[2], al
	lea ax, Pakiet
	mov ECB.Adres_Lokalny[1], ah
	mov ECB.Adres_Lokalny[0], al
	ret
ENDP

SprawdzIPX PROC
	mov ax, 7a00h
	int 2fh				;sprawdz, czy IPX zainstalowany
	cmp al, 0ffh
	jne BrakIPX
	xor ax, ax
	mov dx, 7777h			;przyznaj numer procesu 7777h
	xor bx, bx
	int 7ah
	cmp al,	0
	jne BladNrPr
	ret
BrakIPX:
	mov ah, 09h
	lea dx, Kom0
	int 21h
	jmp Koniec
BladNrPr:
	mov ah, 09h
	lea dx, Kom7
	int 21h
	jmp Koniec
ENDP

WyslijPakiet PROC
	mov ah, 09h
	lea dx, Kom4
	int 21h
	mov bx, 0003h
	lea si, ECB
	int 7ah
PetlaW:
	mov bx, 000ah
	int 7ah
	lea si, ECB.Fl_Kontrolna
	cmp byte ptr es:[si], 0
	jne PetlaW
	inc PIloscP
	mov bx, PIloscP
	call Hex2Dec
	mov ah, 09h
	lea dx, KomE
	int 21h
	lea dx, KomG
	int 21h
	mov bx, IloscP
	call Hex2Dec
	mov ah, 09h
	lea dx, KomE
	int 21h
	lea dx, KomF
	int 21h
NieWyN:
	lea dx, Kom5
	int 21h
	ret
ENDP

PrzygDoOdbioru PROC
	xor si, si
	xor di, di
	mov ECB.Zakonczenie, 0
	mov ECB.Fl_Kontrolna, 1dh
	mov ECB.Nr_Procesu, 7777h
	mov ECB.Liczba_Frag, 1
	mov ax, ds
	mov ECB.Adres_Lokalny[3], ah
	mov ECB.Adres_Lokalny[2], al
	lea ax, Pakiet
	mov ECB.Adres_Lokalny[1], ah
	mov ECB.Adres_Lokalny[0], al
	mov ECB.Rozmiar_Lokalny, 576
	mov Pakiet.Suma_Kontrolna, 0
	mov Pakiet.Dlugosc_Pakietu, 0
	mov Pakiet.Kontrola_Transportu, 0
	mov Pakiet.Typ_Pakietu, 0
	mov Pakiet.Proces_Docelowy, 0
	mov Pakiet.Proces_Zrodlowy, 0
	mov cx, 4
	xor di, di
UOdbPetla1:
	mov Pakiet.Siec_Docelowa[di], 0
	mov Pakiet.Siec_Zrodlowa[di], 0
	mov ECB.Lacze[di], 0
	mov ECB.Podpr_Obs_Zd[di], 0
	mov ECB.Prz_Robocza_IPX[di], 0
	inc di
	dec cx
	jz UOdbPetla1K
	jmp UOdbPetla1	
UOdbPetla1K:
	xor di, di
	mov cx, 6
UOdbPetla2:
	mov ECB.Adres_Docelowy[di], 0 
	mov Pakiet.Wezel_Docelowy[di], 0
	mov Pakiet.Wezel_Zrodlowy[di], 0
	inc di
	dec cx
	jz UOdbPetla2K
	jmp UOdbPetla2
UOdbPetla2K:
	xor di, di
	mov cx, 12
UOdbPetla3:
	mov ECB.Prz_Robocza_IPX[di], 0
	inc di
	dec cx
	jz UOdbPetla3K
	jmp UOdbPetla3
UOdbPetla3K:
	ret
ENDP

OdbierzPakiet PROC
	mov bx, 4
	push ds
	pop es
	lea si, ECB
	int 7ah
PetlaO:
	mov bx, 0ah
	int 7ah
	lea si, ECB.Fl_Kontrolna
	cmp byte ptr es:[si], 0
	jne PetlaO
	mov ah, 09h
	lea dx, KomD
	sub dx, 3
	int 21h
	ret
ENDP

Hex2Dec PROC
	lea bp, KomE
	mov ax, bx

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
	mov byte ptr ds:[bp], '$'
	xor bp, bp
	xor dx, dx
	xor ax, ax
	mov Flaga, 0
	ret
ENDP

.data
	Kom0 db 'Blad. Sterownik IPX nie jest zainstalowany w systemie.',13,10,'$'
	Kom1 db 'Blad. Nie mozna wyslac pakietu.',13,10,'$'
	Kom2 db 'Podaj nazwe pliku: $'
	Kom3 db 'Zakonczyc prace programu? T/N',13,10,'$'
	Kom4 db 'Wysylanie pakietu $'
	Kom5 db ' OK',13,10,'$'
	Kom6 db 'Blad. Odbiornik nie moze przyjac pliku.',13,10,'$'
	Kom7 db 'Blad przy realizacji przyznania numeru procesu.',13,10,'$'
	KomI1 db 'IPX Nadajnik/Odbiornik',13,10,'$'
	KomI2 db 'Program nadawczy',13,10,'$'
	KomI3 db 'Copyright (c) 2001 Jakub Halun',13,10,13,10,'$'
	Kom8 db 'Podaj nazwe pliku do wyslania.',13,10,'(maksymalnie 128 znakow wraz ze sciezka): $'
	Kom9 db 'Plik zostal otwarty bez bledow.',13,10,'$'
	Kom92 db 'Blad. Brak pliku o podanej nazwie.',13,10,'$'
	Kom93 db 'Blad. Nie znaleziona sciezka dostepu.',13,10,'$'
	Kom94 db 'Blad. Zbyt wiele plikow otwartych rownoczesnie.',13,10,'$'
	Kom95 db 'Blad. Brak uprawnien do otwarcia pliku.',13,10,'$'
	KomA db 'Przeslanie informacji do odbiornika.',13,10,'$'
	KomB db 'Oczekiwanie na odpowiedz odbiornika...$'
	KomC db 'Zakonczyc prace programu T/N',13,10,'$'
	KomD db 13,10,'Odbiornik gotowy do odebrania pliku.',13,10,'$'
	KomE db 32 dup(?)
	KomG db ' z $'
	KomF db '... $'
	IPXSeg dw ?
	IPXOffs dw ?
	Uchwyt dw 0
	DlugoscD dw ?
	Nazwa db 130 dup(0)
	DlugoscC dw ?
	IloscP dw 546
	PIloscP dw ?
	Dzielnik dw ?
	Flaga db 0
	PakietIPX STRUC
		Suma_Kontrolna dw 0
		Dlugosc_Pakietu dw 0
		Kontrola_Transportu db 0
		Typ_Pakietu db 0
		Siec_Docelowa db 4 dup(0)
		Wezel_Docelowy db 6 dup(0)
		Proces_Docelowy dw 0
		Siec_Zrodlowa db 4 dup(0)
		Wezel_Zrodlowy db 6 dup(0)
		Proces_Zrodlowy dw 0
		Dane db 546 dup(0)
	PakietIPX ENDS
	Pakiet PakietIPX ?
	BlokECB	STRUC
		Lacze db 4 dup(0)
		Podpr_Obs_Zd db 4 dup(0)
		Fl_Kontrolna db 0
		Zakonczenie db 0
		Nr_Procesu dw 0
		Prz_Robocza_IPX db 4 dup(0)
		Prz_Robocza_St db 12 dup(0)
		Adres_Docelowy db 6 dup(0)	;adres wezla docelowego
		Liczba_Frag dw 0
		Adres_Lokalny db 4 dup(0)	;adres pakietu IPX
		Rozmiar_Lokalny dw 0		;rozmiar pakietu IPX
	BlokECB ENDS
	ECB BlokECB ?
End Start
;* IPX Nadajnik/Odbiornik - Program odbiorczy
;* 2001 by Jakub Halun
;* http://halun.pl

.model small
.stack 64
jumps
.code
Start:
	mov ax, @data
	mov ds, ax
	call SprawdzIPX
	call Odbieraj
Koniec:
	mov bx, 1
	mov dx, 7777h			;zamknij koncowke
	int 7ah
	mov ax, 4c00h
	int 21h

Odbieraj PROC
	mov ah, 09h
	lea dx, KomI1
	int 21h
	lea dx, KomI2
	int 21h
	lea dx, KomI3
	int 21h
Odbieranie:
	mov ah, 09h
	lea dx, Kom5
	int 21h
	call PrzygDoOdbioru
	call OdbierzPakiet
	mov cx, 60
	xor si, si
	xor di, di
KopiujNazwe:
	mov al, Pakiet.Dane[si]		;kopiuj nazwe pliku z odebranego pakietu do bufora Kom2
	cmp al, 0			;bedzie on sluzyl wyswietleniu tej nazwy
	je KKopiujNazwe
	mov Kom2[di], al
	inc si
	inc di
	dec cx
	jz KKopiujNazwe
	jmp KopiujNazwe	
KKopiujNazwe:
	mov Kom2[di], 13
	mov Kom2[di+1], 10
	mov Kom2[di+2], '$'
	xor si, si
	xor di, di
	mov ah, 09h
	lea dx, Kom1
	int 21h
	lea dx, Kom2
	int 21h
	lea dx, Kom7
	int 21h

CzytajZnak1:
	mov ah, 07h
	int 21h
	cmp al, 116
	je OdbTak
	cmp al, 110
	je OdbNie
	jmp CzytajZnak1
OdbTak:
	mov ah, 5bh
	lea dx, Pakiet.Dane
	xor cx, cx
	int 21h
	jc BladZapPliku
	mov Uchwyt, ax
OdbTak2:
	mov Pakiet.Dane[0], 0		;jezeli program ma odebrac plik
	mov DlugoscD, 31		;wyslij do nadajnika pakiet zawierajacy
	mov ah, 09h			;0 na zerowym bajcie pola danych
	lea dx, Kom4			;bedzie to sygnal gotowosci do odbioru pliku
	int 21h
	lea dx, KomA
	int 21h
	call PrzygDoNadaw
	call WyslijPakiet
Odb:
	call PrzygDoOdbioru
	call OdbierzPakiet
	cmp Pakiet.Dane[0], 3		;sprawdz czy nie pakiet koncowy (zawiera
	jne OdbDalej			;lancuch znakow: 3,6,9,'~',66)
	cmp Pakiet.Dane[1], 6
	jne OdbDalej
	cmp Pakiet.Dane[2], 9
	jne OdbDalej
	cmp Pakiet.Dane[3], '~'
	jne OdbDalej
	cmp Pakiet.Dane[4], 66
	jne OdbDalej
	jmp ZakOdb
OdbDalej:
	mov ah, 40h
	mov bx, Uchwyt
	lea dx, Pakiet.Dane
	mov cx, Pakiet.Dlugosc_Pakietu
	xchg ch, cl			;zmien format z Hi-Low(stosowany miedzy innymi
	sub cx, 30			;w naglowku pakietu IPX) na Low-Hi (standard Intela)
	int 21h				;i zapisz dane o takiej dlugosci (po odjeciu dlugosci
	jmp Odb				;naglowka) do pliku
OdbNie:
	mov Pakiet.Dane[0], 1		;jezeli program ma nie odbierac pliku wyslij
	mov DlugoscD, 31		;do nadajnika pakiet z 1 na zerowym bajcie pola danych
	call PrzygDoNadaw
	call WyslijPakiet
	jmp ZakonczOdb
BladZapPliku:
	cmp ax, 80
	jne InnyBladZ
	mov ah, 09h
	lea dx, Kom2A
	int 21h
	lea dx, Kom2B
	int 21h
CzytajZnak2:
	mov ah, 07h
	int 21h
	cmp al, 116
	je Nadpisz
	cmp al, 110
	je NieNadpisz
	jmp CzytajZnak2
Nadpisz:
	mov ah, 3ch
	lea dx, Pakiet.Dane
	xor cx, cx
	int 21h
	jc BladZapPliku
	mov Uchwyt, ax
	jmp OdbTak2
NieNadpisz:
	mov ah, 09h
	lea dx, Kom9
	int 21h
	mov ah, 0ah		;odczyt wiersza z klawiatury
	mov Nazwa[0], 128	;maksymalna dlugosc lancucha znakow
	lea dx, Nazwa
	int 21h
	xor ax, ax
	mov al, Nazwa[1]
	mov di, ax		;dlugosc odczytanego ciagu
	mov Nazwa[di+2], 0
	xor di, di
	lea dx, Nazwa + 2
	mov ax, 5b00h		;tworzenie nowego pliku
	xor cx, cx
	int 21h
	jc BladZapPliku
	mov Uchwyt, ax
	mov ah, 09h
	lea dx, Kom9
	sub dx, 3
	int 21h
	jmp OdbTak2
InnyBladZ:
	mov ah, 09h
	lea dx, Kom8
	int 21h
	jmp OdbNie
ZakOdb:
	mov ah, 09
	lea dx, KomB
	int 21h
ZakonczOdb:
	mov ah, 3eh
	mov bx, Uchwyt
	int 21h
	mov ah, 09h
	lea dx, Kom3
	int 21h
CzytajZnak3:
	mov ah, 07h
	int 21h
	cmp al, 116
	je KoniecPr
	cmp al, 110
	je Odbieranie
	jmp CzytajZnak3
KoniecPr:
	ret
ENDP


PrzygDoOdbioru PROC
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
	mov Pakiet.Dlugosc_Pakietu, 0		;przy odbiorze wszystkie pola naglowka IPX
	mov Pakiet.Kontrola_Transportu, 0	;wyzerowane
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


SprawdzIPX PROC
	mov ax, 7a00h
	int 2fh				;sprawdz, czy IPX zainstalowany
	cmp al, 0ffh
	jne BrakIPX
	xor bx, bx
	xor ax, ax
	mov dx, 7777h
	int 7ah				;otworz koncowke o numerze 7777h
	cmp ax, 0
	jne BladKon
	ret
BrakIPX:
	mov ah, 09h
	lea dx, Kom0
	int 21h
	jmp Koniec
BladKon:
	mov ah, 09h
	lea dx, Kom6
	int 21h
	jmp Koniec
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
	ret
ENDP


PrzygDoNadaw PROC
	lea si, Pakiet.Siec_Zrodlowa
	push ds
	pop es
	mov bx, 9
	int 7ah				;ustal adresy lokalne
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


WyslijPakiet PROC
	mov bx, 0003h
	lea si, ECB
	int 7ah
PetlaW:
	mov bx, 000ah
	int 7ah
	lea si, ECB.Fl_Kontrolna
	cmp byte ptr es:[si], 0
	jne PetlaW
	ret
ENDP


.data
	Kom0 db 'Blad. Sterownik IPX nie jest zainstalowany w systemie.',13,10,'$'
	Kom1 db 'Odbior pliku: $'
	Kom2 db 64 dup(?)
	Kom2A db 'Blad. Plik o takiej nazwie juz istnieje.',13,10,'$'
	Kom2B db 'Nadpisac istniejacy plik? T/N',13,10,'$'
	Kom3 db 'Zakonczyc prace programu? T/N',13,10,'$'
	Kom4 db 'Potwierdzenie wyslane do nadajnika.',13,10,'$'
	Kom5 db 'Oczekiwanie na transmisje nadajnika...',13,10,'$'
	Kom6 db 'Blad podczas otwierania koncowki.',13,10,'$'
	Kom7 db 'Odebrac plik? T/N',13,10,'$'
	Kom8 db 'Blad przy zapisie pliku.',13,10,'$'
	Kom9 db 'Podaj nowa nazwe dla pliku: ',13,10,'$'
	KomI1 db 'IPX Nadajnik/Odbiornik',13,10,'$'
	KomI2 db 'Program odbiorczy',13,10,'$'
	KomI3 db 'Copyright (c) 2001 Jakub Halun',13,10,13,10,'$'
	KomA db 'Odbior pliku... $'
	KomB db ' OK',13,10,'$'
	Nazwa db 128 dup(?)
	DlugoscD dw ?
	Uchwyt dw ?
	BlokECB	STRUC				;przed inicjalizacja, wszystkie pola
		Lacze db 4 dup(0)		;bloku kontroli transmisji ECB i naglowka
		Podpr_Obs_Zd db 4 dup(0)	;pakietu IPX musza byc wyzerowane
		Fl_Kontrolna db 0
		Zakonczenie db 0
		Nr_Procesu dw 0
		Prz_Robocza_IPX db 4 dup(0)
		Prz_Robocza_St db 12 dup(0)
		Adres_Docelowy db 6 dup(0)	;adres wezla docelowego
		Liczba_Frag dw 0	;1 jezeli naglowek i dane pakietu w jednej strukturze
		Adres_Lokalny db 4 dup(0)	;adres pakietu IPX
		Rozmiar_Lokalny dw 0		;rozmiar pakietu IPX
	BlokECB ENDS
	ECB BlokECB ?
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
End Start
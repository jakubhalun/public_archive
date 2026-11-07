;********************************************************************
;*     FF.ASM - FILE FIND - program do wyszukiwania plikow na dysku *
;*     Copyright (C) 2000 Jakub Halun				    *
;*     www.yaqb.prv.pl						    *
;********************************************************************
.model small
.stack 512
.data
	DojscieDoPlikZ dw ?		;uchwyt do pliku do zapisu
	DlLiniiParam db ?
	ZmienDysk db 0
	Dysk db ?
	Plik db 15 dup (?)
	PlikDoZapisu db 15 dup (?)
	Dyski1 db 'abcdefghijklmnopqrstuvwxyz'
	Dyski2 db 'ABCDEFGHIJKLMNOPRQSTUVWXYZ'
	NazwaPliku db 13 dup (?)
	DlNazwyPliku dw ?
	Data db 9 dup (?)
	Czas db 9 dup (?)
	AtrCiag db 8 dup (?)
	KatalogB db 64 dup (?)
	NastepnaLinia db 13,10,'$'
	DyskBiezacy db ?	;zapamietuje nr. dysku biezacego jezeli zmieniany
	Katalog db 64 dup (?)
	ZachBKatalog db 64 dup (?)
	Kat db '\','$'
	WszystkiePl db '*.*', 0
	KatalogWyzej db 64 dup (?)
	KatalogW db 64 dup (?)
	AtrB db ?
	RozmiarB db 4 dup (?)
	DataB dw ?
	CzasB dw ?
	Wroc db 0
	DlSciezki dw ?
	KatalG db 0
	Info db 'FILE FIND wersja 1.0  Copyright (C) 2000 Jakub Halun',13,10,'$'
	Kom0 db 'Program wyszukuje na dysku pliki o zadanych parametrach',13,10,13,10,'$'
	Kom1 db 'FF [dysk:] nazwa_pliku [/L:PLIK] [/U] [/S] [/K] [/B]',13,10,13,10,'$'
	Kom2 db '[dysk:] - okresla dysk do przeszukania',13,10,'$'
	Kom3 db 'nazwa_pliku - okresla plik do wyszukania', 13,10,13,10,'$'
	Kom4 db '/L - zachowuje wyniki przeszukiwania dysku do PLIK',13,10,13,10,'$'
	Kom5 db '/U - wyszukuje rowniez pliki ukryte',13,10,'$'
	Kom6 db '/S - wyszukuje rowniez pliki systemowe',13,10,'$'
	Kom9 db '/K - wyszukuje rowniez podkatalogi',13,10,13,10,'$'
	KomB db '/B - przeszukuje wylacznie biezacy katalog',13,10,'$'
	KomC db 'Blad: plik podany przy parametrze /L juz istnieje',13,10,'$'
	KomD db 'Niewlasciwe parametry. Nie podano nazwy pliku do zapisu',13,10,13,10,'$'
	KomE db 'Niewlasciwe parametry. Niewlasciwe okreslenie dysku',13,10,13,10,'$'
	KomF db 'Niewlasciwe parametry. Brak nazwy pliku do wyszukania',13,10,13,10,'$'
	KomG db 'Niewlasciwe parametry. Nazwa pliku do zapisu zawiera zbyt wiele znakow',13,10,13,10,'$'
	KomH db 'Niewlasciwe parametry. Nazwa pliku do wyszukania zawiera zbyt wiele znakow',13,10,13,10,'$'
	KomI db 'Blad: nie mozna utworzyc pliku do zapisu',13,10,13,10,'$'
  	KomJ db 'Tworzony plik juz istnieje. Nadpisac istniejacy plik? T/N',13,10,'$'
	KomK db 'Podaj nowa nazwe dla tworzonego pliku...',13,10,'$'
	KomL db 'NAZWA PLIKU   -   DATA   -   CZAS   - ATRYBUTY',13,10,13,10,'$'
	KomM db 'Blad zapisu do pliku. Program zostanie zakonczony',13,10,'$'
	KomN db 'Nie znaleziono zadnego pliku odpowiadajacego wzorcowi',13,10,'$'
	Przerwa db ' - ','$'
	Parametry db 256 dup (?)
	Atrybuty db 0		;okresla, czy program ma zwracac uwage na atrybuty
	TylkoBiezacy db 0	;czy tylko biezacy katalog 1=tak
	Atrybut dw 0		;atrybuty pliku
	Atr2 dw 0
	Zapis db 0
	Znaleziony db 0
	KatWyswietlony db 0
	TenSam db 0

.code
Pomoc PROC
	mov ah, 09h
	lea dx, Info
	int 21h
	lea dx, Kom0
	int 21h
	lea dx, Kom1
	int 21h
	lea dx, Kom2
	int 21h
	lea dx, Kom3
	int 21h
	lea dx, Kom4
	int 21h
	lea dx, Kom5
	int 21h
	lea dx, Kom6
	int 21h
	lea dx, Kom9
	int 21h
	lea dx, KomB
	int 21h
	jmp Koniec
	ret
ENDP


CzySaParametry PROC
	mov ah, 62h
	int 21h
	mov es, bx		;zaladuj adres bloku PSP do ES
	mov bl, es:[0080h]	;pobierz dlugosc linii parametrow
	cmp bl, 0		;i sprawdz, czy nie jest rowna 0
	jne SaParametry
	call Pomoc		;jezeli nie ma parametrow wyswietl pomoc
SaParametry:
	mov DlLiniiParam, bl	;zapamietaj dlugosc linii parametrow
	ret
ENDP


PobierzParametry PROC
	mov si, 81h		;zaladuj przesuniecie linii parametrow
	xor cx, cx
	mov cl, DlLiniiParam	;zaladuj dlugosc linii parametrow
	lea di, Parametry	;zaladuj przesuniecie tablicy parametry
Petla1:				;skopiuj zawartosc linii parametrow do tablicy
	mov al, es:[si]
	mov ds:[di], al
	inc di
	inc si
	dec cx
	jcxz Sprawdzaj
	jmp Petla1
Sprawdzaj:
	mov cl, DlLiniiParam	;sprawdzanie parametrow
	xor si, si
	xor di, di
	xor bx, bx		;w rejestrze BX, beda przechowywane atrybuty
	jumps
	jmp SprPetla
PomocX:	call Pomoc
SprPetla:
	mov ah, Parametry[si]
	mov al, Parametry[si+1]
	cmp ax, '/?'
	je PomocX
	cmp ax, '/H'
	je PomocX
	cmp ax, '/h'
	je PomocX
	cmp ax, '/u'
	je UkryteP
	cmp ax, '/U'
	je UkryteP
	cmp ax, '/s'
	je SystemoweP
	cmp ax, '/S'
	je SystemoweP
	cmp ax, '/k'
	je PodkatalogiP
	cmp ax, '/K'
	je PodkatalogiP
	cmp ax, '/b'	
	je TBiezacy
	cmp ax, '/B'
	je Tbiezacy
	cmp ax, '/l'
	je ZapisP
	cmp ax, '/L'
	je ZapisP
	inc si
	loop SprPetla
	jmp KoniecP
UkryteP:
	inc si
	dec cx
	mov Atrybuty, 1
	or bx, 2h			;bit1=1 plik ukryty
	jmp SprPetla
SystemoweP:
	inc si
	dec cx
	mov Atrybuty, 1
	or bx, 4h			;bit2=1 plik systemowy
	jmp SprPetla
PodkatalogiP:
	inc si
	dec cx
	mov Atrybuty, 1
	or bx, 10h
	jmp SprPetla
TBiezacy:
	inc si
	dec cx
	mov TylkoBiezacy, 1
	jmp SprPetla
ZapisP:
	mov Zapis, 1
	xor ax, ax
	add si, 2
	sub cx, 2
	mov al, Parametry[si]
	cmp al, ':'
	jne BladP
	inc si
	dec cx
	mov al, Parametry[si]
	cmp al, ' '
	je BladP
	xor di, di
ZapisPPetla:
	mov al, Parametry[si]
	cmp al, ' '
	je SprPetla
	cmp ah, 12
	ja ZaDlugaNPDoZ			;skok gdy wiekszy od dwunastu
	cmp cl, 0
	je KoniecP			;skok gdy rowny zero(koniec l. param.)
	mov PlikDoZapisu[di], al
	mov PlikDoZapisu[di+1], 0	;zaladuj na koniec nazwy pliku znak 0
	inc di
	inc si
	inc ah				;zlicza dlugosci nazwy
	dec cx
	jmp ZapisPPetla
ZaDlugaNPDoZ:
	lea dx, KomG
	mov ah, 09h
	int 21h
	jmp Koniec
BladP:
	lea dx, KomD
	mov ah, 09h
	int 21h
	jmp Koniec
KoniecP:
	mov Atrybut, bx
	or bx, 10h
	mov Atr2, bx
	ret
ENDP


PobierzNazwePliku PROC
	xor cx, cx
	mov cl, DlLiniiParam
	xor si, si
	xor di, di
SprPetla2:
	mov al, Parametry[si]
	cmp al, ':'
	je LadujNazweDysku
	cmp al, '/'
	je NieMaNazwyDysku
	inc si
	loop SprPetla2
	jmp NieMaNazwyDysku
LadujNazweDysku:
	mov al, Parametry[si-1]
	mov ZmienDysk, 1
	inc si
	dec cx
	jmp NumerDysku
BladNazwyDysku:
	mov ah, 09h
	lea dx, KomE
	int 21h
	jmp Koniec
NumerDysku:
	push cx				;zachowaj wartosc petli na stosie
	xor cx, cx
	mov cl, 25
	xor di, di
NDyskuPetla:
	mov dl, Dyski1[di]		;porownaj nazwe dysku ze znakami w tablicach
	cmp al, dl
	je LadujNumerDysku
	mov dl, Dyski2[di]
	cmp al, dl
	je LadujNumerDysku
	inc di
	loop NDyskuPetla
	jmp BladNazwyDysku
LadujNumerDysku:
	pop cx
	mov ax, di
	mov Dysk, al			;zaladuj numer dysku
	xor di, di
	jmp SprPetla3
NieMaNazwyDysku:
	xor si, si
	xor ax, ax			;wyzeruj rejestr AX
	mov cl, DlLiniiParam
SprPetla3:
	mov al, Parametry[si]
	cmp al, '/'
	je BladP2
	cmp al, ' '
	jne SprPetla4
	inc si
	jmp SprPetla3
SprPetla4:
	mov al, Parametry[si]
	cmp al, ' '
	je PobNazweKoniec
	cmp al, '/'
	je PobNazweKoniec
	cmp ah, 12
	ja ZaDlugaN			;skok, gdy wiekszy od 12
	mov Plik[di], al
	mov Plik[di+1], 0		;zaladuj na koniec nazwy pliku zero
	inc ah				;ah=dlugosc nazwy podanego pliku
	inc si
	inc di
	loop SprPetla4
	jmp PobNazweKoniec
ZaDlugaN:
	lea dx, KomH
	mov ah, 09h
	int 21h
	jmp Koniec
BladP2:
	lea dx, KomF
	mov ah, 09h
	int 21h
	jmp Koniec
PobNazweKoniec:
	ret
ENDP


OtworzPlikDoZapisu PROC
	lea dx, PlikDoZapisu		;zaladuj nazwe pliku
OtworzPlik:
	xor cx, cx			;atrybuty pliku 0h
	mov ah, 5bh			;funkcja tworzenia nowego pliku
	int 21h
	jc BladTwPliku1			;jezeli wystapil blad to CF=1
	jmp BrakBlTwPliku
BladTwPliku1:
	cmp ax, 80			;AX=80 - plik o podanej nazwie juz istnieje
	je BladTwPliku2
	lea dx, KomI
	mov ah, 09h
	int 21h
	jmp Koniec
BladTwPliku2:
	cmp PlikDoZapisu[0], 12		;sprawdz, czy juz wczesniej taki blad wystapil
	je NieNadpisuj			;jezeli tak zazadaj ponownego wpisania nazwy
	lea dx, KomJ
	mov ah, 09h
	int 21h
	mov ah, 07h			;funkcja czytania znaku
CzytajZnak:
	int 21h				;kod znaku zwracany jest w AL
	cmp al, 116			;116=znak T
	je Nadpisz
	cmp al, 110			;110=znak N
	je NieNadpisuj
	jmp CzytajZnak			;jezeli znak to nie "T" lub "N" - powtorz petle
Nadpisz:
	mov ah, 3ch			;tworzenie nowego pliku (z nadpisaniem starego)
	lea dx, PlikDoZapisu
	int 21h
	jc BladTwPliku1			;jezeli wystapil blad CF=1
	jmp BrakBlTwPliku
NieNadpisuj:
	lea dx, KomK
	mov ah, 09h
	int 21h
	mov ah, 0Ah			;funkcja odczytu wiersza z klawiatury
	mov PlikDoZapisu[0], 13		;zaladuj maksymalna dlugosc ciagu do odczytu
	lea dx, PlikDoZapisu		;bufor strumienia wyjsciowego
	int 21h	
	xor ax, ax
	mov al, PlikDoZapisu[1]		;pobierz dlugosc odczytanego ciagu
	mov di, ax
	mov PlikDoZapisu[di+2], 0	;zaladuj na koniec pobranego ciagu znak 0
	lea dx, PlikDoZapisu + 2	;zaladuj nowa nazwe
	jmp OtworzPlik
BrakBlTwPliku:
	mov DojscieDoPlikZ, ax
	ret
ENDP


ZamkPlDoZapisu PROC
	mov bx, DojscieDoPlikZ		;zaladuj do BX numer dojscia do pliku
	mov ah, 3Eh			;funkcja zamykania dojscia do pliku
	int 21h
	ret
ENDP


Hex2Ascii PROC
	mov al, bh
	aam				;zamien liczbe binarna na liczbe w kodzie BCD
	add ah, '0'
	add al, '0'
	ret
ENDP


LadujInfOPliku PROC
	xor di, di
	mov cx, 63
WyKatalogB:				;wyzeruj tablice KatalogB
	mov KatalogB[di], 0
	inc di
	loop WyKatalogB
	mov cx, 0Dh
	xor si, si
	xor di, di
InfPetla:				;ladowanie nazwy odnalezionego pliku
	mov al, es:[si+158]		;laduj nazwe pliku z bufora DTA
	cmp al, 0
	je InfPetlaK
	mov NazwaPliku[di], al
	mov NazwaPliku[di+1], '$'	;zaladuj na koniec ciagu znak $
	inc di
	inc si
	loop InfPetla
InfPetlaK:
	mov NazwaPliku[di], 0
	mov NazwaPliku[di+1], '$'
	inc di
	dec cx
	jcxz InfPetlaKK
	jmp InfPetlaK
InfPetlaKK:
	xor di, di
	mov Data[2], '-'
	mov Data[5], '-'
	mov Czas[2], ':'
	mov Czas[5], ':'
	mov Data[8], '$'
	mov Czas[8], '$'
	mov AtrCiag[7], '$'
	mov al, es:[149]		;zaladuj bajt atrybutow (80h+15h=149d)
	test ax, 10h			;testuj, czy bit4=1 (podkatalog)
	jnz Podkat
	jmp PodkatN
Podkat:
	mov AtrCiag[1], 'K'
PodkatN:
	test ax, 20h			;testuj, czy bit5=1 (archiwalny)
	jnz PArchiwalny
	jmp PArchiwalnyN
PArchiwalny:
	mov AtrCiag[2], 'A'
PArchiwalnyN:
	test ax, 1			;testuj, czy bit0=1 (tylko do odczytu)
	jnz PDoOdczytu
	jmp PDoOdczytuN
PDoOdczytu:
	mov AtrCiag[3], 'R'
PDoOdczytuN:
	test ax, 2			;testuj, czy bit1=1 (ukryty)
	jnz PUkryty
	jmp PUkrytyN
PUkryty:
	mov AtrCiag[4], 'U'
PUkrytyN:
	test ax, 4h			;testuj, czy bit2=1 (systemowy)
	jnz PSystemowy
	jmp PSystemowyN
PSystemowy:
	mov AtrCiag[5], 'S'
PSystemowyN:
	xor ax, ax
	mov dh, es:[153]		;zaladuj date ostatniej modyfikacji
	mov dl, es:[152]
	mov bx, dx
	and bx, 1e0h
	shl bx, 1			;przesun w lewo
	shl bx, 1
	shl bx, 1
	call Hex2Ascii
	mov Data[3], ah
	mov Data[4], al

	mov bx, dx
	and bx, 0fe00h
	shr bx, 1			;przesuno 1 w prawo
	;sprawdz czy data mniejsza od 80 (np. rok 2000 :)
	cmp bh, 19			;jezeli wieksze od 19
	ja Rok2000
	add bh, 80
	jmp NormalnyRok
Rok2000:
	sub bh, 20
NormalnyRok:
	call Hex2Ascii
	mov Data[0], ah
	mov Data[1], al

	mov bx, dx
	and bx, 1fh
	xchg bh, bl
	call Hex2Ascii
	mov Data[6], ah
	mov Data[7], al

	mov dh, es:[151]
	mov dl, es:[150]
	mov bx, dx
	and bx, 1Fh
	xchg bh, bl
	call Hex2Ascii
	mov Czas[6], ah
	mov Czas[7], al
	mov bx, dx
	and bx, 7e0h
	shl bx, 1
	shl bx, 1
	shl bx, 1
	call Hex2Ascii
	mov Czas[3], ah
	mov Czas[4], al
	mov bx, dx
	and bx, 0f800h
	shr bx, 1
	shr bx, 1
	shr bx, 1
	call Hex2Ascii
	mov Czas[0], ah
	mov Czas[1], al
	mov ah, 47h
	lea si, KatalogB	
	mov dl, 0			;dysk biezacy
	int 21h
	xor si, si
	mov KatalogB[63], '$'		;zaladuj na koniec znak "$"
	ret
	jmp koniec
ENDP


Zapisuj MACRO DlugoscC, NazwaC
	mov ah, 40h			;funkcja pisania przez dojscie
	mov cx, DlugoscC		;dlugosc zapisywanego ciagu
	lea dx, NazwaC			;adres zapisywanego ciagu
	int 21h
ENDM


WyswietlInfOPliku PROC
	xor di, di
	cmp Zapis, 1			;sprawdz, czy ma zapisywac do pliku
	je ZapDoPliku
	jmp NZapDoPliku
ZapDoPliku:				;zapisywanie informacji do pliku
	mov bx, DojscieDoPlikZ
	cmp Znaleziony, 1	;sprawdz, czy juz uruchomiono wczesniej ta procedure
	jne NapisPocz1		;jezeli nie - zapisz do pliku napis poczatkowy
	jmp OminNapisPocz1
NapisPocz1:
	Zapisuj 50, KomL
	jc BladZapisu1		;zakoncz program jezeli wystapil blad
	jmp OminNapisPocz1
BladZapisu1:
	jmp BladZapisu
OminNapisPocz1:
	cmp KatWyswietlony, 1	;sprawdz, czy juz zostala wyswietlona nazwa katalogu
	je WysKat1
	jmp NWysKat1
WysKat1:
	Zapisuj 1, Kat
	jc BladZapisu1
	Zapisuj 63, KatalogB
	jc BladZapisu1
	Zapisuj 2, NastepnaLinia
	jc BladZapisu1
NWysKat1:
	Zapisuj 0dh, NazwaPliku
	jc BladZapisu
	Zapisuj 3, Przerwa
	jc BladZapisu
	Zapisuj 8, Data
	jc BladZapisu
	Zapisuj 3, Przerwa
	jc BladZapisu
	Zapisuj 8, Czas
	jc BladZapisu
	Zapisuj 3, Przerwa
	jc BladZapisu
	Zapisuj 5, AtrCiag
	jc BladZapisu
	Zapisuj 2, NastepnaLinia
	jc BladZapisu
	jmp NZapDoPliku
BladZapisu:
	lea dx, KomM
	mov ah, 09h
	int 21h
	jmp Koniec
NZapDoPliku:			;wyswietlanie informacji na ekranie
	mov ah, 09h
	cmp Znaleziony, 1	;sprawdz, czy juz uruchomiono wczesniej ta procedure
	jne NapisPocz2		;jezeli nie - wyswietl napis poczatkowy
	jmp OminNapisPocz2
NapisPocz2:
	lea dx, KomL
	int 21h
OminNapisPocz2:
	cmp KatWyswietlony, 1
	je WyswKat2
	jmp NWyswKat2
WyswKat2:
	lea dx, Kat
	int 21h
	lea dx, KatalogB
	int 21h
	lea dx, NastepnaLinia
	int 21h
	mov KatWyswietlony, 0
NWyswKat2:
	lea dx, NazwaPliku	;wyswietl nazwe wyszukanego pliku
	int 21h
	lea dx, Przerwa
	int 21h
	lea dx, Data
	int 21h
	lea dx, Przerwa
	int 21h
	lea dx, Czas
	int 21h
	lea dx, Przerwa
	int 21h
	lea dx, AtrCiag
	int 21h
	lea dx, NastepnaLinia
	int 21h
	ret
ENDP


WyczyscTab PROC
	xor di, di
	mov cx, 7
AtrWy:
	mov AtrCiag[di], 0	;wyzeruj ciag atrybutow
	inc di
	loop AtrWy
	xor di, di
	ret
ENDP


SprBiezacyKatalog PROC
	cmp Atrybuty, 1		;sprawdz, czy podano atrybuty pliku
	je LadujAtr		;jezeli tak zaladuj do CX
	jmp NieLadujAtr
LadujAtr:
	mov cx, Atrybut
	jmp AtrybK
NieLadujAtr:
	xor cx, cx
AtrybK:
	mov ah, 4Eh		;wyszukaj pierwszy plik odpowiadajacy wzorcowi
	lea dx, Plik		;zaladuj wzorzec
	int 21h
	jc KoniecBKat	;jezeli nie znaleziono zadnego pliku - skok na koniec
	mov al, es:[158]
	cmp al, '.'
	je OmKatN
	call LadujInfOPliku
	mov KatWyswietlony, 1
	call WyswietlInfOPliku	
	mov Znaleziony, 1
	jmp SzBPetla
OmKatN:
	mov KatWyswietlony, 1
SzBPetla:			;petla wyszukajaca kolejne pliki w katalogu
	mov ah, 4Fh		;funkcja - wyszukiwanie kolejnego pliku
	int 21h
	jc KoniecBKat		;jezeli nie znaleziono wiecej  - zakoncz petle
	mov al, es:[158]
	cmp al, '.'
	je SzBPetla
	call WyczyscTab
	call LadujInfOPliku
	call WyswietlInfOPliku
	mov Znaleziony, 1
	jmp SzBpetla
KoniecBKat:
	xor si, si
	xor di, di
	ret
ENDP


LadujPodK PROC
	xor si, si
	xor di, di
	mov cx, 64
LadujNKat:
	mov al, es:[si+158]	;laduj nazwe znalezionego pliku z bufora DTA
	cmp al, 0
	je LadujNKatKoniec
	mov Katalog[di], al
	mov Katalog[di+1], 0
	inc di
	inc si
	loop LadujNKat
LadujNKatKoniec:
	xor si, si
	xor di, di
	mov ah, 3bh		;ustalanie katalogu biezacego
	lea dx, Katalog
	int 21h
	ret
ENDP


PrzejdzWyzej PROC
	xor di, di
	mov ah, 47h		;sprawdz biezacy katalog
	lea si, KatalogW
	mov dl, 0
	int 21h
	mov cx, 64
	mov si, cx
	dec si
UsuwajS:
	mov al, KatalogW[si]
	cmp al, '\'
	je UsunSciezke
	dec si
	loop UsuwajS
	xor si, si
	xor di, di	
	mov cx, 1eh
	jmp OminINCSI
UsunSciezke:
	mov DlSciezki, si	;zachowaj dlugosc sciezki
UsunSciezkeP:
	mov cx, 1eh
	inc si
	jmp OOminINCSI
OminINCSI:
	mov KatalG, 1
OOminINCSI:
	mov al, KatalogW[si]
	cmp al, 0
	je ZakonczUsuw
	mov Katalog[di], al
	mov Katalog[di+1], 0
	inc di
	loop UsunSciezkeP
ZakonczUsuw:
	xor si, si
	xor di, di
	mov KatalogWyzej[0], '\'
	mov KatalogWyzej[1], 0
	inc di
	mov cx, DlSciezki
	cmp KatalG, 1
	jne ZachowajSc
	mov KatalG, 0
	jmp OminPZachSc
ZachowajSc:
	mov al, KatalogW[si]
	mov KatalogWyzej[di], al
	mov KatalogWyzej[di+1], 0
	inc di
	inc si
	loop ZachowajSc
OminPZachSc:
	xor di, di
	xor si, si
	mov ah, 4eh			;znajdz pierwszy plik
	lea dx, WszystkiePl	
	mov cx, Atr2
	int 21h
	lea dx, KatalogWyzej		;przejdz do katalogu powyzej
	mov ah, 3bh			;ustalanie katalogu biezacego
	int 21h
	mov Wroc, 1
	ret
ENDP


Porownaj PROC
	mov TenSam, 0
	xor di, di
	mov cx, 0dh
	xor si, si
PorownajP:
	mov al, Katalog[si]
	mov ah, es:[158+si]
	cmp al, ah
	jne Rozne
	cmp al, 0
	je TakieSame
	inc si
	loop PorownajP
	jmp TakieSame
Rozne:
	mov TenSam, 0
	jmp PorowK
TakieSame:
	mov TenSam, 1
PorowK:
	xor si, si
	ret
ENDP


Szukaj PROC
	cmp Zapis, 1
	je ZapisDoP
	jmp ZapisN
ZapisDoP:			;zapisywanie do pliku wlaczone - otworz plik
	call OtworzPlikDoZapisu
ZapisN:
	cmp TylkoBiezacy, 1	;sprawdz, czy ma szukac tylko w biezacym katalogu
	je SzukajTylkoWB
	jmp SzukajW
SzukajTylkoWB:
	call SprBiezacyKatalog
	cmp Znaleziony, 1
	jne SzukajTylkoWB1	;jezeli nie znaleziono pliku
	jmp SzukajTylkoWB2	;gdy przymajmniej jeden plik zostal znaleziony
SzukajTylkoWB1:
	lea dx, KomN
	mov ah, 09h
	int 21h
SzukajTylkoWB2:
	jmp Koniec
SzukajW:
	xor di, di
	lea si, Katalog		;zachowaj nazwe biezacego katalogu
	mov ah, 47h
	mov dl, 0
	int 21h
	xor si, si
	mov ZachBKatalog[0], '\'
	inc di
	mov cx, 0dh
PrzepiszTab:
	mov al, Katalog[si]
	cmp al, 0
	je ZakPrzepisz
	mov ZachBKatalog[di], al
	mov ZachBKatalog[di+1], 0
	inc di
	inc si
	loop PrzepiszTab
ZakPrzepisz:
	xor si, si
	xor di, di
	cmp ZmienDysk, 1	;sprawdz, czy ma zostac zmieniony dysk
	je ZmienD
	jmp NieZmienD
ZmienD:
	mov ah, 19h		;sprawdz numer dysku biezacego
	int 21h
	mov DyskBiezacy, al	;zachowaj numer dysku biezacego
	mov dl, Dysk		;zaladuj do DL numer dysku logicznego
	mov ah, 0eh		;funkcja sluzaca do zmiany dysku logicznego
	int 21h
NieZmienD:
	mov Katalog[0], '\'	;zmien katalog na glowny
	mov Katalog[1], 0
	lea dx, Katalog
       	mov ah, 3bh		;funkcja do zmiany katalogu
	int 21h

SprKatalogi:
	cmp Wroc, 1
	je NieSpr1Raz
	call SprBiezacyKatalog	;przeszukaj biezacy katalog
	mov ah, 4eh		;wyszukiwanie katalogu (pliku)
	lea dx, WszystkiePl
	mov cx, Atr2		;zaladuj atrybuty przeszukiwanych katalogow
	int 21h
	jc PowrotP		;jezeli w katalogu nie ma plikow i podkatalogow
	mov ax, es:[149]
	test ax, 10h
	jnz PrzejdzDoPK
	jmp PSzukaniaK
NieSpr1Raz:
	mov Wroc, 0		;wyszukuj plki od poczatku
	mov ah, 4eh
	lea dx, WszystkiePl
	mov cx, Atr2
	int 21h
	jc PowrotP
	call Porownaj		;sprawdz, czy plik=przeszukiwany wczesniej katalog
	cmp TenSam, 1		;jezeli tak skok do dalszego przeszukiwania
	je PSzukaniaK
NieSpr1RazP:
	mov ah, 4fh		;powtarzaj dopoki nie poprzedni katalog
	int 21h
	jc PowrotP
	call Porownaj
	cmp TenSam, 1
	je PSzukaniaK
	jmp NieSpr1RazP
PSzukaniaK:
	mov ah, 4fh
	int 21h
	jc PowrotP		;jezeli nie znaleziony zakoncz petle
	mov ax, es:[149]	;laduj bajt atrybutow
	test ax, 10h		;testuj, czy to podkatalog
	jnz PrzejdzDoPK		;jezeli tak przejdz do niego
	jmp PSzukaniaK
PrzejdzDoPk:
	mov ah, es:[158]
	cmp ah, '.'
	je PSzukaniaK
	call LadujPodK
	jmp SprKatalogi
PowrotP:
	mov Katalog[0], 0
	mov ah, 47h		;pytanie o katalog biezacy
	lea si, Katalog
	mov dl, 0		;dysk biezacy
	int 21h
	xor si, si
	cmp Katalog[0], 0	;jezeli nie glowny to wartosc sie zmieni
	je KatGlowny		;jezeli glowny - zakoncz
NieKatG:
	call PrzejdzWyzej
	jmp SprKatalogi
KatGlowny:

	cmp ZmienDysk, 1	;sprawdz, czy byl zmieniany dysk
	je PDyskB
	jmp NPDyskuB
PDyskB:
	mov dl, DyskBiezacy
	mov ah, 0eh		;przywroc dysk biezacy
	int 21h
NPDyskuB:
	xor di, di
	xor si, si
	mov ah, 3bh		;przywroc katalog sprzed wyszukiwania
	lea dx, ZachBKatalog
	int 21h
	cmp Znaleziony, 1
	jne NieZnaleziono
	jmp koniec
	ret
NieZnaleziono:
	lea dx, KomN
	mov ah, 09h
	int 21h
	jmp Koniec
ENDP


Start:
	mov ax, @data
	mov ds, ax		;zaladuj do DS adres segmentu danych
	call CzySaParametry
	call PobierzParametry
	call PobierzNazwePliku
	call Szukaj
Koniec:
	call ZamkPlDoZapisu	;zamknij plik
	mov ax, 4c00h		;zakoncz program
	int 21h

End Start

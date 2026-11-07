.model tiny			;najmniejszy model pamieci dla programu
.stack 30			;stos programu = 30 bajtow
.code				;poczatek segmentu kodu
Start:

	mov ax, 15		; rejestr AX = 15

	xor di, di		; rejestr DI = 0

	shl ax, 6		; przesun o 6 w lewo
				; czyli pomnoz przez 2^6 czyli 64
				; AX teraz = 15*64 = 960

	add di, ax		; rejestr DI = DI + AX = 0 + 960 = 960

	shl ax, 2		; przesun o 2 w lewo
				; czyli pomnoz AX przez 4 (bo 2^2 = 4)
				; AX teraz = 960 * 4 = 3840

	add di, ax		; rejestr DI = DI + AX = 960 + 3840 = 4800
				; i to jest rownoznaczne jakby pomnozyc
				; 15 * 320
				; a to dlatego, ze 64 + 4 * (64) = 64+256 = 320
				; kazda liczbe naturalna mozna rozlozyc na
				; potegi dwojki

	mov ax, 4c00h		;zaladuj do AX funkcje konczaca program

	int 21h			;i teraz - zamknij program (wywolujac przerwanie 21h)

End Start
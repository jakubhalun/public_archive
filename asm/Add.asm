.model tiny			;najmniejszy model pamieci dla programu
.stack 30			;stos programu = 30 bajtow
.code				;poczatek segmentu kodu
Start:

	mov ax, 15		; zawartosc rejestru AX = 15

	mov dx, 26		; zawartosc rejestru DX = 26

	add ax, dx		; dodaj zawartosc AX do DX (i umiesc wynik w AX - wynik zawsze w pierwszy "operandzie"

	mov ax, 4c00h		;zaladuj do AX funkcje konczaca program

	int 21h			;i teraz - zamknij program (wywolujac przerwanie 21h)

End Start
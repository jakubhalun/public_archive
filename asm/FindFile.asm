; Searches directories for matching files using MS-DOS services, with optional logging.
;********************************************************************
;*     FF.ASM - FILE FIND - searches for files on a disk               *
;*     Copyright (C) 2000 Jakub Halun				    *
;*     www.yaqb.prv.pl						    *
;********************************************************************
.model small
.stack 512
.data
	OutputFileHandle dw ?		;output file handle
	CommandLineLength db ?
	ChangeDriveFlag db 0
	DriveNumber db ?
	FilePattern db 15 dup (?)
	OutputFileName db 15 dup (?)
	LowercaseDrives db 'abcdefghijklmnopqrstuvwxyz'
	UppercaseDrives db 'ABCDEFGHIJKLMNOPRQSTUVWXYZ'
	FileName db 13 dup (?)
	FileNameLength dw ?
	FileDate db 9 dup (?)
	FileTime db 9 dup (?)
	AttributeString db 8 dup (?)
	CurrentDirectory db 64 dup (?)
	NewLine db 13,10,'$'
	OriginalDrive db ?	;save the current drive number if changing drives
	DirectoryName db 64 dup (?)
	SavedDirectory db 64 dup (?)
	DirectorySeparator db '\','$'
	AllFiles db '*.*', 0
	ParentDirectory db 64 dup (?)
	WorkingDirectory db 64 dup (?)
	AttributeBuffer db ?
	SizeBuffer db 4 dup (?)
	DateBuffer dw ?
	TimeBuffer dw ?
	ReturningFlag db 0
	PathLength dw ?
	RootDirectoryFlag db 0
	Info db 'FILE FIND wersja 1.0  Copyright (C) 2000 Jakub Halun',13,10,'$'
	Message0 db 'Program wyszukuje na dysku pliki o zadanych parametrach',13,10,13,10,'$'
	Message1 db 'FF [dysk:] nazwa_pliku [/L:PLIK] [/U] [/S] [/K] [/B]',13,10,13,10,'$'
	Message2 db '[dysk:] - okresla dysk do przeszukania',13,10,'$'
	Message3 db 'nazwa_pliku - okresla plik do wyszukania', 13,10,13,10,'$'
	Message4 db '/L - zachowuje wyniki przeszukiwania dysku do PLIK',13,10,13,10,'$'
	Message5 db '/U - wyszukuje rowniez pliki ukryte',13,10,'$'
	Message6 db '/S - wyszukuje rowniez pliki systemowe',13,10,'$'
	Message9 db '/K - wyszukuje rowniez podkatalogi',13,10,13,10,'$'
	MessageB db '/B - przeszukuje wylacznie biezacy katalog',13,10,'$'
	MessageC db 'Blad: plik podany przy parametrze /L juz istnieje',13,10,'$'
	MessageD db 'Niewlasciwe parametry. Nie podano nazwy pliku do zapisu',13,10,13,10,'$'
	MessageE db 'Niewlasciwe parametry. Niewlasciwe okreslenie dysku',13,10,13,10,'$'
	MessageF db 'Niewlasciwe parametry. Brak nazwy pliku do wyszukania',13,10,13,10,'$'
	MessageG db 'Niewlasciwe parametry. Nazwa pliku do zapisu zawiera zbyt wiele znakow',13,10,13,10,'$'
	MessageH db 'Niewlasciwe parametry. Nazwa pliku do wyszukania zawiera zbyt wiele znakow',13,10,13,10,'$'
	MessageI db 'Blad: nie mozna utworzyc pliku do zapisu',13,10,13,10,'$'
  	MessageJ db 'Tworzony plik juz istnieje. Nadpisac istniejacy plik? T/N',13,10,'$'
	MessageK db 'Podaj nowa nazwe dla tworzonego pliku...',13,10,'$'
	MessageL db 'NAZWA PLIKU   -   DATA   -   CZAS   - ATRYBUTY',13,10,13,10,'$'
	MessageM db 'Blad zapisu do pliku. Program zostanie zakonczony',13,10,'$'
	MessageN db 'Nie znaleziono zadnego pliku odpowiadajacego wzorcowi',13,10,'$'
	Separator db ' - ','$'
	Parameters db 256 dup (?)
	CheckAttributes db 0		;whether the program should check file attributes
	CurrentDirectoryOnly db 0	;search only the current directory: 1 = yes
	FileAttributes dw 0		;file attributes
	SearchAttributes dw 0
	WriteEnabled db 0
	FileFound db 0
	DirectoryDisplayed db 0
	SameName db 0

.code
ShowHelp PROC
	mov ah, 09h
	lea dx, Info
	int 21h
	lea dx, Message0
	int 21h
	lea dx, Message1
	int 21h
	lea dx, Message2
	int 21h
	lea dx, Message3
	int 21h
	lea dx, Message4
	int 21h
	lea dx, Message5
	int 21h
	lea dx, Message6
	int 21h
	lea dx, Message9
	int 21h
	lea dx, MessageB
	int 21h
	jmp ExitProgram
	ret
ENDP


CheckParameters PROC
	mov ah, 62h
	int 21h
	mov es, bx		;load the PSP address into ES
	mov bl, es:[0080h]	;get the command line length
	cmp bl, 0		;and check whether it is zero
	jne ParametersPresent
	call ShowHelp		;display help if there are no parameters
ParametersPresent:
	mov CommandLineLength, bl	;save the command line length
	ret
ENDP


GetParameters PROC
	mov si, 81h		;load the command line offset
	xor cx, cx
	mov cl, CommandLineLength	;load the command line length
	lea di, Parameters	;load the offset of the Parameters array
CopyLoop1:				;copy the command line contents into the array
	mov al, es:[si]
	mov ds:[di], al
	inc di
	inc si
	dec cx
	jcxz CheckOptions
	jmp CopyLoop1
CheckOptions:
	mov cl, CommandLineLength	;check parameters
	xor si, si
	xor di, di
	xor bx, bx		;BX will hold the attributes
	jumps
	jmp CheckOptionsLoop
ShowHelpJump:	call ShowHelp
CheckOptionsLoop:
	mov ah, Parameters[si]
	mov al, Parameters[si+1]
	cmp ax, '/?'
	je ShowHelpJump
	cmp ax, '/H'
	je ShowHelpJump
	cmp ax, '/h'
	je ShowHelpJump
	cmp ax, '/u'
	je HiddenOption
	cmp ax, '/U'
	je HiddenOption
	cmp ax, '/s'
	je SystemOption
	cmp ax, '/S'
	je SystemOption
	cmp ax, '/k'
	je SubdirectoryOption
	cmp ax, '/K'
	je SubdirectoryOption
	cmp ax, '/b'	
	je CurrentDirectoryOption
	cmp ax, '/B'
	je CurrentDirectoryOption
	cmp ax, '/l'
	je WriteOption
	cmp ax, '/L'
	je WriteOption
	inc si
	loop CheckOptionsLoop
	jmp EndOptions
HiddenOption:
	inc si
	dec cx
	mov CheckAttributes, 1
	or bx, 2h			;bit 1 = 1: hidden file
	jmp CheckOptionsLoop
SystemOption:
	inc si
	dec cx
	mov CheckAttributes, 1
	or bx, 4h			;bit 2 = 1: system file
	jmp CheckOptionsLoop
SubdirectoryOption:
	inc si
	dec cx
	mov CheckAttributes, 1
	or bx, 10h
	jmp CheckOptionsLoop
CurrentDirectoryOption:
	inc si
	dec cx
	mov CurrentDirectoryOnly, 1
	jmp CheckOptionsLoop
WriteOption:
	mov WriteEnabled, 1
	xor ax, ax
	add si, 2
	sub cx, 2
	mov al, Parameters[si]
	cmp al, ':'
	jne ParameterError
	inc si
	dec cx
	mov al, Parameters[si]
	cmp al, ' '
	je ParameterError
	xor di, di
OutputNameLoop:
	mov al, Parameters[si]
	cmp al, ' '
	je CheckOptionsLoop
	cmp ah, 12
	ja OutputNameTooLong			;jump if greater than twelve
	cmp cl, 0
	je EndOptions			;jump if zero (end of command line)
	mov OutputFileName[di], al
	mov OutputFileName[di+1], 0	;append a zero to the file name
	inc di
	inc si
	inc ah				;count the name length
	dec cx
	jmp OutputNameLoop
OutputNameTooLong:
	lea dx, MessageG
	mov ah, 09h
	int 21h
	jmp ExitProgram
ParameterError:
	lea dx, MessageD
	mov ah, 09h
	int 21h
	jmp ExitProgram
EndOptions:
	mov FileAttributes, bx
	or bx, 10h
	mov SearchAttributes, bx
	ret
ENDP


GetFileName PROC
	xor cx, cx
	mov cl, CommandLineLength
	xor si, si
	xor di, di
CheckDriveLoop:
	mov al, Parameters[si]
	cmp al, ':'
	je LoadDriveName
	cmp al, '/'
	je NoDriveName
	inc si
	loop CheckDriveLoop
	jmp NoDriveName
LoadDriveName:
	mov al, Parameters[si-1]
	mov ChangeDriveFlag, 1
	inc si
	dec cx
	jmp FindDriveNumber
DriveNameError:
	mov ah, 09h
	lea dx, MessageE
	int 21h
	jmp ExitProgram
FindDriveNumber:
	push cx				;save the loop counter on the stack
	xor cx, cx
	mov cl, 25
	xor di, di
DriveNumberLoop:
	mov dl, LowercaseDrives[di]		;compare the drive letter with the characters in the arrays
	cmp al, dl
	je LoadDriveNumber
	mov dl, UppercaseDrives[di]
	cmp al, dl
	je LoadDriveNumber
	inc di
	loop DriveNumberLoop
	jmp DriveNameError
LoadDriveNumber:
	pop cx
	mov ax, di
	mov DriveNumber, al			;load the drive number
	xor di, di
	jmp SkipNameSpaces
NoDriveName:
	xor si, si
	xor ax, ax			;clear AX
	mov cl, CommandLineLength
SkipNameSpaces:
	mov al, Parameters[si]
	cmp al, '/'
	je FileNameError
	cmp al, ' '
	jne CopyNameLoop
	inc si
	jmp SkipNameSpaces
CopyNameLoop:
	mov al, Parameters[si]
	cmp al, ' '
	je EndGetFileName
	cmp al, '/'
	je EndGetFileName
	cmp ah, 12
	ja NameTooLong			;jump if greater than 12
	mov FilePattern[di], al
	mov FilePattern[di+1], 0		;append a zero to the file name
	inc ah				;AH = length of the supplied file name
	inc si
	inc di
	loop CopyNameLoop
	jmp EndGetFileName
NameTooLong:
	lea dx, MessageH
	mov ah, 09h
	int 21h
	jmp ExitProgram
FileNameError:
	lea dx, MessageF
	mov ah, 09h
	int 21h
	jmp ExitProgram
EndGetFileName:
	ret
ENDP


OpenOutputFile PROC
	lea dx, OutputFileName		;load the file name
CreateFile:
	xor cx, cx			;file attributes: 0h
	mov ah, 5bh			;create a new file
	int 21h
	jc FileCreationError1			;CF = 1 if an error occurred
	jmp FileCreated
FileCreationError1:
	cmp ax, 80			;AX = 80: a file with this name already exists
	je FileCreationError2
	lea dx, MessageI
	mov ah, 09h
	int 21h
	jmp ExitProgram
FileCreationError2:
	cmp OutputFileName[0], 12		;check whether this error has already occurred
	je DoNotOverwrite			;if so, request another file name
	lea dx, MessageJ
	mov ah, 09h
	int 21h
	mov ah, 07h			;read a character
ReadCharacter:
	int 21h				;the character code is returned in AL
	cmp al, 116			;116 = character 't'
	je Overwrite
	cmp al, 110			;110 = character 'n'
	je DoNotOverwrite
	jmp ReadCharacter			;repeat the loop if the character is neither 't' nor 'n'
Overwrite:
	mov ah, 3ch			;create a new file, overwriting the old one
	lea dx, OutputFileName
	int 21h
	jc FileCreationError1			;CF = 1 if an error occurred
	jmp FileCreated
DoNotOverwrite:
	lea dx, MessageK
	mov ah, 09h
	int 21h
	mov ah, 0Ah			;read a line from the keyboard
	mov OutputFileName[0], 13		;load the maximum length of the string to read
	lea dx, OutputFileName		;output stream buffer
	int 21h	
	xor ax, ax
	mov al, OutputFileName[1]		;get the length of the string read
	mov di, ax
	mov OutputFileName[di+2], 0	;append a zero to the string read
	lea dx, OutputFileName + 2	;load the new name
	jmp CreateFile
FileCreated:
	mov OutputFileHandle, ax
	ret
ENDP


CloseOutputFile PROC
	mov bx, OutputFileHandle		;load the file handle into BX
	mov ah, 3Eh			;close the file handle
	int 21h
	ret
ENDP


Hex2Ascii PROC
	mov al, bh
	aam				;convert a binary number to BCD
	add ah, '0'
	add al, '0'
	ret
ENDP


LoadFileInfo PROC
	xor di, di
	mov cx, 63
ClearDirectoryBuffer:				;clear the CurrentDirectory array
	mov CurrentDirectory[di], 0
	inc di
	loop ClearDirectoryBuffer
	mov cx, 0Dh
	xor si, si
	xor di, di
FileInfoLoop:				;load the name of the file found
	mov al, es:[si+158]		;load the file name from the DTA buffer
	cmp al, 0
	je FileInfoLoopEnd
	mov FileName[di], al
	mov FileName[di+1], '$'	;append a $ to the string
	inc di
	inc si
	loop FileInfoLoop
FileInfoLoopEnd:
	mov FileName[di], 0
	mov FileName[di+1], '$'
	inc di
	dec cx
	jcxz FileInfoPaddingEnd
	jmp FileInfoLoopEnd
FileInfoPaddingEnd:
	xor di, di
	mov FileDate[2], '-'
	mov FileDate[5], '-'
	mov FileTime[2], ':'
	mov FileTime[5], ':'
	mov FileDate[8], '$'
	mov FileTime[8], '$'
	mov AttributeString[7], '$'
	mov al, es:[149]		;load the attribute byte (80h + 15h = 149 decimal)
	test ax, 10h			;test whether bit 4 = 1 (subdirectory)
	jnz SubdirectoryAttribute
	jmp SkipSubdirectoryAttribute
SubdirectoryAttribute:
	mov AttributeString[1], 'K'
SkipSubdirectoryAttribute:
	test ax, 20h			;test whether bit 5 = 1 (archive)
	jnz ArchiveAttribute
	jmp SkipArchiveAttribute
ArchiveAttribute:
	mov AttributeString[2], 'A'
SkipArchiveAttribute:
	test ax, 1			;test whether bit 0 = 1 (read-only)
	jnz ReadOnlyAttribute
	jmp SkipReadOnlyAttribute
ReadOnlyAttribute:
	mov AttributeString[3], 'R'
SkipReadOnlyAttribute:
	test ax, 2			;test whether bit 1 = 1 (hidden)
	jnz HiddenAttribute
	jmp SkipHiddenAttribute
HiddenAttribute:
	mov AttributeString[4], 'U'
SkipHiddenAttribute:
	test ax, 4h			;test whether bit 2 = 1 (system)
	jnz SystemAttribute
	jmp SkipSystemAttribute
SystemAttribute:
	mov AttributeString[5], 'S'
SkipSystemAttribute:
	xor ax, ax
	mov dh, es:[153]		;load the last modification date
	mov dl, es:[152]
	mov bx, dx
	and bx, 1e0h
	shl bx, 1			;shift left
	shl bx, 1
	shl bx, 1
	call Hex2Ascii
	mov FileDate[3], ah
	mov FileDate[4], al

	mov bx, dx
	and bx, 0fe00h
	shr bx, 1			;shift right by 1
	;check whether the year is below 80 (e.g., 2000 :)
	cmp bh, 19			;if greater than 19
	ja Year2000
	add bh, 80
	jmp NormalYear
Year2000:
	sub bh, 20
NormalYear:
	call Hex2Ascii
	mov FileDate[0], ah
	mov FileDate[1], al

	mov bx, dx
	and bx, 1fh
	xchg bh, bl
	call Hex2Ascii
	mov FileDate[6], ah
	mov FileDate[7], al

	mov dh, es:[151]
	mov dl, es:[150]
	mov bx, dx
	and bx, 1Fh
	xchg bh, bl
	call Hex2Ascii
	mov FileTime[6], ah
	mov FileTime[7], al
	mov bx, dx
	and bx, 7e0h
	shl bx, 1
	shl bx, 1
	shl bx, 1
	call Hex2Ascii
	mov FileTime[3], ah
	mov FileTime[4], al
	mov bx, dx
	and bx, 0f800h
	shr bx, 1
	shr bx, 1
	shr bx, 1
	call Hex2Ascii
	mov FileTime[0], ah
	mov FileTime[1], al
	mov ah, 47h
	lea si, CurrentDirectory	
	mov dl, 0			;current drive
	int 21h
	xor si, si
	mov CurrentDirectory[63], '$'		;append a "$"
	ret
	jmp ExitProgram
ENDP


WriteString MACRO StringLength, StringAddress
	mov ah, 40h			;write through a file handle
	mov cx, StringLength		;length of the string to write
	lea dx, StringAddress			;address of the string to write
	int 21h
ENDM


DisplayFileInfo PROC
	xor di, di
	cmp WriteEnabled, 1			;check whether to write to a file
	je WriteToFile
	jmp DisplayOnScreen
WriteToFile:				;write information to the file
	mov bx, OutputFileHandle
	cmp FileFound, 1	;check whether this procedure has already run
	jne WriteHeading		;if not, write the heading to the file
	jmp SkipWriteHeading
WriteHeading:
	WriteString 50, MessageL
	jc WriteErrorJump		;exit the program if an error occurred
	jmp SkipWriteHeading
WriteErrorJump:
	jmp WriteError
SkipWriteHeading:
	cmp DirectoryDisplayed, 1	;check whether the directory name has already been displayed
	je WriteDirectory
	jmp SkipWriteDirectory
WriteDirectory:
	WriteString 1, DirectorySeparator
	jc WriteErrorJump
	WriteString 63, CurrentDirectory
	jc WriteErrorJump
	WriteString 2, NewLine
	jc WriteErrorJump
SkipWriteDirectory:
	WriteString 0dh, FileName
	jc WriteError
	WriteString 3, Separator
	jc WriteError
	WriteString 8, FileDate
	jc WriteError
	WriteString 3, Separator
	jc WriteError
	WriteString 8, FileTime
	jc WriteError
	WriteString 3, Separator
	jc WriteError
	WriteString 5, AttributeString
	jc WriteError
	WriteString 2, NewLine
	jc WriteError
	jmp DisplayOnScreen
WriteError:
	lea dx, MessageM
	mov ah, 09h
	int 21h
	jmp ExitProgram
DisplayOnScreen:			;display information on the screen
	mov ah, 09h
	cmp FileFound, 1	;check whether this procedure has already run
	jne DisplayHeading		;if not, display the heading
	jmp SkipDisplayHeading
DisplayHeading:
	lea dx, MessageL
	int 21h
SkipDisplayHeading:
	cmp DirectoryDisplayed, 1
	je DisplayDirectory
	jmp SkipDisplayDirectory
DisplayDirectory:
	lea dx, DirectorySeparator
	int 21h
	lea dx, CurrentDirectory
	int 21h
	lea dx, NewLine
	int 21h
	mov DirectoryDisplayed, 0
SkipDisplayDirectory:
	lea dx, FileName	;display the name of the file found
	int 21h
	lea dx, Separator
	int 21h
	lea dx, FileDate
	int 21h
	lea dx, Separator
	int 21h
	lea dx, FileTime
	int 21h
	lea dx, Separator
	int 21h
	lea dx, AttributeString
	int 21h
	lea dx, NewLine
	int 21h
	ret
ENDP


ClearAttributeString PROC
	xor di, di
	mov cx, 7
ClearAttributesLoop:
	mov AttributeString[di], 0	;clear the attribute string
	inc di
	loop ClearAttributesLoop
	xor di, di
	ret
ENDP


SearchCurrentDirectory PROC
	cmp CheckAttributes, 1		;check whether file attributes were specified
	je LoadAttributes		;if so, load them into CX
	jmp NoAttributes
LoadAttributes:
	mov cx, FileAttributes
	jmp AttributesReady
NoAttributes:
	xor cx, cx
AttributesReady:
	mov ah, 4Eh		;find the first file matching the pattern
	lea dx, FilePattern		;load the pattern
	int 21h
	jc EndDirectorySearch	;jump to the end if no file was found
	mov al, es:[158]
	cmp al, '.'
	je SkipDirectoryEntry
	call LoadFileInfo
	mov DirectoryDisplayed, 1
	call DisplayFileInfo	
	mov FileFound, 1
	jmp SearchDirectoryLoop
SkipDirectoryEntry:
	mov DirectoryDisplayed, 1
SearchDirectoryLoop:			;loop to find subsequent files in the directory
	mov ah, 4Fh		;find the next file
	int 21h
	jc EndDirectorySearch		;end the loop if no more files were found
	mov al, es:[158]
	cmp al, '.'
	je SearchDirectoryLoop
	call ClearAttributeString
	call LoadFileInfo
	call DisplayFileInfo
	mov FileFound, 1
	jmp SearchDirectoryLoop
EndDirectorySearch:
	xor si, si
	xor di, di
	ret
ENDP


EnterSubdirectory PROC
	xor si, si
	xor di, di
	mov cx, 64
LoadDirectoryName:
	mov al, es:[si+158]	;load the name of the file found from the DTA buffer
	cmp al, 0
	je EndLoadDirectoryName
	mov DirectoryName[di], al
	mov DirectoryName[di+1], 0
	inc di
	inc si
	loop LoadDirectoryName
EndLoadDirectoryName:
	xor si, si
	xor di, di
	mov ah, 3bh		;set the current directory
	lea dx, DirectoryName
	int 21h
	ret
ENDP


GoToParentDirectory PROC
	xor di, di
	mov ah, 47h		;get the current directory
	lea si, WorkingDirectory
	mov dl, 0
	int 21h
	mov cx, 64
	mov si, cx
	dec si
RemovePathLoop:
	mov al, WorkingDirectory[si]
	cmp al, '\'
	je RemovePath
	dec si
	loop RemovePathLoop
	xor si, si
	xor di, di	
	mov cx, 1eh
	jmp SkipIncrementSI
RemovePath:
	mov PathLength, si	;save the path length
RemovePathPart:
	mov cx, 1eh
	inc si
	jmp CopyPathPart
SkipIncrementSI:
	mov RootDirectoryFlag, 1
CopyPathPart:
	mov al, WorkingDirectory[si]
	cmp al, 0
	je EndRemovePath
	mov DirectoryName[di], al
	mov DirectoryName[di+1], 0
	inc di
	loop RemovePathPart
EndRemovePath:
	xor si, si
	xor di, di
	mov ParentDirectory[0], '\'
	mov ParentDirectory[1], 0
	inc di
	mov cx, PathLength
	cmp RootDirectoryFlag, 1
	jne SavePath
	mov RootDirectoryFlag, 0
	jmp SkipSavePath
SavePath:
	mov al, WorkingDirectory[si]
	mov ParentDirectory[di], al
	mov ParentDirectory[di+1], 0
	inc di
	inc si
	loop SavePath
SkipSavePath:
	xor di, di
	xor si, si
	mov ah, 4eh			;find the first file
	lea dx, AllFiles	
	mov cx, SearchAttributes
	int 21h
	lea dx, ParentDirectory		;go to the parent directory
	mov ah, 3bh			;set the current directory
	int 21h
	mov ReturningFlag, 1
	ret
ENDP


CompareNames PROC
	mov SameName, 0
	xor di, di
	mov cx, 0dh
	xor si, si
CompareNamesLoop:
	mov al, DirectoryName[si]
	mov ah, es:[158+si]
	cmp al, ah
	jne NamesDifferent
	cmp al, 0
	je NamesEqual
	inc si
	loop CompareNamesLoop
	jmp NamesEqual
NamesDifferent:
	mov SameName, 0
	jmp EndCompareNames
NamesEqual:
	mov SameName, 1
EndCompareNames:
	xor si, si
	ret
ENDP


SearchFiles PROC
	cmp WriteEnabled, 1
	je OpenSearchOutput
	jmp SkipOpenSearchOutput
OpenSearchOutput:			;file output is enabled: open the file
	call OpenOutputFile
SkipOpenSearchOutput:
	cmp CurrentDirectoryOnly, 1	;check whether to search only the current directory
	je SearchCurrentOnly
	jmp SearchAllDirectories
SearchCurrentOnly:
	call SearchCurrentDirectory
	cmp FileFound, 1
	jne NoCurrentMatch	;if no file was found
	jmp EndCurrentSearch	;if at least one file was found
NoCurrentMatch:
	lea dx, MessageN
	mov ah, 09h
	int 21h
EndCurrentSearch:
	jmp ExitProgram
SearchAllDirectories:
	xor di, di
	lea si, DirectoryName		;save the current directory name
	mov ah, 47h
	mov dl, 0
	int 21h
	xor si, si
	mov SavedDirectory[0], '\'
	inc di
	mov cx, 0dh
CopyDirectoryBuffer:
	mov al, DirectoryName[si]
	cmp al, 0
	je EndCopyDirectoryBuffer
	mov SavedDirectory[di], al
	mov SavedDirectory[di+1], 0
	inc di
	inc si
	loop CopyDirectoryBuffer
EndCopyDirectoryBuffer:
	xor si, si
	xor di, di
	cmp ChangeDriveFlag, 1	;check whether to change drives
	je ChangeDrive
	jmp SkipChangeDrive
ChangeDrive:
	mov ah, 19h		;get the current drive number
	int 21h
	mov OriginalDrive, al	;save the current drive number
	mov dl, DriveNumber		;load the logical drive number into DL
	mov ah, 0eh		;change the logical drive
	int 21h
SkipChangeDrive:
	mov DirectoryName[0], '\'	;change to the root directory
	mov DirectoryName[1], 0
	lea dx, DirectoryName
       	mov ah, 3bh		;change the directory
	int 21h

ScanDirectories:
	cmp ReturningFlag, 1
	je ResumeDirectoryScan
	call SearchCurrentDirectory	;search the current directory
	mov ah, 4eh		;find a directory (file)
	lea dx, AllFiles
	mov cx, SearchAttributes		;load the attributes of the directories to search
	int 21h
	jc ReturnToParent		;if the directory contains no files or subdirectories
	mov ax, es:[149]
	test ax, 10h
	jnz GoToSubdirectory
	jmp FindNextDirectory
ResumeDirectoryScan:
	mov ReturningFlag, 0		;search for files from the beginning
	mov ah, 4eh
	lea dx, AllFiles
	mov cx, SearchAttributes
	int 21h
	jc ReturnToParent
	call CompareNames		;check whether the file is the previously searched directory
	cmp SameName, 1		;if so, jump to continue searching
	je FindNextDirectory
ResumeDirectoryLoop:
	mov ah, 4fh		;repeat until the previous directory is found
	int 21h
	jc ReturnToParent
	call CompareNames
	cmp SameName, 1
	je FindNextDirectory
	jmp ResumeDirectoryLoop
FindNextDirectory:
	mov ah, 4fh
	int 21h
	jc ReturnToParent		;end the loop if not found
	mov ax, es:[149]	;load the attribute byte
	test ax, 10h		;test whether this is a subdirectory
	jnz GoToSubdirectory		;if so, enter it
	jmp FindNextDirectory
GoToSubdirectory:
	mov ah, es:[158]
	cmp ah, '.'
	je FindNextDirectory
	call EnterSubdirectory
	jmp ScanDirectories
ReturnToParent:
	mov DirectoryName[0], 0
	mov ah, 47h		;get the current directory
	lea si, DirectoryName
	mov dl, 0		;current drive
	int 21h
	xor si, si
	cmp DirectoryName[0], 0	;the value changes unless this is the root directory
	je AtRootDirectory		;finish if this is the root directory
NotRootDirectory:
	call GoToParentDirectory
	jmp ScanDirectories
AtRootDirectory:

	cmp ChangeDriveFlag, 1	;check whether the drive was changed
	je RestoreDrive
	jmp SkipRestoreDrive
RestoreDrive:
	mov dl, OriginalDrive
	mov ah, 0eh		;restore the original drive
	int 21h
SkipRestoreDrive:
	xor di, di
	xor si, si
	mov ah, 3bh		;restore the directory from before the search
	lea dx, SavedDirectory
	int 21h
	cmp FileFound, 1
	jne NoFilesFound
	jmp ExitProgram
	ret
NoFilesFound:
	lea dx, MessageN
	mov ah, 09h
	int 21h
	jmp ExitProgram
ENDP


Start:
	mov ax, @data
	mov ds, ax		;load the data segment address into DS
	call CheckParameters
	call GetParameters
	call GetFileName
	call SearchFiles
ExitProgram:
	call CloseOutputFile	;close the file
	mov ax, 4c00h		;exit the program
	int 21h

End Start

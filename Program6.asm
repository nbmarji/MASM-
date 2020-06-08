TITLE Programming Assignment 6    (Program6.asm)

; Author: Nora Marji
; Last Modified: 7 June 2020
; OSU email address: marjin@oregonstate.edu
; Course number/section: 271
; Project Number:        6         Due Date: 7 June 2020
; Description: This program gets 10 valid integers from the user, and stores the numeric values in an array.
; The program than displays the integers, their sum, and their average.  This program uses readVal procedure 
; which invokes the getString macro to get the user's string of digits.  It converts the digit string to numeric and
;validates user input.  Then, it uses writeVal procedure to convert the numeric values to a string of digits,
;invoking the displayString macro to produce the output.  

;Implementation note: Parameters are passed on the system stack.


INCLUDE Irvine32.inc

;constants

ARRAYSIZE	= 10

;macros

displayStr	MACRO string_addr
	push	edx
	mov		edx, string_addr
	call	WriteString
	pop		edx

ENDM

getStr	MACRO	var_addr, length
push		ecx
push		edx

mov			edx, var_addr		
mov			ecx, length
call		ReadString
pop			edx
pop			ecx

ENDM

.data
;variables

title1		BYTE	"Programming Assignment 6: Designing Low-Level I/O procedures",0
prgmr		BYTE	"By Nora Marji",0
numprompt	BYTE	"Please enter a signed number: ", 0
prompt1		BYTE	"Please provide 10 signed decimal integers.",0
prompt2		BYTE	"Each number needs to be small enough to fit inside a 32-bit register.",0
prompt3		BYTE	"After you have finished inputting the numbers, I will display a list of the integers, their sum, and their average value.",0
err			BYTE	"ERROR: You did not enter a signed number or your number was too big.",0
bye			BYTE	"Bye!  thanks for a great quarter :)",0
spaces		BYTE	"  ", 0
array		DWORD	ARRAYSIZE	DUP(?)
urnumbs		BYTE	"You entered the following numbers: ",0
userInput	BYTE	12 DUP(?)
sumStr		BYTE	"The sum of these numbers is: ", 0
avgStr		BYTE	"The rounded average is: ",0
sum			DWORD	0
avg			DWORD	?
toStr		BYTE   12 DUP(?)
minus		byte	"-",0


.code
main PROC

;program intro

	push		OFFSET prompt3
	push		OFFSET prompt2
	push		OFFSET prompt1
	push		OFFSET prgmr
	push		OFFSET title1
	call		introduction


; get user data with getStr, validate it, convert it to integers and put in array 

	push		OFFSET	err
	push		OFFSET	array
	push		ARRAYSIZE
	push		OFFSET	numprompt
	push		OFFSET userInput
	push		SIZEOF userInput
	call		readVal


; convert the user input back to string and display it with displayStr 
	push		OFFSET minus
	push		OFFSET spaces
	push		OFFSET array
	push		OFFSET urnumbs
	push		OFFSET toStr
	call		writeVal

;calculates sum and average of the user's numbers 
	push		OFFSET avgStr
	push		OFFSET avg
	push		OFFSET sumStr
	push		OFFSET sum
	push		OFFSET array
	call		sumAndAvg

; goodbye 
	push	OFFSET bye
	call	goodbye

	exit

main ENDP



; ------------------------------------------------------------------
introduction	PROC
; 
; Description: Procedure to introduce program and programmer
; Receives: @title1, @prompt1,2,3 @prgmr  on the system stack
; Returns: none
; Preconditions: string1, string2, extracred are correctly set
; Registers changed: edx
;
; ------------------------------------------------------------------

	push		ebp
	mov			ebp, esp
	pushad

	displayStr	[ebp+8]
	call		CrLF
	displayStr	[ebp+12]
	call		CrLf
	displayStr	[ebp+16]
	call		CrLf
	displayStr	[ebp+20]
	call		CrLf
	displayStr	[ebp+24]
	call		CrLf

	popad
	pop			ebp
	ret	20

introduction	ENDP


; ------------------------------------------------------------------
readVal	PROC
; 
; Description: Gets 10 signed integers from user using getString
; macro.  Converts the user's digit strings to numeric (while validating
;user input) and stores the integers in an array. 
; Receives: @err, @array, ARRAYSIZE, @numprompt, @userInput and 
; SIZEOF userInput
; Returns: array of converted integers
; Preconditions: strings are set correctly, array is initialized correctly 
; Registers changed: eax, ebx, ecx, edx, edi, esi 
;
; ------------------------------------------------------------------


	push		ebp
	mov			ebp, esp
	pushad

	mov			ecx, 0 
	mov			ecx, 10 ; move ARRAYSIZE into ECX
	mov			edi, [ebp+24] ;address of array that we're storing values in 
	
arrayFill:

	displayStr	[ebp+16]
	getStr	[ebp+12], [ebp+8] ;value is in the variable UserInput
	
	mov			esi, [ebp+12] ;userInput to esi
	mov			ebx, 0			;EBX will keep track of the number 

	stringtoint:

			cld
			mov			eax, 0 ;clears eax

			lodsb				;loads first character into AL/EAX
								; and increments ESI
			
			cmp			eax, 0		; if it's zero, we quit
			je			theend

			cmp			eax, 2Bh	;does it have a plus sign?
			je			stringtoint

			cmp			eax, 2Dh	; is it negative?
			jne			convert

			push		edi
			mov			edi, 1
			jmp			stringtoint

		convert:
							
							;VERIFICATION
			
			cmp			eax, 30h  ;low limit
			jb			error

			cmp			eax, 39h
			ja			error


								;CONVERSION
			push		eax				;saves character in eax

			mov			eax, ebx			
			mov			edx, 10			;mul current ebx by 10
			mul			edx
			mov			ebx, eax		;put it back in ebx 

			pop			eax	
			sub			eax, 48		;convert, subtract 48
			add			ebx, eax   ;add eax to ebx (where we are saving the full number) 

			jmp		stringtoint
			
			error:
				displayStr	[ebp+28]
				call		CrLf
				jmp			arrayFill
			
		theend:
				
				cmp			edi, 1
				jne			store
				pop			edi
				imul		ebx, -1

		store:

			mov				eax, ebx									
			stosd		   ;stores accumulated value in array, increments
			loop	arrayFill
		

	popad	
	pop	ebp
	ret 24

readVal		ENDP

; ------------------------------------------------------------------
writeVal	PROC
; 
; Description: Converts array of integers ( user's input) back to 
; strings, and invokes displayString macro to produce the output
; Receives:	@minus, @ spaces, @ array, @urnumbs,@toStr
; Returns: converts and prints the array of integers entered by user
; Preconditions: array is filled with signed integers from user,
; strings and variable toStr are correctly set 
; Registers changed: eax, ebx, ecx, edx, edi, esi 
;
; ------------------------------------------------------------------


	push	ebp
	mov		ebp, esp
	pushad

	displayStr	[ebp+12]
	call		CrLf

	mov			esi, [ebp+16]
	mov			ecx, 10
	

loop1:
	 
	mov			eax, [esi]
	mov			edi, [ebp+8]	; put toStr in edi 
	push		ecx
	mov			ecx, 0 

	test		eax, eax
	js			negative

	
	convert:
		
		cld

		mov			ebx, 10
		cdq
		idiv		ebx
		push		edx
		inc			ecx 

		cmp			eax, 0
		je			displayit
		jmp			convert
	
	negative:	
		neg			eax  ;make it positive again
		displayStr	[ebp+24]
		jmp			convert
	

	displayit:
						
		pop			edx
		add			edx, 48
		mov			[edi], edx
		displayStr	[ebp+8]
		loop		displayit

		displayStr  [ebp+20]
		pop			ecx

;loop to clear toStr byte array

		push		ecx
		push		eax

		mov			ecx, 12

	loop2:			
		mov			edi, [ebp+8]
		mov			eax, 0
		mov			[edi], eax 
		loop		loop2


		pop			eax
		pop			ecx

		add			esi, 4

		loop		loop1

		call		CrLf

	popad 
	pop		ebp
	ret		20

writeVal	ENDP


; ------------------------------------------------------------------
sumAndAvg		PROC
; 
; Description: Finds the sum and average of a list of integers
; Receives:		@ avgStr , @avg(variable), @sumStr, @sum(variable), 
;@array
; Returns: the sum and average of the numbers in the array in variables 
; sum and avg
; Preconditions: array is filled with signed integers from user,
; strings and variables are correctly set/initialized 
; Registers changed: eax, ebx, ecx, edx, esi 
;
; ------------------------------------------------------------------



	push		ebp
	mov			ebp, esp
	pushad

	mov			ecx, 10
	mov			esi, [ebp+8]
	mov			edx, 0		; edx is the accumulator

sumLoop:
	
	mov			eax, [esi]
	add			edx, eax
	add			esi, 4
	loop		sumloop

	mov			eax, edx
	displayStr	[ebp+16]
	call		WriteInt
	call		CrLf

	mov			ebx, 10
	cdq
	idiv			ebx
	displayStr	[ebp+24]
	call		WriteInt

	popad
	pop			ebp
	ret	20

sumAndAvg		ENDP

; ------------------------------------------------------------------
goodbye	PROC
; 
; Description: says goodbye to user :(
; Receives: @goodbye string
; Preconditions: goodbye string is correctly set 
; Registers changed: edx changed by displayStr macro 
;
; ------------------------------------------------------------------

	push		ebp
	mov			ebp, esp
	pushad

	call		CrLf
	displayStr	[ebp+8]

	popad
	pop			ebp
	ret 4

goodbye		ENDP

END main

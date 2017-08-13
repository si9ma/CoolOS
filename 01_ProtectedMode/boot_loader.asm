; File: boot_loader.asm
; Author: Beta
; Blog: http://www.hellobeta.me
; Mode: 16 bits
; Syntax: NASM
; Function: boot BetaOS

	NUM EQU 40				; the number of sector we need to read

	[BITS 16]				; tell the assembler that its a 16 bit code
	[ORG 0x7c00]			; tells the assembler that where the code will

; Stand FAT12 format floppy code(Reference: http://wiki.osdev.org/FAT#FAT_12)
; BPB (BIOS Parameter Block)

	JMP		entry			; jump to entry
	DB		0x90			; NOP
	DB		" BetaOS "		; OEM identifier,must 8 bytes.
	DW		512				; The number of Bytes per sector		
	DB		1				; Number of sectors per cluster.	
	DW		1				; Number of reserved sectors. 
	DB		2				; Number of File Allocation Tables (FAT's) on the storage media.(Often this value is 2)
	DW		224				; Number of directory entries.
	DW		2880			; The total sectors in the logical volume.		
	DB		0xf0			; This Byte indicates the media descriptor type.			
	DW		9				; Number of sectors per FAT.
	DW		18				; Number of sectors per track.	
	DW		2				; Number of heads or sides on the storage media.
	DD		0				; Number of hidden sectors.
	DD		2880			; Large amount of sector on media.
	DB		0				; Drive number. 
	DB		0				; Flags in Windows NT. 
	DB		0x29			; Signature (must be 0x28 or 0x29).
	DD		0xffffffff		; VolumeID 'Serial' number.
	DB		"BetaOS     "	; Volume label string,must 11 bytes.
	DB		"FAT12   "		; System identifier string.must 8 bytest.		

; Boot Code
entry:

; Init the register
; BIOS have set CS to 0x0000,set IP to 0x7C00
; We need to init SS and SP
; There are almost 30 KiB at 0x00500~0x07BFF is guaranteed free for use,
; So,set SS to 0x0000,set SP to 0x7c00,when we first push (SP-2)
; Reference: http://wiki.osdev.org/Memory_Map_(x86)#Overview
; Reference: https://en.wikipedia.org/wiki/BIOS#Boot_environment
	MOV		AX,0
	MOV		SS,AX
	MOV		SP,0x7c00
	MOV		DS,AX

; Print msg
	MOV		SI,msg			; Move the address of message to SI
	CALL	putloop			; Print

; Read data into memory from floppy
; ES:BX=where the data will.0x7E00~0x9FBFF is free to use.
; So,set ES to 0x7E00,set BX to 0x0.
; Reference: http://wiki.osdev.org/Memory_Map_(x86)#Overview
	MOV		AX,0x7E00		
	MOV		ES,AX
	MOV		CH,0			; cylinder number=0
	MOV		DH,0			; head number=0
	MOV		CL,2			; sector number=2,read from second sector.
	MOV		DI,0			; record the number of sector we have read

; Loop
readloop:
	MOV		SI,0			; Use SI to record the number of read errors for every sector.reset to 0 when read a new sector.

; Read data
read:
	MOV		AH,0X02			; Read sector into memory
	MOV		AL,1			; Read just 1 sector
	MOV		BX,0			; Read into ES:BX
	MOV		DL,0x00			; drive number=0
	INT		0x13			; Read sector into memory.Reference: http://www.ctyme.com/intr/rb-0607.htm
	JNC		next			; If no error,read next sector
	ADD		SI,1			; the number of read error +1
	CMP		SI,5
	JAE		error			; if the number of read error=5,print error message.

; reset disk system
	MOV		AH,0X00
	MOV		DL,0x00			; Drive 00
	INT		0x13
	JMP		read			; retry

; next sector
next:
	ADD		DI,1			; increase the number of sectors we have read
	CMP		DI,NUM
	JE		success			; if enough,jump to fin
	MOV		AX,ES
	ADD		AX,0x20
	MOV		ES,AX			
	ADD		CL,1			; next sector
	CMP		CL,18	
	JBE		readloop		; A cylinder just have 18 sector,if CL>18,next head
	MOV		CL,1	
	ADD		DH,1			
	CMP		DH,2
	JB		readloop		; just have two head,if DH>=2,next cylinder
	MOV		DH,0
	ADD		CH,1
	JMP		readloop

error:
	MOV		SI,error_msg
	CALL	putloop
	JMP		fin

success:
	MOV		SI,success_msg
	CALL	putloop
	JMP		fin

; Print string on the screen
putloop:
	MOV		AL,[SI]
	ADD		SI,1			
	CMP		AL,0
	JE		done			; Done!return!
	MOV		AH,0x0e			; Display a character
	MOV		BX,15			; Color
	INT		0x10			; Bios video display.Reference: http://www.ctyme.com/intr/rb-0106.htm
	JMP		putloop
done:
	ret

; Infinite loop
fin:
	HLT						; Halt
	JMP		fin				; Loop

; Message
msg:
	DB		0x0a, 0x0a	    ; Two line feed
	DB		"******************************"
	DB		0x0d			; One carriage return
	DB		0x0a			; One line feed.0x0d+0x0a==\n
	DB		"Hello World"
	DB		0x0d			; One carriage return
	DB		0x0a			; One line feed 
	DB		"This is BetaOS"
	DB		0x0d			; One carriage return
	DB		0x0a			; One line feed 
	DB		"Author: Beta"
	DB		0x0d			; One carriage return
	DB		0x0a			; One line feed 
	DB		"Blog: http://www.hellobeta.me"
	DB		0x0d			; One carriage return
	DB		0x0a			; One line feed 
	DB		"******************************"
	DB		0x0d			; One carriage return
	DB		0x0a			; One line feed 
	DB		0				; End of String

error_msg:
	DB		0x0a,0x0a
	DB		"************"
	DB		0x0d,0x0a
	DB		"load error"
	DB		0x0d,0x0a
	DB		"************"
	DB		0x0d,0x0a

success_msg:
	DB		0x0a,0x0a
	DB		"************"
	DB		0x0d,0x0a
	DB		"load success"
	DB		0x0d,0x0a
	DB		"************"
	DB		0x0d,0x0a

	TIMES 510-($-$$) db 0   ; Fill the rest of sector with 0
	DB	0x55, 0xaa          ; Add boot signature at the end of bootloader

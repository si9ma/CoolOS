; File: hello.asm
; Author: Beta
; Blog: http://www.hellobeta.me
; Mode: 16 bits
; Syntax: NASM
; Function: Print a "hello" message on the screen when boot

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
	MOV		SI,msg			; Move the message to SI

putloop:
	MOV		AL,[SI]
	ADD		SI,1			
	CMP		AL,0
	JE		fin				; Done!jump to fin
	MOV		AH,0x0e			; Display a character
	MOV		BX,15			; Color
	INT		0x10			; Bios video display.Reference: http://www.ctyme.com/intr/rb-0106.htm
	JMP		putloop

; Infinite loop
fin:
	HLT						; Halt
	JMP		fin				; Loop

; Message
msg:
	DB		0x0a, 0x0a	    ; Two line feed
	DB		"************"
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
	DB		"************"
	DB		0x0d			; One carriage return
	DB		0x0a			; One line feed 
	DB		0				; End of String

	TIMES 510-($-$$) db 0   ; Fill the rest of sector with 0
	DB	0x55, 0xaa          ; Add boot signature at the end of bootloader

# File: bootasm.S
# Author: si9ma
# Blog: http://www.coolcodes.me
# Reference: https://github.com/mit-pdos/xv6-public/blob/master/bootasm.S
# Reference: https://github.com/zchrissirhcz/osask-linux/blob/master/day3.9/kernel/entry.S 

#include "mmu.h"

# Start the CPU: switch to 32-bit protected mode, jump into C.
# The BIOS loads this code from the first sector of the hard disk into
# memory at physical address 0x7c00 and starts executing in real mode
# with %cs=0 %ip=7c00.

#define LEDS			0x0ff1
#define VMODE			0x0ff2			
#define SCRNX			0x0ff4			
#define SCRNY			0x0ff6			
#define VRAM			0x0ff8			

.set PROT_MODE_CSEG, 0x8			# kernel code segment selector
.set PROT_MODE_DSEG, 0x10			# kernel data segment selector
.set CR0_PE_ON, 0x1					# protected mode enable flag

.globl start

start:
	.code16							# Assemble for 16-bit mode

	# Zero data segment registers DS, ES, and SS.
	 xorw    %ax,%ax				# Segment number zero
	 movw    %ax,%ds				# -> Data Segment
	 movw    %ax,%es				# -> Extra Segment
	 movw    %ax,%ss				# -> Stack Segment

	# set video mode.VGA,320x200x8bit,256-color
	# Reference: http://www.ctyme.com/intr/rb-0069.htm
	movb	$0x13,%al   
	movb	$0x00,%ah
	int		$0x10

	#save video info
	movb	$8,(VMODE)				# 8-bit,256-color
	movw	$320,(SCRNX)
	movw	$200,(SCRNY)
	movl	$0x000a0000,(VRAM)		# Reference: https://en.wikipedia.org/wiki/Video_Graphics_Array#Addressing_details

	# get keyboard shift status
	# Reference: http://www.ctyme.com/itr/rb-1756.htm
	# Bit(s)  Description
	#  7	  Insert active
	#  6	  CapsLock active
	#  5      NumLock active
	#  4      ScrollLock active
	#  3      Alt key pressed (either Alt on 101/102-key keyboards)
	#  2      Ctrl key pressed (either Ctrl on 101/102-key keyboards)
	#  1      left shift key pressed
	#  0      right shift key pressed
	movb	$0x02,%ah 
	int     $0x16			
	movb	%al,(LEDS)

	# diplay message on the screen
	movw	$msg,%si
	call	putloop

	# test whether the A20 address line was already enabled
	call	check_a20
	cmpw	$1,%ax
	jz		skip

# A20 haven't been enabled,continue to enable it
continue:
	movw	$disable_msg,%si
	call	putloop
	movw	$doing_msg,%si
	call	putloop
	jmp		enable_A20

# A20 was already enabled,skip enable_A20
skip:
	movw	$enable_msg,%si
	call	putloop
	jmp		switch_to_protected

# Enable A20:
#   For backwards compatibility with the earliest PCs, physical
#   address line 20 is tied low, so that addresses higher than
#   1MB wrap around to zero by default.  This code undoes this. 
# 
# Reference(8042 controller): http://wiki.osdev.org/%228042%22_PS/2_Controller
# Reference(A20 line): http://wiki.osdev.org/A20_Line#Enabling
enable_A20:
	pushf						# store flag
	cli

# There are four methods to enable A20
# methods 1:

	# disable keyboard
	call	a20wait_write
	movb	$0xAD,%al
	outb	%al,$0x64

	# read controller output port
	call	a20wait_write
	movb	$0xD0,%al
	outb	%al,$0x64

	call	a20wait_read
	inb		$0x60,%al
	push	%ax

	# write controller output port
	call	a20wait_write
	movb	$0xD1,%al
	outb	%al,$0x64

	call	a20wait_write
	pop		%ax
	orb		$2,%al						# set a20 gate to 1
	out		%al,$0x60

	# enable keyboard
	call	a20wait_write
	movb	$0xAE,%al
	outb	%al,$0x64

# methods 2:

/*
seta20.1:
	inb     $0x64,%al               # Wait for not busy
	testb   $0x2,%al
	jnz     seta20.1

	movb    $0xd1,%al               # 0xd1 -> port 0x64
	outb    %al,$0x64

seta20.2:
	inb     $0x64,%al               # Wait for not busy
	testb   $0x2,%al
	jnz     seta20.2

	movb    $0xdf,%al               # 0xdf -> port 0x60
	outb    %al,$0x60
*/

# methods 3(Fast A20):

/*
	inb		$0x92,%al
	orb		$2,%al
	outb	%al,$0x92
*/

# methods 4(Fast A20):
	
/*
	movw	$0x2401, %ax
	int		$0x15
*/

	popf							# restore flags

	# test whether the A20 address line was already enabled
	call	check_a20
	cmpw	$1,%ax
	jz		success

# fail to enable A20
failure:
	movw	$failure_msg,%si
	call	putloop
fin:
	hlt
	jmp		fin

# success to enable A20
success:
	movw	$success_msg,%si
	call	putloop

	# continue to switch to protected mode
	jmp		switch_to_protected

# Function: putloop
# 
# Purpose: Print a string on the screen
# 
# Return: null
putloop:
	movb	(%si),%al
	add		$1,%si
	cmp		$0,%al
	je		done							# done!return!
	movb	$0x0e,%ah
	movw	$15,%bx
	int		$0x10							# Reference: http://www.ctyme.com/intr/rb-0106.htm
	jmp		putloop
done:
	ret	

# Function: a20wait_read
#
# Purpose: wait output buffer status is full
#
# Return: null
a20wait_read:
	inb		$0x64,%al
	testb	$1,%al							# bit-0(Ouput buffer status)
	jz		a20wait_read
	ret

# Function: a20wait_write
#
# Purpose: wait input buffer status is empty
#
# Return: null
a20wait_write:
	inb		$0x64,%al
	testb	$2,%al							# bit-1(Input buffer status)	
	jnz		a20wait_write
	ret

# Function: check_a20
#
# Purpose: to check the status of the a20 line in a completely self-contained state-preserving way.
#          The function can be modified as necessary by removing push's at the beginning and their
#          respective pop's at the end if complete self-containment is not required.
#
# Returns: 0 in ax if the a20 line is disabled (memory wraps around)
#          1 in ax if the a20 line is enabled (memory does not wrap around)
check_a20:
    pushf
    push	%ds
    push	%es
    push	%di
    push	%si

	# disable interrupt
    cli

	# set es to 0
    xorw	%ax,%ax
    movw	%ax,%es

	# set ds to 0xFFFF
    not		%ax
    movw	%ax,%ds

	# store 0x0000:0x0500 and 0xffff:0x0510 to stack
    movw	$0x0500,%di
    movw	$0x0510,%si

	movb	%es:(%di),%al
    push	%ax

	movb	%ds:(%si),%al
    push	%ax

	# set 0x0000:0x0500 to 0x00,0xffff:0x0510 to 0xff
	movb	$0x00,%es:(%di)
	movb	$0xff,%ds:(%si)

	cmpb	$0xff,%es:(%di)

	# restore 0x0000:0x0500 and 0xffff:0x0510
    pop		%ax
	movb	%al,%ds:(%si)

    pop		%ax
	movb	%al,%es:(%di)

	movw	$0,%ax
    je check_a20__exit

	movw	$1,%ax

check_a20__exit:
    pop		%si
    pop		%di
    pop		%es
    pop		%ds
    popf

	ret

# data
msg:
	.asciz "\nThis is CoolOS\r\n\n"

enable_msg:
	.asciz "\r\nA20 was already enabled,skiping...\r\n\n"

disable_msg:
	.asciz "\r\nA20 haven't been enabled\r\n\n"

doing_msg:
	.asciz "\r\nEnabling A20...\r\n\n"

failure_msg:
	.asciz "\r\nFail to enable A20...\r\n\n"

success_msg:
	.asciz "\r\nSuccess to enable A20\r\n\n"

# Switch from real to protected mode.  Use a bootstrap GDT that makes
# virtual addresses map directly to physical addresses so that the
# effective memory map doesn't change during the transition.
switch_to_protected:
	
	cli					

	lgdt    gdtdesc					# load gdt info into gdt register(gdtr)
	movl    %cr0, %eax
	orl     $CR0_PE_ON, %eax
	movl    %eax, %cr0

# Complete the transition to 32-bit protected mode by using a long jmp
# to reload %cs and %eip.  The segment descriptors are set up with no
# translation, so that the mapping is still the identity mapping.
	ljmp    $PROT_MODE_CSEG, $protcseg

.code32                     # Assemble for 32-bit mode
protcseg:
	# Set up the protected-mode data segment registers
	movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
	movw    %ax, %ds                # -> DS: Data Segment
	movw    %ax, %es                # -> ES: Extra Segment
	movw    %ax, %fs                # -> FS
	movw    %ax, %gs                # -> GS
	movw    %ax, %ss                # -> SS: Stack Segment

	# Set up the stack pointer and call into C.
	movl    $start, %esp
	call bootmain

# If bootmain returns (it shouldn't), loop.
spin:
	hlt
	jmp spin


# Bootstrap GDT
	.p2align 2                          # force 4 byte alignment.2^2

# temporary gdt
gdt:
	SEG_NULL							# null seg
	SEG(STA_X|STA_R, 0x0, 0xffffffff)	# code seg
	SEG(STA_W, 0x0, 0xffffffff)	        # data seg

gdtdesc:
	.word   (gdtdesc-gdt-1)                 # sizeof(gdt) - 1
	.long   gdt                             # address gdt(base address)

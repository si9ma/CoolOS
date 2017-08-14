
kernel.out:     file format elf32-i386


Disassembly of section .text:

0000c400 <start>:

start:
	.code16							# Assemble for 16-bit mode

	# Zero data segment registers DS, ES, and SS.
	 xorw    %ax,%ax				# Segment number zero
    c400:	31 c0                	xor    %eax,%eax
	 movw    %ax,%ds				# -> Data Segment
    c402:	8e d8                	mov    %eax,%ds
	 movw    %ax,%es				# -> Extra Segment
    c404:	8e c0                	mov    %eax,%es
	 movw    %ax,%ss				# -> Stack Segment
    c406:	8e d0                	mov    %eax,%ss

	# set video mode.VGA,320x200x8bit,256-color
	# Reference: http://www.ctyme.com/intr/rb-0069.htm
	movb	$0x13,%al   
    c408:	b0 13                	mov    $0x13,%al
	movb	$0x00,%ah
    c40a:	b4 00                	mov    $0x0,%ah
	int		$0x10
    c40c:	cd 10                	int    $0x10

	#save video info
	movb	$8,(VMODE)				# 8-bit,256-color
    c40e:	c6 06 f2             	movb   $0xf2,(%esi)
    c411:	0f 08                	invd   
	movw	$320,(SCRNX)
    c413:	c7 06 f4 0f 40 01    	movl   $0x1400ff4,(%esi)
	movw	$200,(SCRNY)
    c419:	c7 06 f6 0f c8 00    	movl   $0xc80ff6,(%esi)
	movl	$0x000a0000,(VRAM)		# Reference: https://en.wikipedia.org/wiki/Video_Graphics_Array#Addressing_details
    c41f:	66 c7 06 f8 0f       	movw   $0xff8,(%esi)
    c424:	00 00                	add    %al,(%eax)
    c426:	0a 00                	or     (%eax),%al
	#  4      ScrollLock active
	#  3      Alt key pressed (either Alt on 101/102-key keyboards)
	#  2      Ctrl key pressed (either Ctrl on 101/102-key keyboards)
	#  1      left shift key pressed
	#  0      right shift key pressed
	movb	$0x02,%ah 
    c428:	b4 02                	mov    $0x2,%ah
	int     $0x16			
    c42a:	cd 16                	int    $0x16
	movb	%al,(LEDS)
    c42c:	a2 f1 0f be f7       	mov    %al,0xf7be0ff1

	# diplay message on the screen
	movw	$msg,%si
    c431:	c4                   	(bad)  
	call	putloop
    c432:	e8 66 00 e8 84       	call   84e8c49d <__bss_start+0x84e7fe15>

	# test whether the A20 address line was already enabled
	call	check_a20
    c437:	00 83 f8 01 74 0e    	add    %al,0xe7401f8(%ebx)

0000c43d <continue>:
	cmpw	$1,%ax
	jz		skip

# A20 haven't been enabled,continue to enable it
continue:
	movw	$disable_msg,%si
    c43d:	be 32 c5 e8 58       	mov    $0x58e8c532,%esi
	call	putloop
    c442:	00 be 50 c5 e8 52    	add    %bh,0x52e8c550(%esi)
	movw	$doing_msg,%si
	call	putloop
    c448:	00 eb                	add    %ch,%bl
	jmp		enable_A20
    c44a:	09                   	.byte 0x9

0000c44b <skip>:

# A20 was already enabled,skip enable_A20
skip:
	movw	$enable_msg,%si
    c44b:	be 0a c5 e8 4a       	mov    $0x4ae8c50a,%esi
	call	putloop
    c450:	00 e9                	add    %ch,%cl
	jmp		switch_to_protected
    c452:	47                   	inc    %edi
    c453:	01                   	.byte 0x1

0000c454 <enable_A20>:
#   1MB wrap around to zero by default.  This code undoes this. 
# 
# Reference(8042 controller): http://wiki.osdev.org/%228042%22_PS/2_Controller
# Reference(A20 line): http://wiki.osdev.org/A20_Line#Enabling
enable_A20:
	pushf						# store flag
    c454:	9c                   	pushf  
	cli
    c455:	fa                   	cli    

# There are four methods to enable A20
# methods 1:

	# disable keyboard
	call	a20wait_write
    c456:	e8 5c 00 b0 ad       	call   adb0c4b7 <__bss_start+0xadaffe2f>
	movb	$0xAD,%al
	outb	%al,$0x64
    c45b:	e6 64                	out    %al,$0x64

	# read controller output port
	call	a20wait_write
    c45d:	e8 55 00 b0 d0       	call   d0b0c4b7 <__bss_start+0xd0affe2f>
	movb	$0xD0,%al
	outb	%al,$0x64
    c462:	e6 64                	out    %al,$0x64

	call	a20wait_read
    c464:	e8 47 00 e4 60       	call   60e4c4b0 <__bss_start+0x60e3fe28>
	inb		$0x60,%al
	push	%ax
    c469:	50                   	push   %eax

	# write controller output port
	call	a20wait_write
    c46a:	e8 48 00 b0 d1       	call   d1b0c4b7 <__bss_start+0xd1affe2f>
	movb	$0xD1,%al
	outb	%al,$0x64
    c46f:	e6 64                	out    %al,$0x64

	call	a20wait_write
    c471:	e8 41 00 58 0c       	call   c58c4b7 <__bss_start+0xc57fe2f>
	pop		%ax
	orb		$2,%al						# set a20 gate to 1
    c476:	02 e6                	add    %dh,%ah
	out		%al,$0x60
    c478:	60                   	pusha  

	# enable keyboard
	call	a20wait_write
    c479:	e8 39 00 b0 ae       	call   aeb0c4b7 <__bss_start+0xaeaffe2f>
	movb	$0xAE,%al
	outb	%al,$0x64
    c47e:	e6 64                	out    %al,$0x64
/*
	movw	$0x2401, %ax
	int		$0x15
*/

	popf							# restore flags
    c480:	9d                   	popf   

	# test whether the A20 address line was already enabled
	call	check_a20
    c481:	e8 38 00 83 f8       	call   f883c4be <__bss_start+0xf882fe36>
	cmpw	$1,%ax
    c486:	01                   	.byte 0x1
	jz		success
    c487:	74 09                	je     c492 <success>

0000c489 <failure>:

# fail to enable A20
failure:
	movw	$failure_msg,%si
    c489:	be 65 c5 e8 0c       	mov    $0xce8c565,%esi
	...

0000c48f <fin>:
	call	putloop
fin:
	hlt
    c48f:	f4                   	hlt    
	jmp		fin
    c490:	eb fd                	jmp    c48f <fin>

0000c492 <success>:

# success to enable A20
success:
	movw	$success_msg,%si
    c492:	be 80 c5 e8 03       	mov    $0x3e8c580,%esi
	call	putloop
    c497:	00 e9                	add    %ch,%cl

	# continue to switch to protected mode
	jmp		switch_to_protected
    c499:	00 01                	add    %al,(%ecx)

0000c49b <putloop>:
# 
# Purpose: Print a string on the screen
# 
# Return: null
putloop:
	movb	(%si),%al
    c49b:	8a 04 83             	mov    (%ebx,%eax,4),%al
	add		$1,%si
    c49e:	c6 01 3c             	movb   $0x3c,(%ecx)
	cmp		$0,%al
    c4a1:	00 74 09 b4          	add    %dh,-0x4c(%ecx,%ecx,1)
	je		done							# done!return!
	movb	$0x0e,%ah
    c4a5:	0e                   	push   %cs
	movw	$15,%bx
    c4a6:	bb 0f 00 cd 10       	mov    $0x10cd000f,%ebx
	int		$0x10							# Reference: http://www.ctyme.com/intr/rb-0106.htm
	jmp		putloop
    c4ab:	eb ee                	jmp    c49b <putloop>

0000c4ad <done>:
done:
	ret	
    c4ad:	c3                   	ret    

0000c4ae <a20wait_read>:
#
# Purpose: wait output buffer status is full
#
# Return: null
a20wait_read:
	inb		$0x64,%al
    c4ae:	e4 64                	in     $0x64,%al
	testb	$1,%al							# bit-0(Ouput buffer status)
    c4b0:	a8 01                	test   $0x1,%al
	jz		a20wait_read
    c4b2:	74 fa                	je     c4ae <a20wait_read>
	ret
    c4b4:	c3                   	ret    

0000c4b5 <a20wait_write>:
#
# Purpose: wait input buffer status is empty
#
# Return: null
a20wait_write:
	inb		$0x64,%al
    c4b5:	e4 64                	in     $0x64,%al
	testb	$2,%al							# bit-1(Input buffer status)	
    c4b7:	a8 02                	test   $0x2,%al
	jnz		a20wait_write
    c4b9:	75 fa                	jne    c4b5 <a20wait_write>
	ret
    c4bb:	c3                   	ret    

0000c4bc <check_a20>:
#          respective pop's at the end if complete self-containment is not required.
#
# Returns: 0 in ax if the a20 line is disabled (memory wraps around)
#          1 in ax if the a20 line is enabled (memory does not wrap around)
check_a20:
    pushf
    c4bc:	9c                   	pushf  
    push	%ds
    c4bd:	1e                   	push   %ds
    push	%es
    c4be:	06                   	push   %es
    push	%di
    c4bf:	57                   	push   %edi
    push	%si
    c4c0:	56                   	push   %esi

	# disable interrupt
    cli
    c4c1:	fa                   	cli    

	# set es to 0
    xorw	%ax,%ax
    c4c2:	31 c0                	xor    %eax,%eax
    movw	%ax,%es
    c4c4:	8e c0                	mov    %eax,%es

	# set ds to 0xFFFF
    not		%ax
    c4c6:	f7 d0                	not    %eax
    movw	%ax,%ds
    c4c8:	8e d8                	mov    %eax,%ds

	# store 0x0000:0x0500 and 0xffff:0x0510 to stack
    movw	$0x0500,%di
    c4ca:	bf 00 05 be 10       	mov    $0x10be0500,%edi
    movw	$0x0510,%si
    c4cf:	05 26 8a 05 50       	add    $0x50058a26,%eax

	movb	%es:(%di),%al
    push	%ax

	movb	%ds:(%si),%al
    c4d4:	8a 04 50             	mov    (%eax,%edx,2),%al
    push	%ax

	# set 0x0000:0x0500 to 0x00,0xffff:0x0510 to 0xff
	movb	$0x00,%es:(%di)
    c4d7:	26 c6 05 00 c6 04 ff 	movb   $0x26,%es:0xff04c600
    c4de:	26 
	movb	$0xff,%ds:(%si)

	cmpb	$0xff,%es:(%di)
    c4df:	80 3d ff 58 88 04 58 	cmpb   $0x58,0x48858ff
	# restore 0x0000:0x0500 and 0xffff:0x0510
    pop		%ax
	movb	%al,%ds:(%si)

    pop		%ax
	movb	%al,%es:(%di)
    c4e6:	26 88 05 b8 00 00 74 	mov    %al,%es:0x740000b8

	movw	$0,%ax
    je check_a20__exit
    c4ed:	03                   	.byte 0x3

	movw	$1,%ax
    c4ee:	b8                   	.byte 0xb8
    c4ef:	01 00                	add    %eax,(%eax)

0000c4f1 <check_a20__exit>:

check_a20__exit:
    pop		%si
    c4f1:	5e                   	pop    %esi
    pop		%di
    c4f2:	5f                   	pop    %edi
    pop		%es
    c4f3:	07                   	pop    %es
    pop		%ds
    c4f4:	1f                   	pop    %ds
    popf
    c4f5:	9d                   	popf   

	ret
    c4f6:	c3                   	ret    

0000c4f7 <msg>:
    c4f7:	0a 54 68 69          	or     0x69(%eax,%ebp,2),%dl
    c4fb:	73 20                	jae    c51d <enable_msg+0x13>
    c4fd:	69 73 20 42 65 74 61 	imul   $0x61746542,0x20(%ebx),%esi
    c504:	4f                   	dec    %edi
    c505:	53                   	push   %ebx
    c506:	0d                   	.byte 0xd
    c507:	0a 0a                	or     (%edx),%cl
	...

0000c50a <enable_msg>:
    c50a:	0d 0a 41 32 30       	or     $0x3032410a,%eax
    c50f:	20 77 61             	and    %dh,0x61(%edi)
    c512:	73 20                	jae    c534 <disable_msg+0x2>
    c514:	61                   	popa   
    c515:	6c                   	insb   (%dx),%es:(%edi)
    c516:	72 65                	jb     c57d <failure_msg+0x18>
    c518:	61                   	popa   
    c519:	64 79 20             	fs jns c53c <disable_msg+0xa>
    c51c:	65 6e                	outsb  %gs:(%esi),(%dx)
    c51e:	61                   	popa   
    c51f:	62 6c 65 64          	bound  %ebp,0x64(%ebp,%eiz,2)
    c523:	2c 73                	sub    $0x73,%al
    c525:	6b 69 70 69          	imul   $0x69,0x70(%ecx),%ebp
    c529:	6e                   	outsb  %ds:(%esi),(%dx)
    c52a:	67                   	addr16
    c52b:	2e                   	cs
    c52c:	2e                   	cs
    c52d:	2e                   	cs
    c52e:	0d                   	.byte 0xd
    c52f:	0a 0a                	or     (%edx),%cl
	...

0000c532 <disable_msg>:
    c532:	0d 0a 41 32 30       	or     $0x3032410a,%eax
    c537:	20 68 61             	and    %ch,0x61(%eax)
    c53a:	76 65                	jbe    c5a1 <switch_to_protected+0x6>
    c53c:	6e                   	outsb  %ds:(%esi),(%dx)
    c53d:	27                   	daa    
    c53e:	74 20                	je     c560 <doing_msg+0x10>
    c540:	62 65 65             	bound  %esp,0x65(%ebp)
    c543:	6e                   	outsb  %ds:(%esi),(%dx)
    c544:	20 65 6e             	and    %ah,0x6e(%ebp)
    c547:	61                   	popa   
    c548:	62 6c 65 64          	bound  %ebp,0x64(%ebp,%eiz,2)
    c54c:	0d                   	.byte 0xd
    c54d:	0a 0a                	or     (%edx),%cl
	...

0000c550 <doing_msg>:
    c550:	0d 0a 45 6e 61       	or     $0x616e450a,%eax
    c555:	62 6c 69 6e          	bound  %ebp,0x6e(%ecx,%ebp,2)
    c559:	67 20 41 32          	and    %al,0x32(%bx,%di)
    c55d:	30 2e                	xor    %ch,(%esi)
    c55f:	2e                   	cs
    c560:	2e                   	cs
    c561:	0d                   	.byte 0xd
    c562:	0a 0a                	or     (%edx),%cl
	...

0000c565 <failure_msg>:
    c565:	0d 0a 46 61 69       	or     $0x6961460a,%eax
    c56a:	6c                   	insb   (%dx),%es:(%edi)
    c56b:	20 74 6f 20          	and    %dh,0x20(%edi,%ebp,2)
    c56f:	65 6e                	outsb  %gs:(%esi),(%dx)
    c571:	61                   	popa   
    c572:	62 6c 65 20          	bound  %ebp,0x20(%ebp,%eiz,2)
    c576:	41                   	inc    %ecx
    c577:	32 30                	xor    (%eax),%dh
    c579:	2e                   	cs
    c57a:	2e                   	cs
    c57b:	2e                   	cs
    c57c:	0d                   	.byte 0xd
    c57d:	0a 0a                	or     (%edx),%cl
	...

0000c580 <success_msg>:
    c580:	0d 0a 53 75 63       	or     $0x6375530a,%eax
    c585:	63 65 73             	arpl   %sp,0x73(%ebp)
    c588:	73 20                	jae    c5aa <switch_to_protected+0xf>
    c58a:	74 6f                	je     c5fb <bootmain+0x11>
    c58c:	20 65 6e             	and    %ah,0x6e(%ebp)
    c58f:	61                   	popa   
    c590:	62 6c 65 20          	bound  %ebp,0x20(%ebp,%eiz,2)
    c594:	41                   	inc    %ecx
    c595:	32 30                	xor    (%eax),%dh
    c597:	0d                   	.byte 0xd
    c598:	0a 0a                	or     (%edx),%cl
	...

0000c59b <switch_to_protected>:
# Switch from real to protected mode.  Use a bootstrap GDT that makes
# virtual addresses map directly to physical addresses so that the
# effective memory map doesn't change during the transition.
switch_to_protected:
	
	cli					
    c59b:	fa                   	cli    

	lgdt    gdtdesc					# load gdt info into gdt register(gdtr)
    c59c:	0f 01 16             	lgdtl  (%esi)
    c59f:	e4 c5                	in     $0xc5,%al
	movl    %cr0, %eax
    c5a1:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE_ON, %eax
    c5a4:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
    c5a8:	0f 22 c0             	mov    %eax,%cr0

# Complete the transition to 32-bit protected mode by using a long jmp
# to reload %cs and %eip.  The segment descriptors are set up with no
# translation, so that the mapping is still the identity mapping.
	ljmp    $PROT_MODE_CSEG, $protcseg
    c5ab:	ea                   	.byte 0xea
    c5ac:	b0 c5                	mov    $0xc5,%al
    c5ae:	08 00                	or     %al,(%eax)

0000c5b0 <protcseg>:

.code32                     # Assemble for 32-bit mode
protcseg:
	# Set up the protected-mode data segment registers
	movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
    c5b0:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds                # -> DS: Data Segment
    c5b4:	8e d8                	mov    %eax,%ds
	movw    %ax, %es                # -> ES: Extra Segment
    c5b6:	8e c0                	mov    %eax,%es
	movw    %ax, %fs                # -> FS
    c5b8:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs                # -> GS
    c5ba:	8e e8                	mov    %eax,%gs
	movw    %ax, %ss                # -> SS: Stack Segment
    c5bc:	8e d0                	mov    %eax,%ss

	# Set up the stack pointer and call into C.
	movl    $start, %esp
    c5be:	bc 00 c4 00 00       	mov    $0xc400,%esp
	call bootmain
    c5c3:	e8 22 00 00 00       	call   c5ea <bootmain>

0000c5c8 <spin>:

# If bootmain returns (it shouldn't), loop.
spin:
	hlt
    c5c8:	f4                   	hlt    
	jmp spin
    c5c9:	eb fd                	jmp    c5c8 <spin>
    c5cb:	90                   	nop

0000c5cc <gdt>:
	...
    c5d4:	ff                   	(bad)  
    c5d5:	ff 00                	incl   (%eax)
    c5d7:	00 00                	add    %al,(%eax)
    c5d9:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    c5e0:	00                   	.byte 0x0
    c5e1:	92                   	xchg   %eax,%edx
    c5e2:	cf                   	iret   
	...

0000c5e4 <gdtdesc>:
    c5e4:	17                   	pop    %ss
    c5e5:	00 cc                	add    %cl,%ah
    c5e7:	c5 00                	lds    (%eax),%eax
	...

0000c5ea <bootmain>:
void init_screen(int); 

//called by bootasm.S
void bootmain(void)
{
    c5ea:	55                   	push   %ebp
	//if color=-1.....
	if(color==-1)
	{
		//vram(0xa0000~0xaffff).
		//Reference: https://en.wikipedia.org/wiki/Video_Graphics_Array#Addressing_details
		for(int i=0xa0000;i<0xaffff;i++) 
    c5eb:	b8 00 00 0a 00       	mov    $0xa0000,%eax
{
    c5f0:	89 e5                	mov    %esp,%ebp
		{
			ptr=(char *)i;
			*ptr=i&0x0f;
    c5f2:	88 c2                	mov    %al,%dl
		for(int i=0xa0000;i<0xaffff;i++) 
    c5f4:	40                   	inc    %eax
			*ptr=i&0x0f;
    c5f5:	83 e2 0f             	and    $0xf,%edx
    c5f8:	88 50 ff             	mov    %dl,-0x1(%eax)
		for(int i=0xa0000;i<0xaffff;i++) 
    c5fb:	3d ff ff 0a 00       	cmp    $0xaffff,%eax
    c600:	75 f0                	jne    c5f2 <bootmain+0x8>
		asm("hlt"); //inline assembly
    c602:	f4                   	hlt    
    c603:	eb fd                	jmp    c602 <bootmain+0x18>

0000c605 <init_screen>:
{
    c605:	55                   	push   %ebp
		}
	}
	else
	{
		for(int i=0xa0000;i<0xaffff;i++)
    c606:	b8 00 00 0a 00       	mov    $0xa0000,%eax
{
    c60b:	89 e5                	mov    %esp,%ebp
    c60d:	8b 55 08             	mov    0x8(%ebp),%edx
	if(color==-1)
    c610:	83 fa ff             	cmp    $0xffffffff,%edx
    c613:	75 12                	jne    c627 <init_screen+0x22>
			*ptr=i&0x0f;
    c615:	88 c2                	mov    %al,%dl
		for(int i=0xa0000;i<0xaffff;i++) 
    c617:	40                   	inc    %eax
			*ptr=i&0x0f;
    c618:	83 e2 0f             	and    $0xf,%edx
    c61b:	88 50 ff             	mov    %dl,-0x1(%eax)
		for(int i=0xa0000;i<0xaffff;i++) 
    c61e:	3d ff ff 0a 00       	cmp    $0xaffff,%eax
    c623:	75 f0                	jne    c615 <init_screen+0x10>
    c625:	eb 0a                	jmp    c631 <init_screen+0x2c>
		{
			ptr=(char *)i;
			*ptr=color;
    c627:	88 10                	mov    %dl,(%eax)
		for(int i=0xa0000;i<0xaffff;i++)
    c629:	40                   	inc    %eax
    c62a:	3d ff ff 0a 00       	cmp    $0xaffff,%eax
    c62f:	75 f6                	jne    c627 <init_screen+0x22>
		}
	}
}
    c631:	5d                   	pop    %ebp
    c632:	c3                   	ret    

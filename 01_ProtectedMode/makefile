# Author: si9ma
# Blog: http://www.coolcodes.me

# Img file we will use to boot
IMG=CoolOS.img

# detect architecture for qemu Smartly.
ifeq ($(shell uname -m),x86_64)
	QEMU=qemu-system-x86_64
else
	QEMU=qemu-system-i386
endif

CFLAGS = -O -Wall -Werror -m32

LDFLAGS=-m elf_i386
addr=0xc400

img:boot_loader.bin kernel
	@dd if=/dev/zero of=$(IMG) count=2880 bs=512 			# Create a empty img file with size 2880*512 bytes
	@dd if=boot_loader.bin of=$(IMG) bs=512 conv=notrunc	# add boot_loader.bin to the first sector of img file(use conv=notrunc)
	mkdir -p floppy
	sudo mount -o loop $(IMG) floppy -o fat=12
	sudo cp kernel floppy
	sudo umount floppy
	rm floppy -rf

boot_loader.bin:	
	nasm -f bin -o boot_loader.bin boot_loader.asm

kernel:bootasm.o bootmain.o
	ld $(LDFLAGS) -N -Ttext $(addr) -o $@.out $^
	objcopy -S -O binary -j .text $@.out $@

bootasm.o:bootasm.S
	gcc $(CFLAGS) -c -o $@ $<

bootmain.o:bootmain.c
	gcc $(CFLAGS) -Os -c -o $@ $<

run:
# Update img file firstly.
	make img			
	@$(QEMU) -drive file=$(IMG),if=floppy

clean:
	rm -f *.bin $(IMG) *.o *.out kernel

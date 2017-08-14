# Author: Beta
# Blog: http://www.hellobeta.me

# Img file we will use to boot
IMG=BetaOS.img

# detect architecture for qemu Smartly.
ifeq ($(shell uname -m),x86_64)
	QEMU=qemu-system-x86_64
else
	QEMU=qemu-system-i386
endif

CFLAGS := $(CFLAGS) -O1 -fno-builtin -MD
CFLAGS += -fno-omit-frame-pointer
CFLAGS += -Wall -Wno-format -Wno-unused -Werror -gstabs -m32

LDFLAGS=-m elf_i386
addr=0xc400

img:boot_loader.bin kernel
	dd if=/dev/zero of=$(IMG) count=2880 bs=512 	# Create a empty img file with size 2880*512 bytes
	dd if=boot_loader.bin of=$(IMG) bs=512 conv=notrunc	# add boot_loader.bin to the first sector of img file(use conv=notrunc)
	mkdir -p floppy
	sudo mount -o loop $(IMG) floppy -o fat=12
	sudo cp kernel floppy
	sudo umount floppy
	rm floppy -rf

boot_loader.bin:	
	nasm -f bin -o boot_loader.bin boot_loader.asm

kernel:bootasm.o bootmain.o
	ld $(LDFLAGS) -N -e start -Ttext $(addr) -o $@.out $^
	objcopy -S -O binary -j .text $@.out $@

bootasm.o:bootasm.S
	gcc -nostdinc $(CFLAGS) -c -o $@ $<

bootmain.o:bootmain.c
	gcc -nostdinc $(CFLAGS) -Os -c -o $@ $<

run:
	make img			# Update img file firstly.
	$(QEMU) -drive file=$(IMG),if=floppy

clean:
	rm *.bin $(IMG) *.o *.out kernel *.d

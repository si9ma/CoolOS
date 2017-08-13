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

img:boot_loader.bin
	dd if=/dev/zero of=$(IMG) count=2880 bs=512 	# Create a empty img file with size 2880*512 bytes
	dd if=boot_loader.bin of=$(IMG) bs=512 conv=notrunc	# add boot_loader.bin to the first sector of img file(use conv=notrunc)

boot_loader.bin:	
	nasm -f bin -o boot_loader.bin boot_loader.asm

run:
	make img			# Update img file firstly.
	$(QEMU) -drive file=$(IMG),if=floppy

clean:
	rm boot_loader.bin $(IMG)

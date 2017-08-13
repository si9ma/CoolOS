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

img:hello_world.bin
	dd if=/dev/zero of=$(IMG) count=2880 bs=512 	# Create a empty img file with size 2880*512 bytes
	dd if=hello_world.bin of=$(IMG) bs=512 conv=notrunc	# add hello_world.bin to the first sector of img file(use conv=notrunc)

hello_world.bin:	
	nasm -f bin -o hello_world.bin hello_world.asm

run:
	make img			# Update img file firstly.
	$(QEMU) -drive file=$(IMG),if=floppy

clean:
	rm hello_world.bin $(IMG)

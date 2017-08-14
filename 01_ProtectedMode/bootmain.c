void init_screen(int); 

//called by bootasm.S
void bootmain(void)
{

	init_screen(-1);

	//Infinite loop
	while(1)
	{
		asm("hlt"); //inline assembly
	}
}

//init the screen
void init_screen(int color)
{
	char *ptr;//pointer

	//if color=-1.....
	if(color==-1)
	{
		//vram(0xa0000~0xaffff).
		//Reference: https://en.wikipedia.org/wiki/Video_Graphics_Array#Addressing_details
		for(int i=0xa0000;i<0xaffff;i++) 
		{
			ptr=(char *)i;
			*ptr=i&0x0f;
		}
	}
	else
	{
		for(int i=0xa0000;i<0xaffff;i++)
		{
			ptr=(char *)i;
			*ptr=color;
		}
	}
}

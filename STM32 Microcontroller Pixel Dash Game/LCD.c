#include "FinalProject.h"
#include "stm32l476xx.h"


void delay_ms(unsigned int ms) {
 volatile unsigned int i,j;
	for(i=0;i<ms;i++)
	{
		for(j=0;j<300;j++);
	}
}


void LCD_WriteCom8(unsigned char com) {
	
	unsigned char temp1;
	temp1 = com;
	
	//toggles enable to zero
	unsigned int tempE = GPIOB->ODR;
	tempE &= 0xFFFFFFEF;
	GPIOB->ODR |= tempE;
	
	//set RS to zero command mode
	unsigned int tempRS = GPIOB->ODR;
	tempRS &= 0xFFFFFFDF;
	GPIOB->ODR = tempRS;
	
	//delay tsu1
	delay_ms(10);
	
	//send first half of command
	GPIOB->ODR |= temp1;
	
	//toggle enable to one
	tempE = GPIOB->ODR;
	tempE |= 0x00000010;
	GPIOB->ODR = tempE;
	
	//delay
	delay_ms(10);
	
	//toggle enable to zero
	tempE = GPIOB->ODR;
	tempE &= 0xFFFFFFEF;
	GPIOB->ODR = tempE;
}

//reading input command
//sets second nybble of com to zero and stores in temp
//left shifts 4 bits and sets second nyble to zero store in temp
//toggle enable
//set RS to zero
//send first half of command
//toggle enable
//call delay function
//toggle enable
//set RS to zero
//send second half of command
//toggle enable
//call delay
//toggle enable
void LCD_WriteCom(unsigned char com) {
	
	unsigned char temp1, temp2;
	temp1 = (com>>4);
	temp2 = com & 0xF;
	
	//toggles enable to zero
	unsigned int tempE = GPIOB->ODR;
	tempE &= 0xFFFFFFEF;
	GPIOB->ODR = tempE;
	
	//set RS to zero command mode
	unsigned int tempRS = GPIOB->ODR;
	tempRS &= 0xFFFFFFDF;
	GPIOB->ODR = tempRS;
	
	//delay tsu1
	delay_ms(10);
	
	//send first half of command
	GPIOB->ODR &= 0xFFFFFFF0;
	GPIOB->ODR |= temp1;
	
	//toggle enable to one
	tempE = GPIOB->ODR;
	tempE |= 0x00000010;
	GPIOB->ODR = tempE;
	
	//delay
	delay_ms(10);
	
	//toggle enable to zero
	tempE = GPIOB->ODR;
	tempE &= 0xFFFFFFEF;
	GPIOB->ODR = tempE;
	
	//set RS to zero command mode
	tempRS = GPIOB->ODR;
	tempRS &= 0xFFFFFFDF;
	GPIOB->ODR = tempRS;
	
	//delay tsu1
	delay_ms(10);
	
	//send second half of command
	GPIOB->ODR &= 0xFFFFFFF0;
	GPIOB->ODR |= temp2;
	
	//toggle enable to one
	tempE = GPIOB->ODR;
	tempE |= 0x00000010;
	GPIOB->ODR = tempE;
	
	delay_ms(10);
	
	//toggle enable to zero
	tempE = GPIOB->ODR;
	tempE &= 0xFFFFFFEF;
	GPIOB->ODR = tempE;
	delay_ms(5);
}

//reading input data
//sets second nybble of dat to zero and stores in temp
//left shifts 4 bits and sets second nyble to zero store in temp
//toggle enable
//set RS to one
//send first half of command
//toggle enable
//call delay function
//toggle enable
//set RS to one
//send second half of command
//toggle enable
//call delay
//toggle enable
void LCD_WriteData(unsigned char dat) {
	unsigned char temp1, temp2;
	temp1 = (dat>>4);
	temp2 = dat&0xF;
	
	//toggles enable to zero
	unsigned int tempE = GPIOB->ODR;
	tempE &= 0xFFFFFFEF;
	GPIOB->ODR = tempE;
	
	//set RS to one data mode
	unsigned int tempRS = GPIOB->ODR;
	tempRS |= 0x00000020;
	GPIOB->ODR = tempRS;
	
	//delay tsu1
	delay_ms(10);
	
	//send first half of command
	GPIOB->ODR &= 0xFFFFFFF0;
	GPIOB->ODR |= temp1;
	
	//toggle enable to one
	tempE = GPIOB->ODR;
	tempE |= 0x00000010;
	GPIOB->ODR = tempE;
	
	//delay
	delay_ms(10);
	
	//toggle enable to zero
	tempE = GPIOB->ODR;
	tempE &= 0xFFFFFFEF;
	GPIOB->ODR = tempE;
	
	//set RS to one data mode
	tempRS = GPIOB->ODR;
	tempRS |= 0x00000020;
	GPIOB->ODR = tempRS;
	
	//delay tsu1
	delay_ms(10);
	
	//send second half of command
	GPIOB->ODR &= 0xFFFFFFF0;
	GPIOB->ODR |= temp2;
	
	//toggle enable to one
	tempE = GPIOB->ODR;
	tempE |= 0x00000010;
	GPIOB->ODR = tempE;
	
	delay_ms(10);
	
	//toggle enable to zero
	tempE = GPIOB->ODR;
	tempE &= 0xFFFFFFEF;
	GPIOB->ODR = tempE;
	delay_ms(5);
}

//Turn on HSI clock
//Enable clock B
//Configure GPIOB pins as outputs
//set LCD as 4bit mode and 2 line display
//Mode display on, cursor off, cursor blink off
//clear display
//set up CGRAM address to start at 0
void LCD_Init(void){
	
	// Enable the Internal High Speed oscillator (HSI)
	RCC->CR |= RCC_CR_HSION;
	while((RCC->CR & RCC_CR_HSIRDY) == 0);
	RCC->CFGR |= RCC_CFGR_SW_HSI;
	
	
	//Enable the clock to GPIO Port B
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN;
	
	//Configures GPIO PB0-5 as outputs 
	unsigned int temp = GPIOB->MODER;
	temp &= 0xFFFFF000;
	temp |= 0x00000555;
	GPIOB->MODER = temp;
	
	delay_ms(10);
	//sets 8 bt mode
	LCD_WriteCom(0x3);
	delay_ms(10);
	LCD_WriteCom(0x3);
	delay_ms(10);
	LCD_WriteCom(0x3);

	
	//sets 4 bit mode
	//LCD_WriteCom8(0x2);
	delay_ms(20);
	LCD_WriteCom(0x2);
	
	//set LCD as 4bit mode and 2 line display	
	delay_ms(20);
	LCD_WriteCom(0x28);
	delay_ms(10);


	
	//cursor and display
	LCD_WriteCom(0x06);
	delay_ms(10);
	//Mode display on, cursor off, cursor blink off
	LCD_WriteCom(0x0C);
	delay_ms(10);
	//clear display
	LCD_Clear();
	delay_ms(10);
	//set up CGRAM address to start at 0
	LCD_WriteCom(0x40);
	delay_ms(10);
}

void LCD_Clear(void){
  
	//clear display
	LCD_WriteCom(0x01);
}

//if 0 DDRAM starts at 00 elseif 1 DDRAM starts at 40
//while not equal to null pointer
//set DDRAM address to 40 (next line)
void LCD_DisplayString(unsigned int line, unsigned char *ptr) {
	
	unsigned char Start;
	if(line == 0){
		Start =(0x80);
	}
	else{
		Start = (0xC0);
	}
	
	for(unsigned char i=0;*ptr!='\0';i++){
		
		LCD_WriteCom(Start+i);
		LCD_WriteData(*ptr);
		ptr++;
	}
	
	
}


void LCD_DisplayChar(unsigned char position, unsigned char c) {
	
	unsigned char Start;
	
	Start = (0xC0 + position);
	
	LCD_WriteCom(Start);
	LCD_WriteData(c);

}


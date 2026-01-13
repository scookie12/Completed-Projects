#include "stm32l476xx.h"
#include <stdio.h>
#include "stdint.h"
#include "Timer.h"	


//main
//intialize
//
unsigned char Timer[3];
unsigned char ent;
unsigned char CountDown;


int main(void){
		
	Init();
	//SysTick_Initialize(160000);
	
	while(1){
		
		checkRow();
																														//check to see if Timer array function contains any invalid inputs that system cannot handle
		if(Timer[1] == '#' || Timer[2] == '#'){
			//convert array to value CountDown
			if(Timer[1] == '#'){
				CountDown = (Timer[0] - '0');
			}else if(Timer[2] == '#'){
				CountDown = (Timer[0] - '0')*10 + (Timer[1] - '0');
			}if(CountDown > 59){
				CountDown = 59;
			}
			//set Timer[]=0
			Timer[0] = '0';
			Timer[1] = '0';
			Timer[2] = '0';
			ent = 0;
			
			//call function that loads timer to correct starting location clockwise function
			Clockwise(CountDown);
			//call checkRow
			checkRow();
			//while Timer != #
			while(Timer[0] != '#'){
				//Timer = 0
				//call checkRow
				
				Timer[0] = 0;
				ent = 0;
				checkRow();
			}
			
			//call counter clockwise timer
			CounterClockwise(CountDown);
			
			Timer[0] = '0';
			Timer[1] = '0';
			Timer[2] = '0';
			ent = 0;
			
			//call buzzer sound.
			for(volatile int k = 0; k < 2500; k++){
			GPIOC->ODR |= GPIO_ODR_ODR_0;
				for(volatile int q = 0; q < 1000; q++);
			GPIOC->ODR &= 0xFFFFFFFE;
			}
			
		}else 
		Timer[2] = '0';
	}
	
	
	
}
	

//void SysTick_Initialize(unsigned int reload){
//	
//	SysTick->CTRL = 0;												//disable SysTick
//	
//	SysTick->LOAD = reload - 1;								//Set reload register
//	
//	NVIC_SetPriority(SysTick_IRQn, (1<<__NVIC_PRIO_BITS) - 1); //Set interupt priority
//	
//	SysTick->VAL = 0;													//reset the SysTick counter value
//	
//	SysTick->CTRL |= SysTick_CTRL_CLKSOURCE_Msk;	//select processor clock
//	
//	SysTick->CTRL |= SysTick_CTRL_TICKINT_Msk;		//enable SysTick interupt
//	
//	SysTick->CTRL |= SysTick_CTRL_ENABLE_Msk;			//Enable SysTick
//	
//}

void Init(){
	
	// Enable the Internal High Speed oscillator (HSI)
	RCC->CR |= RCC_CR_HSION;
	while((RCC->CR & RCC_CR_HSIRDY) == 0);
	RCC->CFGR |= RCC_CFGR_SW_HSI;
	
	
	//Enable the clock to GPIO Port B
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN;
	
	//Enable the clock to GPIO Port C
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOCEN;
		
	//Set PB6-9 as open drain
	GPIOB->OTYPER |= GPIO_OTYPER_OT_6;
	GPIOB->OTYPER |= GPIO_OTYPER_OT_7;
	GPIOB->OTYPER |= GPIO_OTYPER_OT_8;
	GPIOB->OTYPER |= GPIO_OTYPER_OT_9;
	
	//Set PB6-9 as output
	GPIOB->MODER &= ~GPIO_MODER_MODER6;
	GPIOB->MODER |= GPIO_MODER_MODER6_0;
	GPIOB->MODER &= ~GPIO_MODER_MODER7;
	GPIOB->MODER |= GPIO_MODER_MODER7_0;
	GPIOB->MODER &= ~GPIO_MODER_MODER8;
	GPIOB->MODER |= GPIO_MODER_MODER8_0;
	GPIOB->MODER &= ~GPIO_MODER_MODER9;
	GPIOB->MODER |= GPIO_MODER_MODER9_0;
	
	//Set PB-10-13 as input
	GPIOB->MODER &= ~GPIO_MODER_MODER10;
	GPIOB->MODER &= ~GPIO_MODER_MODER11;
	GPIOB->MODER &= ~GPIO_MODER_MODER12;
	GPIOB->MODER &= ~GPIO_MODER_MODER13;
	
	//Set PB0-3 as output
	GPIOB->MODER &= ~GPIO_MODER_MODER0;
	GPIOB->MODER |= GPIO_MODER_MODER0_0;
	GPIOB->MODER &= ~GPIO_MODER_MODER1;
	GPIOB->MODER |= GPIO_MODER_MODER1_0;
	GPIOB->MODER &= ~GPIO_MODER_MODER2;
	GPIOB->MODER |= GPIO_MODER_MODER2_0;
	GPIOB->MODER &= ~GPIO_MODER_MODER3;
	GPIOB->MODER |= GPIO_MODER_MODER3_0;
	
	//Set PC0 as output
	GPIOC->MODER &= ~GPIO_MODER_MODER0;
	GPIOC->MODER |= GPIO_MODER_MODER0_0;
	
}


void checkRow(void){
	for(unsigned int i=0;i<=3;i++){		//for loop infinitely cycles through rows
			volatile unsigned int row = i;		//declares a row variable to keep track of row
			unsigned int write = 0x000003B8;	//declares temp variable 0011 1011 1000 to cycle zero through ODR
			write = write << i;			//shifts zero to correct row position
			write &= 0x000003C0;			//keeps only the four bits we want
			GPIOB->ODR &= 0xFFFFFC3F;		//bitmasks ODR zeros the 4 bits we are changing
			GPIOB->ODR |= write; 			//inputs cycling zero into ODR
			checkColumn(row);			//calls checkColumn sending the row value
		}
}

void checkColumn(unsigned int row){

//temp variable for checking inputs from keypad
unsigned int x1 = GPIOB->IDR;

x1 &= 0x00003C00; 			//keeps only PB13-10 
unsigned int x = x1;
if(x1 != 0x00003C00){			//if button is pressed(zero in PB13-10)
	while(x != 0x00003C00){		//while loop until a button is pressed
	x = GPIOB->IDR;
	x &= 0x00003C00; 		//keeps only PB13-10
	}
SetColumn(x1, row);			//calls SetColumn with row number and IDR values
}
}

void SetColumn(unsigned int x2, unsigned int row){
unsigned int column = 0;
				//if statements read IDR and set column based off button pressed
if(x2 == 0x00003800){		//PB13-10 == 1110
column = 0;
}else if(x2 == 0x00003400){ 	//PB13-10 == 1101
	column = 1;
}else if(x2 == 0x00002C00){	//PB13-10 == 1011
	column = 2;
}else if(x2 == 0x00001C00){	//PB13-10 == 0111
	column = 3;
}

//declares an array with all buttons in their position on the keypad
char KeyPad[4][4] = {{'1','2','3','A'},{'4','5','6','B'},{'7','8','9','C'},{'*','0','#','D'}};


	Timer[ent] = KeyPad[row][column];
	ent++;
}

//void SysTick_Handler(void){
//	//ms counter
//	ms++;
//}

void Clockwise(unsigned char Start){
	unsigned char Step[4] = {0x9, 0xA, 0x6, 0x5}; //1001 1010 0110 0101
	for(int j = 0; j<(Start*9); j++){
		for(int i = 0; i < 4; i++){
			for(volatile int k = 0; k < 6000; k++);
			//set PB0-3 to zero
			unsigned int temp = (GPIOB->ODR & 0xFFFFFFF0);
			//set PB0-3
			temp |= (Step[i] & 0x8);
			temp |= (Step[i] & 0x4);
			temp |= (Step[i] & 0x2);
			temp |= (Step[i] & 0x1);
			GPIOB->ODR = temp;
		}
	}
}

void CounterClockwise(unsigned char Start){
	unsigned char Step[4] = {0xC, 0x6, 0x3, 0x9}; //1001 1010 0110 0101
	for(int j = 0; j<(Start*9); j++){
		for(int i = 0; i < 4; i++){
			for(volatile int k = 0; k < 53000; k++);
			//set PB0-3 to zero
			unsigned int temp = (GPIOB->ODR & 0xFFFFFFF0);
			//set PB0-3
			temp |= (Step[i]);

			GPIOB->ODR = temp;
		}
	}
}

#include "stm32l476xx.h"
#include <stdio.h>
#include "stdint.h"
#include "FinalProject.h"
#include <stdlib.h>

	//sets starting level, can use to check if other level work
	unsigned char level = 1;
	char * Maps[10] = {
		"                #         #    #         ##         #    #       ##     #                                   ",
		"                #     #    #         #   #         #  #          ##     #                                   ",
		"                #          ##    #       ##         #    #       #     #                                    ",
		"                #   ##    ##         ##         ##                      #                                   ",
		"                   #  #   #    #     #       #    #       ##     #                                          ",
		"                #  #  #     ##                                   #  #  ## #                                 ",
		"                #               ##            ##         ##       ##         #                              ",
		"                #      #         #         #    #       #      #       #    #     #                         ",
		"                     #   #   #   #   #   #   #   #   #   #                                                  ",
		"                #      ##         #    #         ##       ##     #                                          "
	};

	unsigned char jump = 0;
	
int main(void){
	//initialize clock, GPIOB and C clocks, initialize all pins
	Init();
	//delay
	delay_ms(10);
	//initialize LCD, set 8 bit mode, set 4 bit mode, set 2 line display, turn off cursor and turn on display, turn cursor blink off
	LCD_Init();
	delay_ms(10);
	//play game function, starts game and progresses through each level
	PlayGame();
	
}

void Init(void){
	
	// Enable the Internal High Speed oscillator (HSI)
	RCC->CR |= RCC_CR_HSION;
	while((RCC->CR & RCC_CR_HSIRDY) == 0);
	RCC->CFGR |= RCC_CFGR_SW_HSI;
	
	//Enable the clock to GPIO Port B
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN;
	
	//Enable the clock to GPIO Port C
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOCEN;
	
	//Buttons
	//Configure GPIOC 0-2 PUPDR in mode 01 Pull-up
	GPIOC->PUPDR &= 0xFFFFFFC0;
	GPIOC->PUPDR |= GPIO_PUPDR_PUPDR0_0;
	GPIOC->PUPDR |= GPIO_PUPDR_PUPDR1_0;
	GPIOC->PUPDR |= GPIO_PUPDR_PUPDR2_0;
	
	//configure GPIOC 0-2 to input mode
	GPIOC->MODER &= 0xFFFFFFC0;
	
	//enable SYSCFG clock
	RCC->APB2ENR |= RCC_APB2ENR_SYSCFGEN;

	// Connect External Line to the GPI
	RCC->APB2ENR |= RCC_APB2ENR_SYSCFGEN;
	SYSCFG->EXTICR[0] &= ~SYSCFG_EXTICR1_EXTI0;
	SYSCFG->EXTICR[0] |= SYSCFG_EXTICR1_EXTI0_PC;
	SYSCFG->EXTICR[0] &= ~SYSCFG_EXTICR1_EXTI2;
	SYSCFG->EXTICR[0] |= SYSCFG_EXTICR1_EXTI2_PC;

	// Rising trigger selection
	// 0 = trigger disabled, 1 = trigger enabled
	EXTI->FTSR1 |= EXTI_FTSR1_FT0;
	EXTI->FTSR1 |= EXTI_FTSR1_FT2;
	//diable rising edge
	EXTI->RTSR1 &= ~EXTI_RTSR1_RT0;
	EXTI->RTSR1 &= ~EXTI_RTSR1_RT2;
	
	// Interrupt Mask Register
	// 0 = marked, 1 = not masked (enabled)
	EXTI->IMR1 |= EXTI_IMR1_IM0;
	EXTI->IMR1 |= EXTI_IMR1_IM2;
	
	//enable GPIOC 0-2 as interupts
	NVIC_EnableIRQ(EXTI0_IRQn);
	NVIC_EnableIRQ(EXTI2_IRQn);
	
	EXTI->PR1 |= EXTI_PR1_PIF0;
	EXTI->PR1 |= EXTI_PR1_PIF2;

	//Buzzer
	GPIOC->MODER &= ~GPIO_MODER_MODER3;
	GPIOC->MODER |= GPIO_MODER_MODER3_0; 
	
	//LED
	//Output
	GPIOB->MODER &= 0x00000FFF;
	GPIOB->MODER |= 0x55555000;
	
	//Open-drain
	GPIOB->OTYPER |= 0x0000FFC0;

}

void PlayGame(){
	char *pos = 0;
	unsigned char LEV = 0;
	GPIOB->ODR |= 0x0000FFC0;
	
	unsigned char start[]= "Press Green Btn";
	LCD_DisplayString(0,start);
	
	//wait for green button
	while((GPIO_IDR_IDR_1 & GPIOC->IDR) == GPIO_IDR_IDR_1);
	LCD_Clear();
	while(level<11){
		
		//light bar shows current level
		if(level == 1){
			GPIOB->ODR &= ~GPIO_ODR_ODR_6;
		}if(level == 2){
			GPIOB->ODR &= ~GPIO_ODR_ODR_7;
		}if(level == 3){
			GPIOB->ODR &= ~GPIO_ODR_ODR_8;
		}if(level == 4){
			GPIOB->ODR &= ~GPIO_ODR_ODR_9;
		}if(level == 5){
			GPIOB->ODR &= ~GPIO_ODR_ODR_10;
		}if(level == 6){
			GPIOB->ODR &= ~GPIO_ODR_ODR_11;
		}if(level == 7){
			GPIOB->ODR &= ~GPIO_ODR_ODR_12;
		}if(level == 8){
			GPIOB->ODR &= ~GPIO_ODR_ODR_13;
		}if(level == 9){
			GPIOB->ODR &= ~GPIO_ODR_ODR_14;
		}if(level == 10){
			GPIOB->ODR &= ~GPIO_ODR_ODR_15;
		}
	
		LEV = (unsigned char)(rand() % 10);
		pos = &Maps[LEV][0];
	
		//main gameplay loop, wait for player to jump over 10 obstacles
		for(unsigned char obstacles = 0; obstacles < 10; pos++){
			
			unsigned char i = 0;
			//dynamic delay that decreases the higher level the player gets to
			delay_ms((11-level)*60);
			
			//propagates the 16 character onto the LCD screen and continues to shift left across
			for(char* k = pos; k<pos+16; k++){
				
				if(k == pos){
					if(jump > 0){
						NVIC_DisableIRQ(EXTI2_IRQn); 	//prevents double jumping
						LCD_WriteCom(0xC0);
						LCD_WriteData(' ');
						LCD_WriteCom(0x80); 					//sets position to write character
						jump--;
					}
					else {
						NVIC_EnableIRQ(EXTI2_IRQn);		//allows player to jump again
						LCD_WriteCom(0x80);
						LCD_WriteData(' ');
						LCD_WriteCom(0xC0);
					}if(*pos == '#' && jump == 0){	//gameover conditions
						GameOver();
					}
					if(*pos == '#'){								//increase progress on level
						obstacles++;
					}
					
					LCD_WriteData(0xEF);						//write custom character
				}else{
					LCD_DisplayChar(i,*k);					//write currently displayed obstacles onto LCD
				}
				
				i++;
				
			}
				 
			
		}
		
		
		//Level passed tune
		Buzzer(494,1000);
		Buzzer(494,1000);
		Buzzer(494,1000);
		Buzzer(523,2500);
		Buzzer(494,1000);
		Buzzer(494,1000);
		Buzzer(494,1000);
		Buzzer(523,2500);
		Buzzer(494,1000);
		Buzzer(494,1000);
		Buzzer(494,1000);
		Buzzer(523,2500);
		
		delay_ms((11-level)*60);
		level++;	//increment level
	}
	//You won
	Victory();
}

void GameOver(){
	unsigned char GameOver[] = {"Game Over"};
	LCD_Clear();
	LCD_DisplayString(0,GameOver);
	
	//end game sound
	Buzzer(784,2000);
	Buzzer(523,2000);
	Buzzer(784,2000);
	Buzzer(523,2000);
	Buzzer(784,2000);
	Buzzer(523,2000);

	
	
	while(1){
		LCD_DisplayString(0,GameOver);
	}
}

void Victory(){
	unsigned char victory[] = {"Victory"};
	LCD_Clear();
	LCD_DisplayString(0,victory);
	
	//victory sound
	Buzzer(494,1000);
	Buzzer(494,1000);
	Buzzer(494,1000);
	Buzzer(523,2500);
	Buzzer(587,1000);
	Buzzer(587,1000);
	Buzzer(587,2000);
	delay_ms(5);
	Buzzer(587,3500);
	
	while(1){
	LCD_DisplayString(0,victory);
	}
}

void EXTI0_IRQHandler(void){
	if((EXTI->PR1 & EXTI_PR1_PIF0) == EXTI_PR1_PIF0){
		
		//pause until green is pressed
		while((GPIO_IDR_IDR_1 & GPIOC->IDR) == GPIO_IDR_IDR_1);
		
		EXTI->PR1 |= EXTI_PR1_PIF0;
	}
}

void EXTI2_IRQHandler(void){
	if((EXTI->PR1 & EXTI_PR1_PIF2) == EXTI_PR1_PIF2){
		//set jump to 3 so it last for 3 left shifts
		jump = 3;
		
		EXTI->PR1 |= EXTI_PR1_PIF2;
	}
}

void Buzzer(unsigned int note, unsigned int duration){
	//Sets buzzer on for duration
	for(unsigned int k = 0; k < duration; k++){
		GPIOC->ODR |= GPIO_ODR_ODR_3;
		//sets buzzer off for note
			for(unsigned int q = 0; q < note; q++){
		GPIOC->ODR &= 0xFFFFFFF7;
		}
	}
}


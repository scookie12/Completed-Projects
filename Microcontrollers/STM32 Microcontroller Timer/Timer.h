#ifndef __STM32L476R_NUCLEO_LCD_H
#define __STM32L476R_NUCLEO_LCD_H
	
	extern unsigned char Timer[3];
	extern unsigned char ent;
	extern unsigned char CountDown;
	//extern unsigned int ms;
	
	//void SysTick_Initialize(unsigned int reload);
	void Init(void);
	void KeyPadPressed(void);
	void checkColumn(unsigned int row);
	void SetColumn(unsigned int x2, unsigned int row);
	void checkRow(void);
	//void SysTick_Handler(void);
	void Clockwise(unsigned char Start);
	void CounterClockwise(unsigned char Start);
	
#endif


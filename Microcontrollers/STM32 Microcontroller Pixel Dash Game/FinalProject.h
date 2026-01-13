#ifndef __STM32L476R_NUCLEO_LCD_H
#define __STM32L476R_NUCLEO_LCD_H

void Init(void);
void delay_ms(unsigned int ms);
void LCD_WriteCom(unsigned char com);
void LCD_WriteCom8(unsigned char com);
void LCD_WriteData(unsigned char dat);
void LCD_Clear(void);
void write_custom_character(unsigned char pos, char *x);
int rand(void);
void LCD_DisplayString(unsigned int line, unsigned char *ptr);
void LCD_Init(void);
void LCD_DisplayChar(unsigned char position, unsigned char c);

void Buzzer(unsigned int note, unsigned int duration);
void StartGame(void);
void PlayGame(void);
void GameOver(void);
void Victory(void);
void EXTI0_IRQHandler(void);
void EXTI2_IRQHandler(void);

extern char stick_figure[8];
extern unsigned char level;
extern char * Maps[10];
extern unsigned char jump;


#endif

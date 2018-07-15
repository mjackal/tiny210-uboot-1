/*
 * Copyright (C) 2009 Samsung Electronics
 * Kyungmin Park <kyungmin.park@samsung.com>
 * Minkyu Kang <mk7.kang@samsung.com>
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */

#include <config.h>
#include <version.h>
#include <asm/arch/cpu.h>
#include <asm/arch/power.h>

/*
 * Register usages:
 *
 * r5 has zero always
 */

#define GPJ2CON 0xE0200280
#define GPJ2DAT 0xE0200284
	.globl lowlevel_init
lowlevel_init:

	ldr r0, =0xE0200280 //ldr: load address
	ldr r1, =0x00001111 //set led1~4 as output
	str r1, [r0] //r1 -> [r0]
	//led blink
led_blink:
	ldr r0, =0xE0200284 //GPJDAT
	ldr r1, =(0<<0|0<<1|0<<2|0<<3)
	str r1, [r0]

	bl delay
	
	ldr r0, =0xE0200284
	ldr r1, =(1<<0|1<<1|1<<2|1<<3) //led off
	str r1, [r0]

	bl delay

	b led_blink

delay:
	ldr r2, =0x01FFFFFF
	ldr r3, =0x0
loop:
	sub r2, r2, #1
	cmp r2, r3
	bne loop
	mov pc, lr




	mov	r9, lr

	/* r5 has always zero */
	mov	r5, #0

	ldr	r8, =S5PC100_GPIO_BASE

	/* Disable Watchdog */
	ldr	r0, =S5PC100_WATCHDOG_BASE		@0xEA200000
	orr	r0, r0, #0x0
	str	r5, [r0]

	/* setting SRAM */
	ldr	r0, =S5PC100_SROMC_BASE
	ldr	r1, =0x9
	str	r1, [r0]

	/* S5PC100 has 3 groups of interrupt sources */
	ldr	r0, =S5PC100_VIC0_BASE			@0xE4000000
	ldr	r1, =S5PC100_VIC1_BASE			@0xE4000000
	ldr	r2, =S5PC100_VIC2_BASE			@0xE4000000

	/* Disable all interrupts (VIC0, VIC1 and VIC2) */
	mvn	r3, #0x0
	str	r3, [r0, #0x14]				@INTENCLEAR
	str	r3, [r1, #0x14]				@INTENCLEAR
	str	r3, [r2, #0x14]				@INTENCLEAR

	/* Set all interrupts as IRQ */
	str	r5, [r0, #0xc]				@INTSELECT
	str	r5, [r1, #0xc]				@INTSELECT
	str	r5, [r2, #0xc]				@INTSELECT

	/* Pending Interrupt Clear */
	str	r5, [r0, #0xf00]			@INTADDRESS
	str	r5, [r1, #0xf00]			@INTADDRESS
	str	r5, [r2, #0xf00]			@INTADDRESS

	/* for UART */
	bl uart_asm_init

	/* for TZPC */
	bl tzpc_asm_init

#ifdef CONFIG_SPL_BUILD
	bl system_clock_init      /*init system clock*/
	/*bl ddr_init			      ddr init*/
#endif


1:
	mov	lr, r9
	mov	pc, lr

/*
 * system_clock_init: Initialize core clock and bus clock.
 * void system_clock_init(void)
 */
system_clock_init:
#define	  APLL_CON0	   0xE0100100  @FOUT_APLL = 1000 MHZ
#define   APLL_VAL     ((1<<31)|(125<<16)|(3<<8)|(1<<0))    
         
#define	  MPLL_CON     0xE0100108  @FOUT_MPLL = 667 MHZ
#define   MPLL_VAL     ((1<<31)|(667<<16)|(12<<8)|(1<<0)) 
		  
#define	  EPLL_CON0    0xE0100110  @FOUT_EPLL = 96 MHZ
#define   EPLL_VAL     ((1<<31)|(48<<16)|(3<<8)|(2<<0)) 
		   
#define	  VPLL_CON 	   0xE0100120  @FOUT_VPLL = 54 MHZ
#define   VPLL_VAL     ((1<<31)|(108<<16)|(6<<8)|(3<<0)) 
		    
@ MOUT_MSYS = SCLKAPLL = FOUT_APLL = 1000MHz
@ MOUT_DSYS = SCLKMPLL = FOUT_MPLL = 667MHz
@ MOUT_PSYS = SCLKMPLL = FOUT_MPLL = 667MHz
@ ONENAND = HCLK_PSYS
			 
#define   CLK_SRC0     0xE0100200
#define   SRC0_VAL     ((1<<0)|(1<<4)|(1<<8)|(1<<12))
			  
@ APLL_RATIO = 0, freq(ARMCLK) = MOUT_MSYS / (APLL_RATIO + 1) = 1000MHz */
@ A2M_RATIO = 4, freq(A2M) = SCLKAPLL / (A2M_RATIO + 1) = 200MHz */
@ HCLK_MSYS_RATIO = 4, freq(HCLK_MSYS) = ARMCLK / (HCLK_MSYS_RATIO + 1) = 200MHz */
@ PCLK_MSYS_RATIO = 1, freq(PCLK_MSYS) = HCLK_MSYS / (PCLK_MSYS_RATIO + 1) = 100MHz */
@ HCLK_DSYS_RATIO = 3, freq(HCLK_DSYS) = MOUT_DSYS / (HCLK_DSYS_RATIO + 1) = 166MHz */
@ PCLK_DSYS_RATIO = 1, freq(PCLK_DSYS) = HCLK_DSYS / (PCLK_DSYS_RATIO + 1) = 83MHz */
@ HCLK_PSYS_RATIO = 4, freq(HCLK_PSYS) = MOUT_PSYS / (HCLK_PSYS_RATIO + 1) = 133MHz */
@ PCLK_PSYS_RATIO = 1, freq(PCLK_PSYS) = HCLK_PSYS / (PCLK_PSYS_RATIO + 1) = 66MHz */
			   
#define   CLK_DIV0 0xE0100300
#define	  DIV0_VAL 	((0<<0)|(4<<4)|(4<<8)|(1<<12)|(3<<16)|(1<<20)|(4<<24)|(1<<28))	

/*
 * system_clock_init: Initialize core clock and bus clock.
 * void system_clock_init(void)
 */
system_clock_init:
	@ref: page 364 spec

	@Turn on a PLL
	@(A,M,E,V)PLL_CON[31]=1

	@wait_lock_time, wait until PLL is locked

	@(A,M,E,V)PLL_SEL=1

	@Change PLL's PMS values

	@Set PMS values, (A,M,E,V)PLL_CON SFR

	@Change the system clock divider values
	@CLK_DIV0[31:0] =target value0

	@Change the divider values for specical clocks
	@CLK_DIV1[31:0] = target value1
	@CLK_DIV2[31:0] = target value2

	ldr r0, =CLK_SRC0
	ldr r1, =SRC0_VAL
	str r1, [r0]

	ldr r0, =APLL_CON0
	ldr r1, =APLL_VAL
	str r1, [r0]

	ldr r0, =MPLL_CON
	ldr r1, =MPLL_VAL
	str r1, [r0]

	ldr r0, =EPLL_CON0
	ldr r1, =EPLL_VAL
	str r1, [r0]

	ldr r0, =VPLL_CON
	ldr r1, =VPLL_VAL
	str r1, [r0]

	ldr r0, =CLK_DIV0
	ldr r1, =DIV0_VAL
	str r1, [r0]

	mov pc, lr

/*
 * uart_asm_init: Initialize UART's pins
 */
uart_asm_init:
	mov	r0, r8
	ldr	r1, =0x22222222
	str	r1, [r0, #0x0]			@ GPA0_CON
	ldr	r1, =0x00022222
	str	r1, [r0, #0x20]			@ GPA1_CON

	mov	pc, lr

/*
 * tzpc_asm_init: Initialize TZPC
 */
tzpc_asm_init:
	ldr	r0, =0xE3800000
	mov	r1, #0x0
	str	r1, [r0]
	mov	r1, #0xff
	str	r1, [r0, #0x804]
	str	r1, [r0, #0x810]

	ldr	r0, =0xE2800000
	str	r1, [r0, #0x804]
	str	r1, [r0, #0x810]
	str	r1, [r0, #0x81C]

	ldr	r0, =0xE2900000
	str	r1, [r0, #0x804]
	str	r1, [r0, #0x810]

	mov	pc, lr

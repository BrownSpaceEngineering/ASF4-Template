#include <atmel_start.h>
#include <delay_periods.h>

int main(void)
{
	/* Initializes MCU, drivers and middleware */
	atmel_start_init();

	/* Set PB30 to output */
	REG_PORT_DIR1 |= (1<<30);

	while (1) {
		REG_PORT_OUT1 &= ~(1<<30);
		delay_ms(SHORT_DELAY);
		REG_PORT_OUT1 |= (1<<30);
		delay_ms(SHORT_DELAY);
		REG_PORT_OUT1 &= ~(1<<30);
		delay_ms(SHORT_DELAY);
		REG_PORT_OUT1 |= (1<<30);
		delay_ms(SHORT_DELAY);
		REG_PORT_OUT1 &= ~(1<<30);
		delay_ms(SHORT_DELAY);
		REG_PORT_OUT1 |= (1<<30);
		delay_ms(LONG_DELAY);
	}
}

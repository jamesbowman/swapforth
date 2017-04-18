#include "ets_sys.h"
#include "osapi.h"
#include "gpio.h"
#include "os_type.h"
#include "mem.h"
#include "user_config.h"
#include "ip_addr.h"
#include "espconn.h"
#include "user_interface.h"

extern int swapforth(), swapforth2();

// #undef ICACHE_FLASH_ATTR
// #define ICACHE_FLASH_ATTR

#define user_procTaskPrio        0
#define user_procTaskQueueLen    128
os_event_t    user_procTaskQueue[user_procTaskQueueLen];
static void user_procTask(os_event_t *events);

volatile os_timer_t some_timer;

struct espconn *_ptrUDPServer;
uint8 udpServerIP[] = { 192, 168, 0, 64 };

void dump(uint32 a)
{
  uint32*ptr = (uint32_t*)a;
  int i;

  ets_printf("%08x:   ", a);
  for (i = 0; i < 8; i++)
    ets_printf("%08x ", *ptr++);
  ets_printf("\n");
}

void timer_action(void *arg)
{
  system_os_post(user_procTaskPrio, 0, 0 );
}

void some_timerfunc(void *arg)
{
  //Do blinky stuff
  if (GPIO_REG_READ(GPIO_OUT_ADDRESS) & BIT2)
  {
      //Set GPIO2 to LOW
      gpio_output_set(0, BIT2, BIT2, 0);
  }
  else
  {
      //Set GPIO2 to HIGH
      gpio_output_set(BIT2, 0, BIT2, 0);
  }
  static int cold = 1;
  if (cold) {
    cold = 0;
  }
  static int i; i++;
  ets_printf("Hello World %d!\r\n", i);

#if 0
  // See eagle_soc.h for timer layout
  {
    uint32*ptr = (uint32_t*)0x60000600;
    int i;

    for (i = 0; i < 24; i++) {
      ets_printf("%08x ", *ptr++);
      if ((i & 7) == 7)
        ets_printf("\n");
    }
  }
  dump(0x3fffdaac);
  dump(0x3fffc000);
  dump(0x40000390);
  dump(0x3fffc100);
  dump(0x401006a0);
#endif

  if (1) {
    _ptrUDPServer = (struct espconn *) os_zalloc(sizeof(struct espconn));
    _ptrUDPServer->type = ESPCONN_UDP;
    _ptrUDPServer->state = ESPCONN_NONE;
    _ptrUDPServer->proto.udp = (esp_udp *) os_zalloc(sizeof(esp_udp));
    _ptrUDPServer->proto.udp->local_port = espconn_port();
    _ptrUDPServer->proto.udp->remote_port = 2115;
    os_memcpy(_ptrUDPServer->proto.udp->remote_ip, udpServerIP, 4);
    espconn_create(_ptrUDPServer);
  }
  if (40 < i) {
    char USER_DATA[80];
    os_sprintf(USER_DATA, "%07d\n", i);
    espconn_sent(_ptrUDPServer, (uint8 *) USER_DATA, (uint16) strlen(USER_DATA));
  }
  system_os_post(user_procTaskPrio, 0, 0 );
}

//Do nothing function
static void ICACHE_FLASH_ATTR
user_procTask(os_event_t *e)
{
  // ets_printf("/idle %d %d/\n", e->sig, e->par);
  // os_delay_us(10);
  // ets_printf("\nreturn B: %08x\n", swapforth2(e->sig, e->par));
  swapforth2(e->sig, e->par);
}

#define UART0   0
#define UART1   1

#include "uart_register.h"

LOCAL void
uart0_rx_intr_handler(void *para)
{
  //Set GPIO2 to HIGH
  gpio_output_set(BIT2, 0, BIT2, 0);

  if (UART_RXFIFO_FULL_INT_ST != (READ_PERI_REG(UART_INT_ST(UART0)) & UART_RXFIFO_FULL_INT_ST)) {
    return;
  }

  WRITE_PERI_REG(UART_INT_CLR(UART0), UART_RXFIFO_FULL_INT_CLR);

  if (READ_PERI_REG(UART_STATUS(UART0)) & (UART_RXFIFO_CNT << UART_RXFIFO_CNT_S)) {
    uint8 RcvChar = READ_PERI_REG(UART_FIFO(UART0)) & 0xFF;
    // ets_printf("^^^%c", RcvChar);
    // os_delay_us(1000);
    system_os_post(user_procTaskPrio, 0x947, RcvChar );
  }
}

void
uart_config(uint8 uart_no)
{
    if (uart_no == UART1) {
        PIN_FUNC_SELECT(PERIPHS_IO_MUX_GPIO2_U, FUNC_U1TXD_BK);
    } else {
        /* rcv_buff size if 0x100 */
        ETS_UART_INTR_ATTACH(uart0_rx_intr_handler,  NULL);
        PIN_PULLUP_DIS(PERIPHS_IO_MUX_U0TXD_U);
        PIN_FUNC_SELECT(PERIPHS_IO_MUX_U0TXD_U, FUNC_U0TXD);
    }

    uart_div_modify(uart_no, UART_CLK_FREQ / 1000000);


    //clear rx and tx fifo,not ready
    SET_PERI_REG_MASK(UART_CONF0(uart_no), UART_RXFIFO_RST | UART_TXFIFO_RST);
    CLEAR_PERI_REG_MASK(UART_CONF0(uart_no), UART_RXFIFO_RST | UART_TXFIFO_RST);

    //set rx fifo trigger
    WRITE_PERI_REG(UART_CONF1(uart_no), (1 & UART_RXFIFO_FULL_THRHD) << UART_RXFIFO_FULL_THRHD_S);

    //clear all interrupt
    WRITE_PERI_REG(UART_INT_CLR(uart_no), 0xffff);
    //enable rx_interrupt
    SET_PERI_REG_MASK(UART_INT_ENA(uart_no), UART_RXFIFO_FULL_INT_ENA);

    ETS_UART_INTR_ENABLE();
}

void wifi_config()
{
  const char ssid[32] = "bowmanvilleshed";
  const char password[64] = "qwertyui";
  wifi_station_get_connect_status();
  struct station_config stationConf;

  wifi_set_opmode(STATION_MODE);
  stationConf.bssid_set = 0;
  os_memcpy(&stationConf.ssid, ssid, 32);
  os_memcpy(&stationConf.password, password, 64);
  wifi_station_set_config(&stationConf);
  // wifi_station_connect();
};

//Init function 
void ICACHE_FLASH_ATTR
user_init()
{
  system_set_os_print(0);
  uart_div_modify(0, UART_CLK_FREQ / 1000000);

  // wifi_config();

  // Initialize the GPIO subsystem.
  gpio_init();

  //Set GPIO2 to output mode
  PIN_FUNC_SELECT(PERIPHS_IO_MUX_GPIO2_U, FUNC_GPIO2);

  //Set GPIO2 low
  gpio_output_set(0, BIT2, BIT2, 0);

#if 0
  //Disarm timer
  os_timer_disarm(&some_timer);

  // Setup timer
  os_timer_setfn(&some_timer, (os_timer_func_t *)some_timerfunc, NULL);
  //Arm the timer
  //&some_timer is the pointer
  //1000 is the fire time in ms
  //0 for once and 1 for repeating
  // os_timer_arm(&some_timer, 2000, 1);
#endif

  os_timer_disarm(&some_timer);
  os_timer_setfn(&some_timer, (os_timer_func_t *)timer_action, NULL);
  // os_timer_arm(&some_timer, 2000, 1);

  //Start os task
  system_os_task(user_procTask, user_procTaskPrio,user_procTaskQueue, user_procTaskQueueLen);

  int j;
  for (j = 0; j < 2000; j++)
    ets_printf(".");

  uart_config(0);

  //ets_printf("\nreturn A: %08x\n", swapforth());
  swapforth();
}

int ICACHE_FLASH_ATTR
klok()
{
  os_timer_arm(&some_timer, 2000, 1);
  return 101;
}

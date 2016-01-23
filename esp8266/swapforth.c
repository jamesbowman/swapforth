#include "ets_sys.h"
#include "osapi.h"
#include "gpio.h"
#include "os_type.h"
#include "mem.h"
#include "user_config.h"
#include "ip_addr.h"
#include "espconn.h"
#include "user_interface.h"

// #undef ICACHE_FLASH_ATTR
// #define ICACHE_FLASH_ATTR

#define user_procTaskPrio        0
#define user_procTaskQueueLen    1
os_event_t    user_procTaskQueue[user_procTaskQueueLen];
static void user_procTask(os_event_t *events);

static volatile os_timer_t some_timer;

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

  if (i == 40) {
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
}

//Do nothing function
static void ICACHE_FLASH_ATTR
user_procTask(os_event_t *events)
{
    os_delay_us(10);
}

//Init function 
void ICACHE_FLASH_ATTR
user_init()
{
  // system_set_os_print(0);
  uart_div_modify(0, UART_CLK_FREQ / 1000000);

#if 0
  // Initialize the GPIO subsystem.
  gpio_init();

  //Set GPIO2 to output mode
  PIN_FUNC_SELECT(PERIPHS_IO_MUX_GPIO2_U, FUNC_GPIO2);

  //Set GPIO2 low
  gpio_output_set(0, BIT2, BIT2, 0);

  //Disarm timer
  os_timer_disarm(&some_timer);

  //Setup timer
  os_timer_setfn(&some_timer, (os_timer_func_t *)some_timerfunc, NULL);

  //Arm the timer
  //&some_timer is the pointer
  //1000 is the fire time in ms
  //0 for once and 1 for repeating
  os_timer_arm(&some_timer, 100, 1);
#endif

  //Start os task
  system_os_task(user_procTask, user_procTaskPrio,user_procTaskQueue, user_procTaskQueueLen);
  int j;
  for (j = 0; j < 2000; j++)
    ets_printf(".");

#if 0

  const char ssid[32] = "bowmanvilleshed";
  const char password[32] = "qwertyui";

  struct station_config stationConf;

  wifi_set_opmode( STATION_MODE );
  os_memcpy(&stationConf.ssid, ssid, 32);
  os_memcpy(&stationConf.password, password, 32);
  wifi_station_set_config(&stationConf);
  wifi_station_connect();

  system_print_meminfo();

  uint32_t dat[] = {
    0x12345678,
    0x12345678,
    0x12345678,
    0x12345678};
  spi_flash_erase_sector(0);
  spi_flash_write(0, dat, 16);

  {
    uint32_t *p = (uint32_t*)0x40200000;
    int i;
    
    for (i = 0; i < 32; i++, p++)
      ets_printf("%p %08x\n", p, *p);
  }
#endif

  extern int swapforth();
  ets_printf("\nreturn: %08x\n", swapforth());
}

int ICACHE_FLASH_ATTR
klok()
{
  return 101;
}

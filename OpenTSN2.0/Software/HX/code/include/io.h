
#ifndef _IO_H__
#define _IO_H__

#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<malloc.h>
#include <unistd.h>




#define BUF_LEN_2048 2048
#define BUF_LEN_4096 4096



typedef int(*hx_pcap_callback)(unsigned char* pkt, int len,int inport);

int hx_libpcap_init();
int hx_libpcap_destroy();
int hx_pcap_loop(hx_pcap_callback callback);

int hx_libnet_init();
int hx_libnet_destroy();
int hx_libnet_write(unsigned char* pkt,unsigned int len,unsigned int outport);




#define IO_DEBUG 1

#if IO_DEBUG
	#define IO_DBG(args...) do{printf("IO-INFO:");printf(args);}while(0)
	#define IO_ERR(args...) do{printf("IO-ERROR:");printf(args);}while(0)
#else
	#define IO_DBG(args...)
	#define IO_DBG(args...)
#endif
//void ids_pkt_print(u8 *pkt,int len);


#endif


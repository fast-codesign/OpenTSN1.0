
#ifndef _SCHEDULE_H__
#define _SCHEDULE_H__

#include "np.h"



struct schedule_info
{
	u16  key;//key
	u8  value;//
};

//编排调度策略表（每一种报文类型，对应一个策略表）
#define MAX_SCHEDULE_NUM 32


void hx_schedule_init();

void hx_msg_schedule();

void hx_schedule_destroy();


#define SCHEDULE_DEBUG 1

#if SCHEDULE_DEBUG
	#define SCHEDULE_DBG(args...) do{printf("SCHEDULE-INFO:");printf(args);}while(0)
	#define SCHEDULE_ERR(args...) do{printf("SCHEDULE-ERROR:");printf(args);}while(0)
#else
	#define SCHEDULE_DBG(args...)
	#define SCHEDULE_DBG(args...)
#endif



#endif



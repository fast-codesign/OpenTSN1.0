
#ifndef _TOOLS_H__
#define _TOOLS_H__

#include "np.h"



int get_cfgx_file(const char *filpath, const char *nam, char *val);



#define TOOLS_DEBUG 1

#if SCHEDULE_DEBUG
	#define TOOLS_DBG(args...) do{printf("TOOLS-INFO:");printf(args);}while(0)
	#define TOOLS_ERR(args...) do{printf("TOOLS-ERROR:");printf(args);}while(0)
#else
	#define TOOLS_DBG(args...)
	#define TOOLS_DBG(args...)
#endif



#endif



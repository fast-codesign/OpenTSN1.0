#ifndef USG_PROTOCOL_H 
#define USG_PROTOCOL_H 

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <malloc.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/shm.h>
#include <sys/time.h>
#include <signal.h>
#include <pthread.h>
#include <errno.h>

typedef unsigned char u8,uint8,uint8_t;
typedef unsigned short u16,uint16, uint16_t;
typedef unsigned int u32,uint32,uint32_t;

#define USGPROTO_DEBUG 1
#undef USGPROTO_DEBUG

#if USGPROTO_DEBUG
	#define USGPROTO_DBG(args...) do{printf("USGPROTO-INFO: ");printf(args);}while(0)
	#define USGPROTO_ERR(args...) do{printf("USGPROTO-ERROR: ");printf(args);exit(0);}while(0)
#else
	#define USGPROTO_DBG(args...)
	#define USGPROTO_ERR(args...)
#endif


/*版本类型*/
typedef enum {
    USG10_VERSION = 0x1,
    USG11_VERSION = 0x2,
}usg_version;

/*报文类型*/
typedef enum
{
	/*握手报文*/
	USG_HELLO = 0x00,
	USG_ERROR = 0x01,
	USG_ECHO_REQUEST = 0x02,/*echo请求*/
	USG_ECHO_REPLY = 0x03,/*echo应答*/
	USG_FEATURES_REQUEST = 0x04,/*特征请求*/
	USG_FEATURES_REPLY = 0x05,/*特征应答*/
	/*控制报文*/
	USG_RULE_CFG = 0x40,/*规则请求*/
	USG_RULE_CFG_ACK = 0x41,/*规则应答*/
	USG_FUNC_CTRL = 0x42, /*功能请求*/
	USG_FUNC_CTRL_ACK = 0x43,/*功能应答*/
	USG_FUNC_REFACTOR = 0x44,/*功能重构请求*/
	USG_FUNC_REFACTOR_ACK = 0x45,/*功能重构应答*/
	/*统计报文*/
	USG_LOG_STATS = 0x60,
	USG_CPU_STATS_REQUEST = 0x61,
	USG_CPU_STATS_REPLY = 0x62,
}usg_type;

/*规则类型*/
typedef enum
{
	HW_ORCHE = 6,/*编排功能*/
//	HW_FW = 7,  /*防火墙功能*/
	HW_SFW = 7, /*有状态防火墙功能*/
	HW_IDPS = 8,   /*IDS功能*/
//	HW_WAF = 10,    /*WAF功能*/
//	HW_DLP = 11,  /*DLP功能*/

	SW_ORCHE = 129,/*编排功能*/
	SW_FW = 130,  /*防火墙功能*/
	SW_SFW = 131, /*有状态防火墙功能*/
	SW_IDPS = 132,   /*IDS功能*/
	SW_WAF = 133,    /*WAF功能*/
	SW_DLP = 134,  /*DLP功能*/
	SW_BL = 135, /*black list*/
	SW_RW  = 135,/*RW功能*/
}mid;

typedef enum
{
	OP_ADD = 0x01,//增加规则
	OP_DEL = 0x02,//删除规则
}RL_OP;
	

/*规则类型*/
typedef enum
{
	RL_ORCHE = 0x00,/*编排功能*/
	RL_FW = 0x01,  /*防火墙功能*/
	RL_SFW = 0x02, /*有状态防火墙功能*/
	RL_IDPS = 0x03,   /*IDS功能*/
	RL_WAF = 0x04,    /*WAF功能*/
	RL_DLP = 0x05,  /*DLP功能*/
	RL_BL = 0X06,/*black list*/

}rule_type;

/*功能类型*/
typedef enum
{
	FUNC_ORCHE = 0x00,/*编排功能*/
	FUNC_FW = 0x01,  /*防火墙功能*/
	FUNC_SFW = 0x02, /*有状态防火墙功能*/
	FUNC_IDPS = 0x03,   /*IDS功能*/
	FUNC_WAF = 0x04,    /*WAF功能*/
	FUNC_DLP = 0x05,  /*DLP功能*/
	FUNC_BL = 0X06,/*BL*/
}func_id;

/*错误类型*/
typedef enum
{
	ER_CFG = 0x00,  /*配置错误*/
	ER_RULE = 0x01,   /*规则错误*/
	ER_FUNC = 0x02,    /*功能控制错误*/
}error_type;

/*动作类型*/
typedef enum
{
	ALLOW = 0x00,  /*通过*/
	DENY = 0x01,   /*阻断*/
	ALERT = 0x02,    /*告警*/
	ALERT_DENY = 0x03,  /*告警、阻断*/
}rule_action;

/*控制类型*/
typedef enum
{
	STOP = 0x00,  /*关闭*/
	START= 0x01,   /*启动*/		
}ctrl_type;


/*通用报文头部*/
typedef struct
{
	u8 version; 		/* 版本号 */
	u8 type; 			/* 报文类型usg_type */
	u16 length; 		/* 报文总长度 */
}usg_header;


/*报文结构*/
typedef struct
{
	usg_header header;      /* 通用报文头部 */
	u8 data[0];        /* 报文子头部和数据 */
}usg_pkt;


/*error子报文*/
typedef struct
{
	u8 error_type;/*error_type*/
	u8 pad;
	union{
		struct{
			u8 rule_type;
			u8 operation;
			u16 group_id;/*规则组id */
       		u16 rule_head_id;/*当前第几条规则 */
		}rule_error;
		struct{
			u8 func_id;
     		u8 ctrl_type;/* 控制类型, 0关闭，1启动*/
		}func_error;
	}error_code;
}error_info;


/*ACK报文*/
typedef struct
{
	union{
		struct{
			u8 func_id;  /* 功能标识func_id*/
        	u8 ctrl_type;  /* 控制类型, 0关闭，1启动*/
        }func_ack;
		struct{
			u8 rule_type; /*规则类型*/
			u8 operation; /*规则操作*/
			u16 group_id;/*组ID*/
		}rule_ack;
	}ack_code;
}ack_info;


/*rule子报文*/
typedef struct
{
    u8 operation;          /*添加add、删除del*/
	u8 path_info;          /*路徑信息 */
	u16 hw_flow_id;		   /*硬件表项ID*/
	u8 rule_data[0];       /*规则内容 JSON*/
}rule_info;


/*func子报文*/
typedef struct
{
	u8 ctrl_type;          /* 控制类型, 0关闭，1启动*/
	u8 func_id;              /* 功能标识func_id*/
	u8 pad[2];       
}func_info;

/*统计子报文*/
typedef struct
{
	u8 func_id;          /* 功能标识func_id */
	u8 pad[3];         /* 保留位 */
	u8 info_data[0];        /*统计信息内容json */
}dp_info;

/*hello子报文*/
typedef struct
{
	u8 id;          /* 设备或UA的ID */
	u8 pad[3];         /* 保留位 */
}hello_info;


/*构造通用报文头部*/
usg_pkt *build_usg_header(u8 type, u16 len);

/*构造握手报文，主要是如下四种报文：
USG_HELLO、USG_ECHO_REQUEST、USG_ECHO_REPLY、USG_FEATURES_REQUEST报文*/
usg_pkt *build_hand_pkt(u8 type);

/*构造hello报文*/
usg_pkt *build_hello_pkt(u8 id);

/*构造feature_reply报文*/
usg_pkt *build_feature_reply_pkt(u8 id);

/*构造统计报文*/
usg_pkt *build_dp_pkt(u8* log, u8 func_id, u16 len);

/* 构造cpu_resoucer统计信息报文*/
usg_pkt *build_cpu_resoucer_pkt(u8* msg, u16 len);

/*构造功能error报文*/
usg_pkt *build_func_error_pkt(u8 func_id,u8 ctr_type);

/*构造规则error报文*/
usg_pkt *build_rule_error_pkt(u8 rule_type, u16 group_id,u16 rule_head_id, u8 operation);

/*构造规则确认报文*/
usg_pkt *build_rule_ack_pkt(u16 group_id, u8 rule_type, u8 operation);

/*构造功能确认报文*/
usg_pkt *build_func_ack_pkt(u8 func_id,u8 ctrl_type);

/*构造规则配置报文*/
usg_pkt *build_rule_cfg_pkt(u8 operation, u8* msg, u16 len);

/*构造功能配置报文*/
usg_pkt *build_func_ctrl_pkt(u8 func_id,u8 ctrl_type);

/*构造CPU资源请求报文*/
usg_pkt *build_cpu_stat_request_pkt();

#endif 

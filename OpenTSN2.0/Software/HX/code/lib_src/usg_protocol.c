#include "../include/usg_protocol.h"

static void usg_pkt_print(u8 *pkt,int len)
{
#if 0
	int i=0;

	printf("-----------------------***USG PROTOCOL PACKET***-----------------------\n");
	printf("Packet Addr:%p\n",pkt);
	for(i=0;i<16;i++)
	{
		if(i % 16 == 0)
			printf("      ");
		printf(" %X ",i);
		if(i % 16 == 15)
			printf("\n");
	}
	
	for(i=0;i<len;i++)
	{
		if(i % 16 == 0)
			printf("%04X: ",i);
		printf("%02X ",*((u8 *)pkt+i));
		if(i % 16 == 15)
			printf("\n");
	}
	if(len % 16 !=0)
		printf("\n");
	printf("-----------------------***USG PROTOCOL PACKET***-----------------------\n\n");
#endif
}



/*
函数名称：copy_usg_header
输入参数：报文首指针、报文类型、报文长度
返回结果：返回报文的首指针地址
函数说明：报文头部各成员变量赋值
*/
static void copy_usg_header(usg_header *reply,u16 len,u8 type)
{
	reply->version = USG10_VERSION;
	reply->length = htons(len);	
	reply->type = type;
}

/*
函数名称：build_usg_header
输入参数：报文类型、报文长度
返回结果：返回报文的首指针地址
函数说明：构造通用的报文头部
*/
usg_pkt *build_usg_header(u8 type,u16 len)
{
	usg_header *reply = (usg_header *)malloc(len+1);
	memset((u8 *)reply,0,len+1);
	copy_usg_header(reply,len,type);

	return (usg_pkt *)reply;
}

/*
函数名称：build_hand_pkt
输入参数：报文类型
返回结果：返回报文的首指针地址.
函数说明：构造握手报文，主要是如下三种报文：
		  USG_ECHO_REQUEST、USG_ECHO_REPLY、USG_FEATURES_REQUEST
*/
usg_pkt *build_hand_pkt(u8 type)
{
	u16 reply_len = sizeof(usg_header);
	usg_pkt *hand_pkt = build_usg_header(type,reply_len);
	
	USGPROTO_DBG("build hand pkt successfully!\n");
	usg_pkt_print((u8 *)hand_pkt, ntohs(hand_pkt->header.length));
	return hand_pkt;
}

/*
函数名称：build_hello_pkt
输入参数：设备或UA的id
返回结果：返回报文的首指针地址.
函数说明：构造hello报文
*/
usg_pkt *build_hello_pkt(u8 id)
{
	u16 reply_len = sizeof(usg_header)+sizeof(hello_info);//头部+id
	usg_pkt *hello_reply = build_usg_header(USG_HELLO,reply_len);
	hello_info *reply = (hello_info *)hello_reply->data;
	reply->id = id;

	USGPROTO_DBG("build hello pkt successfully!\n");
	usg_pkt_print((u8 *)hello_reply, ntohs(hello_reply->header.length));
	return hello_reply;
}

/*
函数名称：build_feature_reply
输入参数：设备或UA的id
返回结果：返回报文的首指针地址.
函数说明：构造FEATURES_REPLY报文
*/
usg_pkt *build_feature_reply_pkt(u8 id)
{
	u16 reply_len = sizeof(usg_header)+1;//头部+id
	usg_pkt *feature_reply = build_usg_header(USG_FEATURES_REPLY,reply_len);
	feature_reply->data[0] = id;

	USGPROTO_DBG("build feature reply pkt successfully!\n");
	usg_pkt_print((u8 *)feature_reply, ntohs(feature_reply->header.length));
	return feature_reply;
}

/*
函数名称：build_dp_pkt
输入参数：日志信息、func_id、日志长度
返回结果：返回报文的首指针地址.
函数说明：构造统计信息报文
*/
usg_pkt *build_dp_pkt(u8* log,u8 func_id,u16 len)
{
	u16 reply_len = sizeof(usg_header)+ sizeof(dp_info)+len;//头部+dp子报文头部+日志信息长度
	usg_pkt *dp_reply = build_usg_header(USG_LOG_STATS, 1024);
	dp_reply->header.length = htons(reply_len);
	dp_info *dp_head = (dp_info*)dp_reply->data;
	dp_head->func_id = func_id;
	strncpy(dp_head->info_data,log,len);
	USGPROTO_DBG("build dp reply pkt successfully!\n");
	usg_pkt_print((u8 *)dp_reply, ntohs(dp_reply->header.length));
	return dp_reply;
}

/*
函数名称：build_cpu_resoucer_pkt
输入参数：cpu_resoucer 的msg、消息长度
返回结果：返回报文的首指针地址.
函数说明：构造cpu_resoucer统计信息报文
*/
usg_pkt *build_cpu_resoucer_pkt(u8* msg,u16 len)
{
	u16 reply_len = sizeof(usg_header) +len;//头部+ 信息长度
	usg_pkt *cpu_reply = build_usg_header(USG_CPU_STATS_REPLY,reply_len); 
	strncpy(cpu_reply->data,msg,len);	
	
	USGPROTO_DBG("build cpu reply pkt successfully!\n");
	usg_pkt_print((u8 *)cpu_reply, ntohs(cpu_reply->header.length));
	return cpu_reply;
}

/*
函数名称：build_func_error_pkt
输入参数：func_id、ctrl_type
返回结果：返回报文的首指针地址.
函数说明：构造 func_error报文
*/
usg_pkt *build_func_error_pkt(u8 func_id,u8 ctrl_type)
{
	u16 reply_len = sizeof(usg_header)+ sizeof(error_info);//头部+error子头部
	usg_pkt *err_reply = build_usg_header(USG_ERROR,reply_len);

	error_info *err_head = (error_info*)err_reply->data;
	err_head->error_type = ER_FUNC ;
	err_head->error_code.func_error.func_id = func_id;
	err_head->error_code.func_error.ctrl_type = ctrl_type;

	USGPROTO_DBG("build func error pkt successfully!\n");
	usg_pkt_print((u8 *)err_reply, ntohs(err_reply->header.length));
	return err_reply;
}

/*
函数名称：build_rule_error_pkt 
输入参数：group_id、rule_head_id
返回结果：返回报文的首指针地址.
函数说明：构造rule error报文
*/
usg_pkt *build_rule_error_pkt(u8 rule_type, u16 group_id,u16 rule_head_id,u8 operation)
{
	u16 reply_len = sizeof(usg_header)+ sizeof(error_info);//头部+error子头部
	usg_pkt *err_reply = (usg_pkt *)build_usg_header(USG_ERROR,reply_len);

	error_info *err_head = (error_info*)err_reply->data;
	err_head->error_type = ER_RULE ;
	err_head->error_code.rule_error.rule_type = rule_type;
	err_head->error_code.rule_error.operation = operation;
	err_head->error_code.rule_error.group_id = htons(group_id);
	err_head->error_code.rule_error.rule_head_id = htons(rule_head_id);

	USGPROTO_DBG("build rule error pkt successfully!\n");
	usg_pkt_print((u8 *)err_reply, ntohs(err_reply->header.length));
	return err_reply;
}

/*
函数名称：build_rule_ack_pkt
输入参数：id(group_id or update_id)
返回结果：返回报文的首指针地址.
函数说明：构造规则确认报文
*/
usg_pkt *build_rule_ack_pkt(u16 group_id, u8 rule_type,u8 operation)
{
	u16 reply_len = sizeof(usg_header)+ sizeof(ack_info);//头部+ack_info子报文头部 
	usg_pkt *ack_reply = (usg_pkt *)build_usg_header(USG_RULE_CFG_ACK,reply_len);
	ack_info *ack_head = (ack_info*)ack_reply->data;
	ack_head->ack_code.rule_ack.rule_type = rule_type;
	ack_head->ack_code.rule_ack.operation = operation;
	ack_head->ack_code.rule_ack.group_id = htons(group_id);
	
	USGPROTO_DBG("build rule ack pkt successfully!\n");
	usg_pkt_print((u8 *)ack_reply, ntohs(ack_reply->header.length));
	return ack_reply;
}


/*
函数名称：build_func_ack_pkt
输入参数：func_id、ctrl_type
返回结果：返回报文的首指针地址.
函数说明：构造功能确认报文
*/
usg_pkt *build_func_ack_pkt(u8 func_id,u8 ctrl_type)
{
	u16 reply_len = sizeof(usg_header)+ sizeof(ack_info);//头部+ack_info子报文头部 
	usg_pkt *ack_reply = (usg_pkt *)build_usg_header(USG_FUNC_CTRL_ACK,reply_len);
	ack_info *ack_head = (ack_info*)ack_reply->data;
	ack_head->ack_code.func_ack.func_id = func_id;
	ack_head->ack_code.func_ack.ctrl_type = ctrl_type;
	
	USGPROTO_DBG("build func ack pkt successfully!\n");
	usg_pkt_print((u8 *)ack_reply, ntohs(ack_reply->header.length));
	return ack_reply;
}

/*
函数名称：build_rule_cfg_pkt
输入参数：操作，规则类型，规则msg、消息长度
返回结果：返回报文的首指针地址.
函数说明：构造规则报文
*/
usg_pkt *build_rule_cfg_pkt(u8 operation, u8* msg,u16 len)
{
	u16 rule_pkt_len = sizeof(usg_header)+sizeof(rule_info)+len;//头部+ 信息长度
	usg_pkt *rule_pkt = build_usg_header(USG_RULE_CFG,rule_pkt_len); 
	rule_info *rule_head = (rule_info *)rule_pkt->data;
	rule_head->operation = operation;
	strncpy(rule_head->rule_data,msg,len);	
	
	USGPROTO_DBG("build rule cfg pkt successfully!\n");
	usg_pkt_print((u8 *)rule_pkt, ntohs(rule_pkt->header.length));
	return rule_pkt;
}

/*
函数名称：build_func_ctrl_pkt
输入参数：func_id、ctrl_type
返回结果：返回报文的首指针地址.
函数说明：构造功能配置报文
*/
usg_pkt *build_func_ctrl_pkt(u8 func_id,u8 ctrl_type)
{
	u16 func_pkt_len = sizeof(usg_header)+ sizeof(func_info);//头部+ack_info子报文头部 
	usg_pkt *func_pkt = (usg_pkt *)build_usg_header(USG_FUNC_CTRL,func_pkt_len);
	func_info *func_head = (func_info*)func_pkt->data;
	func_head->func_id = func_id;
	func_head->ctrl_type = ctrl_type;
	
	USGPROTO_DBG("build func ctrl pkt successfully!\n");
	usg_pkt_print((u8 *)func_pkt, ntohs(func_pkt->header.length));
	return func_pkt;
}

/*
函数名称：build_cpu_stat_request_pkt
输入参数：无
返回结果：返回报文的首指针地址.
函数说明：构造CPU资源请求报文
*/
usg_pkt *build_cpu_stat_request_pkt()
{
	u16 cpu_request_len = sizeof(usg_header);
	usg_pkt *cpu_request_pkt = build_usg_header(USG_CPU_STATS_REQUEST,cpu_request_len);

	USGPROTO_DBG("build cpu request pkt successfully!\n");
	usg_pkt_print((u8 *)cpu_request_pkt, ntohs(cpu_request_pkt->header.length));
	return cpu_request_pkt;
}

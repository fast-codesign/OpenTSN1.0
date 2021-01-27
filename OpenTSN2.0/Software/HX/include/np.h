/** *************************************************************************
 *  @file       np.h
 *  @brief	    NP平台头文件
 *  @date		2020/06/05  星期四
 *  @author		psz
 *  @version	0.1.0
 ****************************************************************************/

#ifndef _NP_H__
#define _NP_H__
 
#include<stdio.h>
#include<stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <string.h>
#include <pcap.h>
//#include <libnet.h>
#include <arpa/inet.h>
#include <time.h>
#include <string.h>


#if 1
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <linux/if.h>
#include <linux/if_tun.h>
#include <linux/if_ether.h>
#include <linux/if_packet.h>
#include <fcntl.h>
#endif



#define TRUE 1
#define FALSE 0

typedef char s8;				/**< 有符号的8位（1字节）数据定义*/
typedef unsigned char u8;		/**< 无符号的8位（1字节）数据定义*/
typedef short s16;				/**< 有符号的16位（2字节）数据定义*/
typedef unsigned short u16;	/**< 无符号的16位（2字节）数据定义*/
typedef int s32;				/**< 有符号的32位（4字节）数据定义*/
typedef unsigned int u32;		/**< 无符号的32位（4字节）数据定义*/
typedef long long s64;				/**< 有符号的64位（8字节）数据定义*/
typedef unsigned long long u64;		/**< 无符号的64位（8字节）数据定义*/

#define MAX_SERVICE_NUM  32



//buf节点长度
#define BUF_NODE_LEN 16
//msg长度
#define MSG_NODE_LEN 72
//buf预留字段长度（共2048）
#define PAD_BUF_LEN  414 //2048-16-72-32-1514
//METADATA字段长度
#define METADATA_BUF_LEN 32
//以太网报文字段长度
#define ETH_PKT_BUF_LEN 1514



//资源池空闲缓冲区组数
#define MAX_POOL_NUM 32
//每组空闲缓冲区的空闲缓冲区块数目
#define MAX_LIST_NUM 1024
#define BUF_SIZE 2048


#define CONFIG_FILE "./np.cfg"


//数据报文metedata格式定义
struct um_metadata
{
  u64 dmid:8,//下一个处理分组的模块ID
  	  outport:4,//单播：分组输出端口ID，组播/泛洪：组播/泛洪表地址索引
  	  outtype:2,//00:单播；01：组播；10：泛洪；11：从输入接口输出。
  	  discard:1,//丢弃位
  	  pktdst:1,//分组的目的，0为网络接口输出，1为送CPU
  	  pad:16,//自定义以太网协议类型：0x0807
  	  pkttype:1,//报文类型，0：数据报文，1：控制报文
  	  pktsrc:1,//分组的来源，0为网络接口输入，1为CPU输入
  	  len:12,//包含MetaData字段的分组长度
  	  inport:4,//分组的输入端口号
  	  flow_index:12,//流索引号，根据五元组查表得到
  	  flow_hit:1,//流表命中标识，0未命中，1命中
  	  reserve:1;//保留
  u64 reserve1:1,//保留
      fin:1,
  	  syn:1,
  	  rst:1,
  	  ack:1,//  
  	  reserve2:27,//保留
  	  eth_type:16,//第十三、四字节（为以太网类型）
  	  reserve3:16;//保留
  u64 user[2];//用户自定义
};


//控制报文metedata格式定义
struct ctl_metadata
{
  u64 dmid:8,//下一个处理分组的模块ID
  	  srcmid:8,//源模块ID
  	  ethtype:16,//自定义以太网协议类型：0x0807
  	  pkttype:1,//报文类型，0：数据报文，1：控制报文
  	  reserve:16,//保留
  	  seq:12,//
  	  type:3;//请求类型，001：读帧；010写帧；011读响应帧；100：硬件主动触发帧
  u64 data:32,//数据值
      addr:32;//地址
};



//np数据报文定义
struct np_packet
{
	
	struct um_metadata um;		//数据报文metedata格式定义
	u8 data[1514];	//完整以太网报文数据，不含CRC数据
};




/************************************消息队列相关结构体定义、全局变量及API声明****************************************************/		
struct msg_node
{
	u64 msg_type:8,//msg类型
	    src_service_id:8,//源服务ID
	    um_type:4,//标识有无metedata和metedata长度
	    eth_pkt_len:16,//以太网报文长度	
	    reserve:28;//保留位	
	u8* pad_head_ptr;//填充报文头指针
	u8* eth_head_ptr;//以太网报文头指针
	u64 ext_domian[2];//扩展域
	struct um_metadata um;//数据报文metedata
}; 


struct msg_quene_node
{
	struct msg_node *msg; //消息
	struct msg_quene_node *next;
};


struct msg_quene
{
	u8 flag;//队列活跃标志.0:不活跃;1:活跃
	u8 service_id;//服务线程名称
	u16 size;//队列大小
	struct msg_quene_node *front;//队列首指针
	struct msg_quene_node *rear;//队列尾指针
};





typedef enum RES
{
	ERR = -1,
	SUCCESS=0,	
}NP_RES;

typedef enum QUEUE_TYPE
{
	TQ = 0,
	RQ=1,	
}NP_Q_TYPE;




//输入队列注册表锁
pthread_mutex_t rxq_mutex;
//输出队列注册表锁
pthread_mutex_t txq_mutex;
//输入队列注册表
struct msg_quene*  rxq_service_list[MAX_SERVICE_NUM];
//输出队列注册表
struct msg_quene* txq_service_list[MAX_SERVICE_NUM];

extern void hx_txq_rxq_service_list_init();
extern int hx_msg_quene_init(struct msg_quene* quene, u8 qtype);
extern int hx_msg_quene_destroy(struct msg_quene* queen, u8 qtype);
extern int hx_write_msg_quene_node_blocking(struct msg_quene* quene, struct msg_node *node);
extern int hx_write_msg_quene_node(struct msg_quene* quene, struct msg_node *node);
extern struct msg_node* hx_read_msg_quene_node_blocking(struct msg_quene* quene);
extern struct msg_node* hx_read_msg_quene_node(struct msg_quene* quene);



/************************************消息队列相关结构体定义、全局变量及API声明****************************************************/

/************************************缓冲区管理相关结构体定义、全局变量及API声明****************************************************/
/* buf地址节点 */
struct buf_node
{
	u8 *buf;
	struct buf_node *next;
};

struct buf_list
{
	int count;
	struct buf_node *head;
};




//空闲缓冲区资源池
u8 *idle_buf_pool[MAX_POOL_NUM];
struct buf_list idle_buf_list_bak;

//空闲缓冲区资源池互斥锁
pthread_mutex_t buf_pool_mutex;


extern int hx_buf_pool_init();//缓存池初始化
extern int hx_buf_pool_destroy( );//缓存池销毁
extern struct buf_list hx_buf_list_get( );//得到空闲缓冲区组
extern u8* hx_malloc_eth_pkt_buf(struct buf_list *buf_head);//从组缓存区得到一个buf节点中的eth地址
extern u8* hx_malloc_metedata_buf(struct buf_list *buf_head);//从组缓存区得到一个buf节点中的metedata地址
extern int hx_free_buf(struct buf_list *buf_head,struct msg_node *msg);//归还地址，缓冲区新增一个节点
extern int hx_free_buf_list(struct buf_list *buf_head);//归还地址，线程结束归还缓冲区



struct hx_context_arg
{
	u8 service_id; //服务线程编号
	u16 rxq_size; //输入队列大小
	u16 txq_size; //输出队列大小
};
struct hx_context
{
	struct msg_quene rxq; //输入队列
	struct msg_quene txq; //输出队列
	struct buf_list buffer_list;//空闲缓冲区链表
};
//extern struct hx_context  hx_init(struct hx_context_arg *arg);
extern int hx_init(struct hx_context *tmp_context,struct hx_context_arg *arg);
extern void hx_destroy(struct hx_context* context);

/************************************缓冲区管理相关结构体定义、全局变量及API声明****************************************************/

/************************************基础服务线程声明****************************************************/
extern int hx_data_service_thread_init();
extern int hx_controller_service_thread_init();

//extern int get_cfgx_file(const char *filpath, const char *nam, char *val);
struct hand_info
 {
	 u8 version;		 /* 版本号 */
	 u8 usg_type;			 /* 报文类型*/
	 u16 length;		 /* 报文总长度 */
	 u8 hand_type;			/* 握手报文类型 */
	 u8 pad[3]; 		/* 保留位 */
 };





/************************************基础服务线程声明****************************************************/

/************************************消息操作相关定义及声明****************************************************/
//msg类型
typedef enum
{
	NP_NMAC_RESPONSE = 0x00,	//np NMAC响应
	NP_STATIC = 0x01,	//np数据统计报文
	NP_SR = 0x02,//sr类型
	NP_TCP_PROXCY = 0x03, //np tcp proxcy
	NP_HW_HIT = 0x04,	//np硬件流表命中
	NP_NON_HW_HIT = 0x05,	//np硬件流表未命中	
	NP_SW_HIT_DISCARD = 0x06,	//np软件流表命中丢弃
	NP_SW_HIT_ACCEPT = 0x07,	//np软件流表命中允许通过
	NP_NON_SW_HIT_MIRROR = 0x08,	//np软件流表未命中且端口镜像类型
	NP_NON_SW_HIT_TAP = 0x09,	//np软件流表未命中且非端口镜像类型且arp\icmp报文
	NP_NON_SW_HIT_NON_TAP = 0x0A,	//np软件流表未命中且非端口镜像类型且非arp\icmp报文	
	NP_NON_SW_HIT_DISCARD = 0x0B,	//np软件流表未命中且应用服务需要丢弃
	NP_NON_SW_HIT_ACCEPT = 0x0C,	//np软件流表未命中且应用服务需要转发
	NP_LOG = 0x0D,	//np 日志统计信息
	NP_NMAC_REQUEST = 0x0E,	//np nmac请求
	NP_SERVICE_REQUEST = 0x0F,	//np 服务注册注销请求
	NP_DISPATCH = 0x10,	//np 编排策略
	NP_ACL_RULE = 0x11,	//np ACL规则
	NP_IP_BIND_RULE = 0x12,	//np 主机IP绑定规则
	NP_ROUTE_RULE = 0x13,	//np 静态路由
	NP_IDPS_RULE = 0x14,	//np IDPS规则
	NP_INTERFACE_INFO_RULE = 0x15,	//np 接口IP、Mac信息
	NP_TRAFFIC_RULE = 0x16,	//np 流量阈值
	NP_DDOS_CFG = 0x17,	//np DDOS开/关
	NP_RATE_CFG = 0x18,	//np 令牌桶限速
	NP_INTERFACE_ENABLE_CFG = 0x19,	//np 接口使能配置
	
	
	//TEST = 0x30,//test

}msg_type;

//服务ID
typedef enum
{
	DATA_REQUEST_ID= 0x00,  //数据请求线程
	DATA_RESPONSE_ID = 0x01, //数据响应线程
	PROTOCOL_REQUEST_ID = 0x02, //协议栈请求线程
	PROTOCO_RESPONSE_ID = 0x03, //协议栈响应线程
	CONTROL_REQUEST_ID = 0x04, //控制请求线程
	CONTROL_RESPONSE_ID = 0x05, //控制响应线程
	FLOW_MANAGER_ID = 0x06, //流管理线程
	ACL_SERVICE_ID = 0x07, //ACL服务线程
	IP_BIND_SERVICE_ID = 0x08, //IP绑定服务线程
	ROUTE_SERVICE_ID = 0x09, //路由服务线程
	IDS_SERVICE_ID = 0x0A, //IDS服务线程
	SRV6_SERVICE_ID = 0x0B, //SRV6服务线程
	SFW_SERVICE_ID = 0x0C, //SFW服务线程
	PORT_TRAFFIC_SERVICE_ID = 0x0D, //端口流量统计线程
	INTERFACE_CFG_SERVICE_ID= 0x0E, //接口配置线程
	FUNC_CFG_SERVICE_ID = 0x0F, //功能配置线程
	
	
	//TEST_SERVICE_ID = 0x10, //PTP线程

}service_id;


struct eth_pkt_info
{
	u16 len;//报文长度
	u8* buf;//报文存储地址
};

struct metedata_pkt_info
{
	u16 len;//报文长度
	u8* buf;//报文存储地址
};


void hx_data_receive_loop();
void hx_data_receive_destroy();

void hx_data_send_init();
void hx_data_send_destroy();
void hx_data_send(struct msg_node* tmp_msg_node);



extern struct eth_pkt_info hx_get_msg_eth_pkt (struct msg_node* node);//从msg中获取eth报文
extern int hx_get_msg_type(struct msg_node* node);//获取msg类型
extern u8* hx_get_msg_pad_buf(struct msg_node* node);//从msg中获取pad报文地址
extern struct msg_node* hx_common_eth_msg_build(u8* pkt,u16 len,u8 msg_type,u8 service_id);//（不带metedata）通用控制报文类型的msg构造
extern struct msg_node* hx_common_metedata_msg_build(u8* metedata,u16 len,u8 pkt_type,u8 service_id);//（带metedata）通用数据报文类型的msg构造


u8 get_msg_type_from_pkt(u8 *pkt,u16 len);



/************************************消息操作相关定义及声明****************************************************/

#define NPLIB_DEBUG 1


#ifdef NPLIB_DEBUG
	#define NPLIB_DBG(args...) do{printf("NPLIB-INFO:");printf(args);}while(0)
	#define NPLIB_ERR(args...) do{printf("NPLIB-ERROR:");printf(args);}while(0)
#else
	#define NPLIB_DBG(args...)
	#define NPLIB_DBG(args...)
#endif

extern void np_pkt_print(u8 *pkt,int len);//


/************************************外部线程函数定义及声明****************************************************/





extern void test_thread(void *argv);
extern int hx_test_handler();//测试线程


/************************************外部线程函数定义及声明****************************************************/
#endif


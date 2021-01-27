/** *************************************************************************
 *  @file       buf.c
 *  @brief	    NP平台基础服务线程
 *  @date		2020/06/05  星期四
 *  @author		psz
 *  @version	0.1.0
 ****************************************************************************/
#include "../include/np.h"
#include "../include/tools.h"



/*****************创建控制请求及响应线程函数**************************************/




#if 1
/*****************创建控制请求及响应线程函数**************************************/


int client_sockfd = -1;

int  client_state = FALSE;


char controller_ip[256] = {0};
char controller_port[256] = {0};



 struct hx_context ctl_request_context;//控制请求线程变量
 struct hx_context ctl_response_context;//控制响应线程变量

 
 
 void create_controller_io_service()
 {
 
	 int ret = 0;
	 const char opt = 1;
	 struct sockaddr_in controller_addr;
	 client_state = FALSE;
	 client_sockfd = socket(AF_INET, SOCK_STREAM, 0);
	 if(client_sockfd < 0)
	 {
		 NPLIB_DBG("Controller client start failed: create TCP socket failed!\n");
		 return ;
	 }

	 get_cfgx_file(CONFIG_FILE, "controller_ip", controller_ip);
	 get_cfgx_file(CONFIG_FILE, "controller_port", controller_port);
	 
	setsockopt(client_sockfd, IPPROTO_TCP, 1, &opt, sizeof(char));
	bzero(&controller_addr, sizeof(struct sockaddr_in));
	controller_addr.sin_family=AF_INET;
	inet_pton(AF_INET, controller_ip, &controller_addr.sin_addr);
	controller_addr.sin_port = htons(atoi(controller_port));
 
	 ret = connect(client_sockfd, (struct sockaddr *)&controller_addr, sizeof(controller_addr));
	 if(ret < 0)
	 {
		 NPLIB_DBG("Controller client start failed: connect TCP socket failed!\n");
		 close(client_sockfd);
		 sleep(10);
	 }
	 else
	 {
		 client_state = TRUE;
		 NPLIB_DBG("Controller client start : connect TCP socket success\n");
	 }
 
 }



 /*------------------------------控制响应----------------------*/
void ctl_response_thread(void *argv)//控制响应
{
   //创建及注册ctl_request的发送队列
   struct hx_context_arg  ctl_response_arg;
   memset(&ctl_response_arg,0,sizeof(struct hx_context_arg));
   ctl_response_arg.service_id=CONTROL_RESPONSE_ID;
   ctl_response_arg.rxq_size=1024;//发送队列
   hx_init(&ctl_response_context,&ctl_response_arg);
    
	//接收控制信息
	u8* tmp_mt_addr=NULL;
	struct msg_node* tmp_msg_node=NULL;
	int len=0;
	int shark_flag=1;
	
	struct hand_info shark_info;
	memset(&shark_info,0,sizeof(struct hand_info));
	shark_info.version=0x01;
	shark_info.usg_type=0x00;//握手
	shark_info.length=sizeof(struct hand_info);
	shark_info.usg_type=0x01;//HELLO
	while(1)
	{

	    if(client_state==FALSE) create_controller_io_service();//重新连接
		
        if(shark_flag==1)
        {
           len=send(client_sockfd, &shark_info, sizeof(struct hand_info), 0);//先向控制器发送握手只发一次
		   if(len>0)
		   	{
		   	  shark_flag=0;
		   	}
        }
		
		tmp_msg_node=hx_read_msg_quene_node(&ctl_response_context.rxq);
		if(tmp_msg_node!=NULL)
		{
			len = send(client_sockfd, (u8*)tmp_msg_node->eth_head_ptr, tmp_msg_node->eth_pkt_len, 0);
			hx_free_buf(&ctl_response_context.buffer_list,tmp_msg_node);//归还地址，ctl_response_buf_list缓冲区新增一个节点
			if(len == -1)//发送失败重连
			{
				perror("sendto fail\n");
				while(1)
				{
				   close(client_sockfd);
				   create_controller_io_service();
					if(client_state==TRUE)
					{
					   shark_flag=1;//重连成功需要重新发握手
					   break;
					}
					usleep(100);
				}

			}

		}
	}

	//线程结束注销队列、归还组缓存池
	hx_destroy(&ctl_response_context);
}

/*-------------------------------控制响应---------------------*/

 /*-------------------------------控制请求---------------------*/
void ctl_request_thread(void *argv)//控制请求
{
   
	//创建及注册ctl_request的发送队列
   struct hx_context_arg  ctl_request_arg;
   memset(&ctl_request_arg,0,sizeof(struct hx_context_arg));
   ctl_request_arg.service_id=CONTROL_REQUEST_ID;
   ctl_request_arg.txq_size=1024;//发送队列
   hx_init(&ctl_request_context,&ctl_request_arg);	 
    
	//接收控制信息
	u8* tmp_eth_addr=NULL;
	struct msg_node* tmp_msg_node=NULL;
	int len=0;
	u8 recvbuf[2000];
	while(1)
	{
	  
	  if((len=recv(client_sockfd, recvbuf, 1514, 0))>0)//客户端socket接收数据报文
	  	{
			
			tmp_eth_addr=hx_malloc_eth_pkt_buf(&ctl_request_context.buffer_list);//取一个缓存区ETH地址
			if(tmp_eth_addr==NULL) return;
			memcpy(tmp_eth_addr,recvbuf,len);//第一步将报文拷贝至缓存区

			NPLIB_DBG("ctl_request_thread  recvbuf tmp_eth_addr:%p\n",tmp_eth_addr);
			np_pkt_print(recvbuf,len);
			//第二步构造消息填充到发送队列   
			tmp_msg_node=(struct msg_node*)((u8*)tmp_eth_addr-METADATA_BUF_LEN-PAD_BUF_LEN-MSG_NODE_LEN);
            //NPLIB_DBG("tmp_msg_node:%p\n",tmp_msg_node);
			tmp_msg_node->src_service_id=CONTROL_REQUEST_ID;
			tmp_msg_node->msg_type=0x19;//recvbuf[1];//第二字节为消息类型（头=版本+类型+长度）
			
			tmp_msg_node->eth_pkt_len=len;
			tmp_msg_node->eth_head_ptr=(u8*)tmp_eth_addr;

			if(ERR==hx_write_msg_quene_node(&ctl_request_context.txq,tmp_msg_node))
			{

			  hx_free_buf(&ctl_request_context.buffer_list,tmp_msg_node);//如发送失败则归还缓冲区地址
			}

	  	}
	    else
	    {
	      usleep(10);
	    }
	  
	}

	//线程结束注销队列、归还组缓存池
	hx_destroy(&ctl_request_context);
	close(client_sockfd);
   
}

/*-------------------------------控制请求---------------------*/

/*****************创建控制请求及响应线程函数**************************************/
#endif



/*****************创建数据请求及响应线程函数**************************************/





struct hx_context data_request_context;//数据请求线程变量
struct hx_context data_response_context;//数据响应线程变量

/*-------------------------------创建数据响应线程函数---------------------------*/
void data_response_thread(void *argv)//数据响应
{

    
	struct hx_context_arg  data_response_arg;
	memset(&data_response_arg,0,sizeof(struct hx_context_arg));
	data_response_arg.service_id=DATA_RESPONSE_ID;//0x01
	data_response_arg.rxq_size=1024;
	hx_init(&data_response_context,&data_response_arg); 


	struct msg_node* tmp_msg_node=NULL;

	hx_data_send_init();
	
	while(1)//阻塞获取消息发送报文
	{
	   tmp_msg_node=hx_read_msg_quene_node(&data_response_context.rxq);//读取接收队列的消息
	   if(tmp_msg_node!=NULL)
	   	{
           	hx_data_send(tmp_msg_node);

			hx_free_buf(&data_response_context.buffer_list,tmp_msg_node);//发送完成释放一个

	   }
     
	}
	//线程结束注销队列、归还组缓存池
	hx_destroy(&data_response_context);

	hx_data_send_destroy();
}

/*-------------------------------创建数据响应线程函数---------------------------*/



/*-------------------------------创建数据请求线程---------------------------*/



void data_request_thread(void *argv)//数据请求
{
   //创建及注册data_request的发送队列

   
   struct hx_context_arg  data_request_arg;
   memset(&data_request_context,0,sizeof(struct hx_context));//一定要清零
   memset(&data_request_arg,0,sizeof(struct hx_context_arg));//一定要清零
   data_request_arg.service_id=DATA_REQUEST_ID;
   data_request_arg.txq_size=1024;
   hx_init(&data_request_context,&data_request_arg);

  // NPLIB_DBG("data_request :rxq %p txq:%p buf:%p\n",data_request_context.rxq.front,data_request_context.txq.front,data_request_context.buffer_list.head);

   //循环抓包
   hx_data_receive_loop();

   //线程结束注销队列、归还组缓存池
   hx_destroy(&data_request_context);

   hx_data_receive_destroy();

}

/*-------------------------------创建数据请求线程---------------------------*/

/*****************创建数据请求及响应线程函数**************************************/


int hx_data_service_thread_init()
{
     //创建数据请求线程
    pthread_t data_request_tid;
	if(pthread_create(&data_request_tid, NULL,(void *)data_request_thread, NULL) == -1)
	{
		NPLIB_DBG("create data_request error!\n");
		return ERR;
	}

	 //创建数据响应线程
   
	pthread_t data_response_tid;
	if(pthread_create(&data_response_tid, NULL,(void *)data_response_thread, NULL) == -1)
	{
		NPLIB_DBG("create data_response error!\n");
		return ERR;
	}

	return SUCCESS;

}


int hx_controller_service_thread_init()
{

	 //创建控制请求线程
    create_controller_io_service();//控制请求线程和响应线程先要建立套接字

	usleep(10);
	
    pthread_t ctl_request_tid;
	if(pthread_create(&ctl_request_tid, NULL,(void *)ctl_request_thread, NULL) == -1)
	{
		NPLIB_DBG("create data_request error!\n");
		return ERR;
	}

	 //创建控制响应线程
	pthread_t ctl_response_tid;
	if(pthread_create(&ctl_response_tid, NULL,(void *)ctl_response_thread, NULL) == -1)
	{
		NPLIB_DBG("create data_response error!\n");
		return ERR;
	}	
 
	return SUCCESS;
}



/** *************************************************************************
 *  @file       main.c
 *  @brief	    NP平台主线程
 *  @date		2020/06/05  星期四
 *  @author		psz
 *  @version	0.1.0
 ****************************************************************************/
#include "../include/np.h"
#include "../include/tools.h"


extern struct hx_context data_request_context;//数据请求线程变量

 //数据响应线程变量
 struct ether_header
 {
	 unsigned char ether_dhost[6];	 //目的mac
	 unsigned char ether_shost[6];	 //源mac
	 unsigned short ether_type; 	 //以太网类型
 };


 void ethernet_protocol_callback(unsigned char *argument,const struct pcap_pkthdr *packet_heaher,const unsigned char *packet_content)
{
    NPLIB_DBG("libpcap data\n");
    //np_pkt_print((u8*)packet_content,packet_heaher->len);
    if(packet_heaher->len<=METADATA_BUF_LEN)
    {
      printf("libpcap data is err \n");
    }
	//第一步将报文拷贝至缓存区
	u8* mt_addr;//没有metedata
	mt_addr=hx_malloc_metedata_buf(&data_request_context.buffer_list);//取一个缓存区mt地址
	if(mt_addr==NULL) return;
    memcpy(mt_addr,packet_content,packet_heaher->len);//将报文拷贝至缓存区

	//第二步构造消息填充到发送队列
	struct msg_node* tmp_msg_node=(struct msg_node*)((u8*)mt_addr-PAD_BUF_LEN-MSG_NODE_LEN);
	//tmp_msg_node->msg_type=NP_HW_HIT;//根据metedata数据填充
	
	//处理报文，获取报文的消息类型
	//u8 tmp_msg_type=0;	
	//tmp_msg_type = TEST;//ljs修改	
	//memcpy(&tmp_msg_type,mt_addr,1);//metedata第一字节为消息类型
	tmp_msg_node->msg_type = get_msg_type_from_pkt((u8*)packet_content,packet_heaher->len);	
	
	//tmp_msg_node->msg_type=tmp_msg_type;
	tmp_msg_node->src_service_id=DATA_REQUEST_ID;
	tmp_msg_node->eth_pkt_len=packet_heaher->len-METADATA_BUF_LEN;
	tmp_msg_node->eth_head_ptr=mt_addr+METADATA_BUF_LEN;
	memcpy(&tmp_msg_node->um,packet_content,METADATA_BUF_LEN);//拷贝metedata至msg的um
	//NPLIB_DBG("libpcap data tmp_msg_node->um.eth_type:%x dmid:%d\n",htons(tmp_msg_node->um.eth_type),tmp_msg_node->um.dmid);	

	if(ERR==hx_write_msg_quene_node(&data_request_context.txq,tmp_msg_node))
	{
	  NPLIB_DBG("hx_write_msg_quene_node fail\n");
	  hx_free_buf(&data_request_context.buffer_list,tmp_msg_node);
	}

}

void hx_data_receive_loop()
{
        char error_content[100];    //出错信息
		pcap_t * pcap_handle;
		unsigned char *mac_string;
		unsigned short ethernet_type;           //以太网类型
		char *net_interface =NULL;//"enaftgm1i0";                 //接口名字
		struct pcap_pkthdr protocol_header;
		struct ether_header *ethernet_protocol;

		char temp_net_interface[256] = {0};
		get_cfgx_file(CONFIG_FILE, "net_interface", temp_net_interface);
		net_interface=temp_net_interface;
		//printf("temp_net_interface:%s\n",temp_net_interface);
		
		//获取网络接口
		net_interface = pcap_lookupdev(error_content);//寻找网络设备
		//printf("net_interface:%s\n",net_interface);
		if(NULL == net_interface)
		{
		    perror("pcap_lookupdev");
		    exit(-1);
		}
		pcap_handle = pcap_open_live(net_interface,2000,1,0,error_content);//打开网络接口

		/*配置过滤器*/
#if 0
		struct bpf_program filter;
		pcap_compile(pcap_handle, &filter, "ether[12:2]=0x0807", 1, 0);
		pcap_setfilter(pcap_handle, &filter);
#endif

		//设置抓取方向为输入
		if(pcap_setdirection(pcap_handle,PCAP_D_IN)!=0)
		{
			//printf("88888\n");
			perror("error");

		}


		if(pcap_loop(pcap_handle,-1,ethernet_protocol_callback,NULL) < 0)//捕获数据包
		{
		    perror("pcap_loop");
		}
		pcap_close(pcap_handle);

		return;
}

void hx_data_receive_destroy()
{
	return;
}



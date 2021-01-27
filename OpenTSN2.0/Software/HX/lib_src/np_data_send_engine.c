/** *************************************************************************
 *  @file       main.c
 *  @brief	    NP平台主线程
 *  @date		2020/06/05  星期四
 *  @author		psz
 *  @version	0.1.0
 ****************************************************************************/
#include "../include/np.h"
#include "../include/tools.h"


int sock_raw_fd;
struct sockaddr_ll sll;	


void hx_data_send_init()
{
	//原始套接字发送
	sock_raw_fd = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
					//原始套接字地址结构
	struct ifreq req;					//网络接口地址


    
	char temp_net_interface[256] = {0};
	get_cfgx_file(CONFIG_FILE, "net_interface", temp_net_interface);


	strncpy(req.ifr_name,temp_net_interface, IFNAMSIZ);			//指定网卡名称
	//strncpy(req.ifr_name, "enaftgm1i0", IFNAMSIZ);			//指定网卡名称
	if(-1 == ioctl(sock_raw_fd, SIOCGIFINDEX, &req))	//获取网络接口
	{
		perror("ioctl");
		close(sock_raw_fd);
		exit(-1);
	}
	
	/*将网络接口赋值给原始套接字地址结构*/
	bzero(&sll, sizeof(sll));
	sll.sll_ifindex = req.ifr_ifindex;
	

	return ;
}

void hx_data_send(struct msg_node* tmp_msg_node)
{
	int len;
	
	//将发送出去的eth_type改为0x0809(大小端)，再将msg中metedata拷贝值缓存区mt位置，发送报文带mtdata
	tmp_msg_node->um.eth_type=0x0908;
	memcpy((u8*)tmp_msg_node->eth_head_ptr-METADATA_BUF_LEN,&tmp_msg_node->um,METADATA_BUF_LEN);
	len = sendto(sock_raw_fd, (u8*)tmp_msg_node->eth_head_ptr-METADATA_BUF_LEN, tmp_msg_node->eth_pkt_len+METADATA_BUF_LEN, 0 , (struct sockaddr *)&sll, sizeof(sll));
	if(len == -1)
	{
	   perror("sendto fail\n");
	}

	return;
}

void hx_data_send_destroy()
{
	close(sock_raw_fd);
}




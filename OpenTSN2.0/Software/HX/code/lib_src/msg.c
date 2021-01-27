/** *************************************************************************
 *  @file       msg.c
 *  @brief	    NP平台消息封装API
 *  @date		2020/06/05  星期四
 *  @author		psz
 *  @version	0.1.0
 ****************************************************************************/
#include "../include/np.h"


struct eth_pkt_info hx_get_msg_eth_pkt (struct msg_node* node)//从msg中获取eth报文
{
	struct eth_pkt_info tmp_pkt_info;
	tmp_pkt_info.buf=NULL;
	tmp_pkt_info.len=0;
	if(node==NULL)
	{
	    printf("msg_node is null\n");
		return tmp_pkt_info;
	}

	tmp_pkt_info.len =node->eth_pkt_len;
	tmp_pkt_info.buf=node->eth_head_ptr;
	return tmp_pkt_info;
}

int hx_get_msg_type(struct msg_node* node)//获取msg类型
{
    if(node==NULL)
	{
	    printf("msg_node is null\n");
		return ERR;
	}
    return node->msg_type;
}

u8* hx_get_msg_pad_buf(struct msg_node* node)//从msg中获取pad报文地址
{
   if(node==NULL)
	{
	    printf("msg_node is null\n");
		return NULL;
	}
   if(node->eth_head_ptr==NULL)
   	{
   	   printf("pad_head_buf is null\n");
		return NULL;
   	}

   return (u8*)node->eth_head_ptr-METADATA_BUF_LEN-PAD_BUF_LEN-MSG_NODE_LEN;
}


struct msg_node* hx_common_eth_msg_build(u8* pkt,u16 len,u8 msg_type,u8 service_id)//（不带metedata）通用控制报文类型的msg构造
{
	struct msg_node *tmp_msg=NULL; 
	if(pkt==NULL)
	{
	    printf("pkt is null\n");
		return tmp_msg;
	}
	tmp_msg=(struct msg_node *)(pkt-METADATA_BUF_LEN-PAD_BUF_LEN-MSG_NODE_LEN);
	tmp_msg->src_service_id=service_id;
	tmp_msg->eth_head_ptr=pkt;
	tmp_msg->eth_pkt_len=len;
    tmp_msg->um_type=0;//无metedata
	
	tmp_msg->msg_type=msg_type;
	return tmp_msg;
}


struct msg_node* hx_common_metedata_msg_build(u8* metedata,u16 len,u8 pkt_type,u8 service_id)//（带metedata）通用数据报文类型的msg构造
{
	struct msg_node *tmp_msg=NULL; 
	if(metedata==NULL)
	{
	    printf("metedata is null\n");
		return tmp_msg;
	}
	tmp_msg=(struct msg_node *)(metedata-PAD_BUF_LEN-MSG_NODE_LEN);
	tmp_msg->src_service_id=service_id;
	tmp_msg->eth_head_ptr=metedata+METADATA_BUF_LEN;
	tmp_msg->eth_pkt_len=len-METADATA_BUF_LEN;
    tmp_msg->um_type=1;//metedata长度为32

	tmp_msg->msg_type=pkt_type;

	memcpy(&tmp_msg->um,metedata,METADATA_BUF_LEN);//有metedata拷贝至msg的um
	return tmp_msg;
}



#if 0
int main()
{
  int ret;
  struct msg_node *tmp_msg;
  #if 0
  tmp_msg=(struct msg_node *)malloc(sizeof(struct msg_node));
  tmp_msg->eth_head_buf=(u8*)0x11111111111111;
  tmp_msg->eth_pkt_len=5;
  tmp_msg->msg_type=0x09;
  tmp_msg->discard_flag=0;
  tmp_msg->pad_head_buf=(u8*)0x2222222222222;
   struct eth_pkt_info pkt_info=hx_get_msg_eth_pkt(tmp_msg);
   NPLIB_DBG("eth_pkt_info buf:%p %u \n",pkt_info.buf,pkt_info.len);

  ret=hx_get_msg_type(tmp_msg);
  NPLIB_DBG("ret %d \n",ret);

  hx_set_msg_discard(tmp_msg);
   NPLIB_DBG("tmp_msg->discard_flag  %d \n",tmp_msg->discard_flag);

   hx_set_msg_outport(tmp_msg,5);
   hx_set_msg_ids_index(tmp_msg,8);
   NPLIB_DBG("tmp_msg->outport  %d  ids_index:%d\n",tmp_msg->outport,tmp_msg->ids_index);

   NPLIB_DBG("tmp_msg->pad_head_buf  %p \n",hx_get_msg_pad_buf(tmp_msg));
#endif
   struct buf_node *tmp_node=(struct buf_node*)malloc(BUF_SIZE);
   memset((u8*)tmp_node+16+32+32,0x11,10);
   //tmp_msg=hx_log_msg_build((u8*)tmp_node+16+32+32,10,5);
  // tmp_msg=hx_common_control_msg_build((u8*)tmp_node+16+32+32,15,5,6);
   tmp_msg=hx_common_pkt_msg_build((u8*)tmp_node+16+32,5,6,11);
   NPLIB_DBG("tmp_msg->msg_type  %u %p %p %x\n",tmp_msg->msg_type,tmp_node,tmp_msg->eth_head_buf,*((u8*)tmp_node+16+32+32));
   
  
}
#endif

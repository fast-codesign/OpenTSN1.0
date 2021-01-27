/** *************************************************************************
 *  @file       test_main.c
 *  @brief	    HX测试程序，对接收到的报文进行MAC地址比较，然后指定输出端口输出
 *  @date		2021/01/15  星期五
 *  @author		ljs
 *  @version	0.0.1
 ****************************************************************************/

#include "test_main.h"
#include "print.c"

#define TEST 0x30//定义TEST的消息类型
#define TEST_SERVICE_ID  0x10 //测试线程

struct hx_context  test_context;

//定义两个mac地址，用于匹配MAC地址，然后相应端口转发
u8 mac1[6] = {1,2,3,4,5,6};
u8 mac2[6] = {1,2,3,4,5,7};


int hx_test_contex_init()
{
	struct hx_context_arg  hx_test_arg;
	memset(&hx_test_arg,0,sizeof(struct hx_context_arg));
	
	hx_test_arg.service_id = TEST_SERVICE_ID;//
	hx_test_arg.rxq_size = 2048;
	hx_test_arg.txq_size = 2048;
	
	hx_init(&test_context,&hx_test_arg); 

	return 0;
}

int hx_test_contex_destroy()
{
	hx_destroy(&test_context); 
	return 0;
}


int get_outport(u8 *pkt)
{
	int outport = -1;
	if(memcmp(pkt,mac1,6)==0)
	{	
		printf("pkt mac=%d:%d:%d:%d:%d:%d\n",pkt[0],pkt[1],pkt[2],pkt[3],pkt[4],pkt[5]);
		printf("compare success\n");
		outport = 1;//指定输出端口
	}
	else if(memcmp(pkt,mac2,6)==0)
	{
		
		printf("pkt mac=%d:%d:%d:%d:%d:%d\n",pkt[0],pkt[1],pkt[2],pkt[3],pkt[4],pkt[5]);
		printf("compare success\n");
		outport = 2;//指定输出端口
	}		
	else
	{
		printf("pkt mac=%d:%d:%d:%d:%d:%d\n",pkt[0],pkt[1],pkt[2],pkt[3],pkt[4],pkt[5]);
		printf("compare fail\n");
	}
	
	return outport;
	
}

/*测试线程*/
void hx_test(void *argv)
{
	//声明msg头
	struct msg_node* tmp_msg_node = NULL;
	
	u8 *tmp_pkt = NULL;
	int outport = 0;
	
	hx_test_contex_init();

	while(1)
	{
		//从接收队列中读取数据，阻塞方式
		tmp_msg_node = hx_read_msg_quene_node_blocking(&(test_context.rxq));
		tmp_pkt      = tmp_msg_node->eth_head_ptr;

		outport = get_outport(tmp_pkt);//根据mac地址获取输出端口号
		
		
		if(outport == -1)
		{
			continue;
		}
		else
		{
			tmp_msg_node->reserve = outport;//输出端口
			tmp_msg_node->src_service_id = TEST_SERVICE_ID;
			tmp_msg_node->msg_type = TEST;
			if(ERR==hx_write_msg_quene_node(&test_context.txq,tmp_msg_node))
			{
				  printf("hx_write_msg_quene_node fail\n");
				  hx_free_buf(&test_context.buffer_list,tmp_msg_node);
			}
		}
	}

	hx_test_contex_destroy();

}


int hx_test_handler()
{
	int ret = -1;
	pthread_t test_id;

	
	ret=pthread_create(&test_id,NULL,(void *)hx_test,NULL); 
	
	if(0 != ret)
	{
		printf("create hx_test_handler fail!ret=%d err=%s\n",ret, strerror(ret));
	}

	return ret;
}

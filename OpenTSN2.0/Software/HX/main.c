/** *************************************************************************
 *  @file       main.c
 *  @brief	    NP平台主线程
 *  @date		2020/06/05  星期四
 *  @author		psz
 *  @version	0.1.0
 ****************************************************************************/
#include "./include/np.h"
#include "./include/schedule.h"



u8 get_msg_type_from_pkt(u8* pkt,u16 len)
{
	u8 msg_type = 0;
	msg_type = 0x30;//消息类型为TEST
	//目前把所有的报文都送往TEST服务
	return  msg_type;                       
	
}

int main(int argc,char* argv[])
{
	hx_txq_rxq_service_list_init();//平台服务队列初始化ALL	
	hx_buf_pool_init();//平台缓存池初始化ALL
	hx_schedule_init();//调度表部分初始化
	
   /*********外部服务线程*********/
   
   hx_test_handler();//测试线程
   
   


	hx_data_service_thread_init();//创建基础服务线程
	//hx_controller_service_thread_init();//创建基础服务线程
	
	sleep(1); 

	while(1)//调度
	{
	 	hx_msg_schedule();
		usleep(1);
	}

	hx_schedule_destroy();
	hx_buf_pool_destroy();//主线程结束，销毁缓存池（平台）

	return SUCCESS;

}

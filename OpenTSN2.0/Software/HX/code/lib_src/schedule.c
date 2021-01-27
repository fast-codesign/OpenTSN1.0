/** *************************************************************************
 *  @file       main.c
 *  @brief	    NP平台主线程
 *  @date		2020/06/05  星期四
 *  @author		psz
 *  @version	0.1.0
 ****************************************************************************/
#include "../include/schedule.h"


struct schedule_info schedule_table[MAX_SCHEDULE_NUM];
struct buf_list schedule_buf_list;

void hx_schedule_resource_init()
{
	schedule_buf_list=hx_buf_list_get();//调度线程为主线程只需要缓存区
	if(schedule_buf_list.head==NULL) 
		SCHEDULE_DBG("schedule_buf_list get buf fail \n");

	return;
}

#define BUF_LEN       100

#define NO_FLOW       0
#define NEW_FLOW      1

#define TYPE_SCHEDULE 10


void riprt(char *str)
{
	int len, i;

	if (str == NULL)
		return;
	len = strlen(str);
	if (len == 0) 
		return;

	for (i = 0; i < len; i++)
	{
		if (str[i] == '\r' || str[i] == '\n')
			str[i] = '\0';
	}
}

int flow_flag = 0;

void get_schedule_info()
{
	FILE *fp = NULL;
	int i = 0;
	char buf[BUF_LEN];
	char *save_pstr = NULL;
	char *fir_pstr = NULL;
	char *sec_pstr = NULL;

	int schedule_idx = 0;
	
	int tmp_schedule_idx = 0;
	
	u8 high=0,low=0;
	
	u8 tmp_src_service_id = 0;
	u8 tmp_dst_service_id = 0;
	u8 tmp_msg_type = 0;

	
	fp = fopen("./schedule_table", "r");
	if(fp == NULL)
	{
		printf("Could not read schedule_table file!\n");
		return ;
	}
	
	printf("Open schedule_table file successfully!\n");
	while(fgets(buf, BUF_LEN, fp) != NULL)
	{
		//printf("line content: %s", buf);
		riprt(buf);
		if(flow_flag == NO_FLOW)
		{
			if(!strcmp(buf, "{"))
			{
				//printf("Find a new flow!\n");
				flow_flag = NEW_FLOW;
			}
			else
				continue;
		}
		else if(flow_flag == NEW_FLOW)
		{
			fir_pstr = strtok_r(buf, ":", &sec_pstr);
			if(!strcmp(fir_pstr + 1, "type"))
			{
				if(!strcmp(sec_pstr, "schedule"))
				{
					flow_flag = TYPE_SCHEDULE;
					//printf("Find TS flow!\n");
				}
				else
					flow_flag = NO_FLOW;
			}
			else
				flow_flag = NO_FLOW;
			//printf("111111111flow_flag: %d\n",flow_flag);
		}

		else if(flow_flag == TYPE_SCHEDULE)
		{
			if(!strcmp(buf, "}"))
			{
				flow_flag = NO_FLOW;
#if 1
				for(tmp_schedule_idx=0;tmp_schedule_idx<schedule_idx;tmp_schedule_idx++)
				{
					printf("schedule[%d]:key=%4x,value=%2x\n", tmp_schedule_idx,
															 schedule_table[tmp_schedule_idx].key,
															 schedule_table[tmp_schedule_idx].value);
					
				}

#endif

			}
			else
			{
				fir_pstr = strtok_r(buf, ":", &sec_pstr);
				if(!strcmp(fir_pstr + 1, "src_service_id"))
				{
					fir_pstr = strtok_r(sec_pstr, ",", &sec_pstr);
					high = ((*fir_pstr > '9') && ((*fir_pstr <= 'F') || (*fir_pstr <= 'f'))) ? *fir_pstr - 48 - 7 : *fir_pstr - 48;
					low = (*(++ fir_pstr) > '9' && ((*fir_pstr <= 'F') || (*fir_pstr <= 'f'))) ? *(fir_pstr) - 48 - 7 : *(fir_pstr) - 48;					
					tmp_src_service_id = ((high & 0x0f) << 4 | (low & 0x0f));
					
					fir_pstr = strtok_r(sec_pstr, ":", &sec_pstr);
					fir_pstr = strtok_r(sec_pstr, ",", &sec_pstr);
					high = ((*fir_pstr > '9') && ((*fir_pstr <= 'F') || (*fir_pstr <= 'f'))) ? *fir_pstr - 48 - 7 : *fir_pstr - 48;
					low = (*(++ fir_pstr) > '9' && ((*fir_pstr <= 'F') || (*fir_pstr <= 'f'))) ? *(fir_pstr) - 48 - 7 : *(fir_pstr) - 48;					
					tmp_msg_type = ((high & 0x0f) << 4 | (low & 0x0f));

					fir_pstr = strtok_r(sec_pstr, ":", &sec_pstr);
					high = ((*sec_pstr > '9') && ((*sec_pstr <= 'F') || (*sec_pstr <= 'f'))) ? *sec_pstr - 48 - 7 : *sec_pstr - 48;
					low = (*(++ sec_pstr) > '9' && ((*sec_pstr <= 'F') || (*sec_pstr <= 'f'))) ? *(sec_pstr) - 48 - 7 : *(sec_pstr) - 48;
					tmp_dst_service_id = ((high & 0x0f) << 4 | (low & 0x0f));
									
					
					schedule_table[schedule_idx].key   = (tmp_src_service_id << 8 | tmp_msg_type);
					schedule_table[schedule_idx].value = tmp_dst_service_id;				

					schedule_idx++;
				}
				else
					continue;
			}

		}
		else
		{
			continue;
		}	
	}
		
	
}

void hx_schedule_init()
{
		hx_schedule_resource_init();

		for(int i=0;i<MAX_SCHEDULE_NUM;i++)
			{
			  schedule_table[i].key=0xffff;
		      schedule_table[i].value=0xff;
			}
		get_schedule_info();	
		SCHEDULE_DBG("np_schedule_init success \n");
		return;
}




void hx_msg_schedule()
{

		struct msg_quene *rd_msg_quene=NULL;
		struct msg_quene **wr_msg_quene=NULL;
		struct msg_node* tmp_msg=NULL;
		u8 hit_flag=0;
		u16 *msg_key=NULL;	
		for(int i=0;i<MAX_SERVICE_NUM;i++)
		{
		  if(txq_service_list[i]!=NULL)//轮询tx队列
		    {

			    
				rd_msg_quene=txq_service_list[i];
				tmp_msg=hx_read_msg_quene_node(rd_msg_quene);//先从tx队列读出消息
				if(tmp_msg==NULL)
				  continue;   
			  				
				
				 msg_key=(u16*)tmp_msg;//
				 
				
				 
                 for(int j=0;j<MAX_SCHEDULE_NUM;j++)//查调度表
                 {
                   if(*msg_key==schedule_table[j].key)
                   	{
                       NPLIB_DBG("main msg_key:%x j:%d\n",*msg_key,j);
                       if(schedule_table[j].value < MAX_SERVICE_NUM)
                       	{
	                   	   wr_msg_quene=&rxq_service_list[schedule_table[j].value];
			             
						   hx_write_msg_quene_node_blocking(*wr_msg_quene,tmp_msg);//然后写入rx队列

						   hit_flag=1;
	
                       	}
					   break;
                   	}

				 }

				 if(hit_flag==0)
				 {
				   SCHEDULE_DBG("  schedule_buf_list\n");
				   hx_free_buf(&schedule_buf_list,tmp_msg);//调度表中不存在，归还缓存区归还
				 }
			  
		  	}  
		}

		return;
}


void hx_schedule_destroy()
{
	hx_free_buf_list(&schedule_buf_list);//归还（调度线程)缓冲区	

	return;
}




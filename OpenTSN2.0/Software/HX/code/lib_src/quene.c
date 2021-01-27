/** *************************************************************************
 *  @file       quene.c
 *  @brief	    NP平台消息队列操作API
 *  @date		2020/06/05  星期四
 *  @author		psz
 *  @version	0.1.0
 ****************************************************************************/
#include "../include/np.h"

//输入队列注册表
struct msg_quene*  rxq_service_list[MAX_SERVICE_NUM];

//输出队列注册表
struct msg_quene* txq_service_list[MAX_SERVICE_NUM];
//输入队列注册表锁
pthread_mutex_t rxq_mutex;
//输出队列注册表锁
pthread_mutex_t txq_mutex;

void hx_txq_rxq_service_list_init()
{
	pthread_mutex_init(&rxq_mutex,NULL);
	pthread_mutex_init(&txq_mutex,NULL);
	for(int j=0;j<MAX_SERVICE_NUM;j++)
	{
	  txq_service_list[j]=NULL;
	  rxq_service_list[j]=NULL;
	}
}


int hx_msg_quene_init(struct msg_quene* quene, u8 qtype)//消息队列初始化
{
    struct msg_quene_node* head=NULL;
    struct msg_quene_node* tmp_node=NULL;

    if(quene==NULL) 
	 {
	    NPLIB_DBG("msg_quene err\n");
		return ERR;
	 }

	if(quene->service_id >= MAX_SERVICE_NUM) 
	 {
	    NPLIB_DBG("mquene->pthread_id err\n");
		return ERR;
	 }
	struct msg_quene_node* new_node = (struct msg_quene_node*)malloc(sizeof(struct	msg_quene_node));
	if (new_node == NULL)
	{ 
	   NPLIB_DBG("malloc fail\n");
	   return ERR; 
	}
	new_node->msg = NULL;
	new_node->next = new_node;
	
    head=new_node;//先malloc一个新节点作为头 
    //NPLIB_DBG("msg_quene head :%p\n",head);
	
	for(int i=0;i<quene->size-1;i++)//创建循环单链表节点
    {
       new_node = (struct msg_quene_node*)malloc(sizeof(struct msg_quene_node));//malloc新节点

	  // NPLIB_DBG("new_node :%p\n",new_node);
	   if (new_node == NULL)
		{ 
		   NPLIB_DBG("malloc fail\n");
		   return ERR; 
		}
	   new_node->msg=NULL;
	   new_node->next=NULL;

	   tmp_node=head;
	   while(tmp_node->next!=head)//遍历到最后节点
	   	{
	   	  tmp_node=tmp_node->next;
	   	}
	   tmp_node->next=new_node;
	   new_node->next=head;//保持最后节点的*next指向head
    }

	quene->front=head;
	quene->rear=head;

	//将注册队列头结点挂载到注册表
	if(qtype==TQ)
	{
	   pthread_mutex_lock(&txq_mutex);
	   
       //for(int j=0;j<MAX_SERVICE_NUM;j++)
		{
		
		   if(txq_service_list[quene->service_id]==NULL)//找到指针数组空项
		   	{
		   	   txq_service_list[quene->service_id]=quene;//将注册队列头结点挂载
		   	   NPLIB_DBG("register txq_service_list[%d]\n",quene->service_id);
		   	   //break;
		   	}
		}
	   pthread_mutex_unlock(&txq_mutex);
	}
	else if(qtype==RQ)
	{
	   pthread_mutex_lock(&rxq_mutex);
	   
       //for(int j=0;j<MAX_SERVICE_NUM;j++)
		{
		
		   if(rxq_service_list[quene->service_id]==NULL)//找到指针数组空项
		   	{
		   	   rxq_service_list[quene->service_id]=quene;//将注册队列头挂载
		   	   NPLIB_DBG("register rxq_service_list[%d]\n",quene->service_id);
		   	   //break;
		   	}
		}
	   pthread_mutex_unlock(&rxq_mutex);
	}

	return SUCCESS;
}

int hx_msg_quene_destroy(struct msg_quene* quene, u8 qtype)//队列销毁
{
   //从队列注册表卸载
   struct msg_quene* tmp_quene=NULL;
   if(qtype==TQ)
	{
	   pthread_mutex_lock(&txq_mutex);
	   
       for(int j=0;j<MAX_SERVICE_NUM;j++)
		{
		  if(txq_service_list[j]!=NULL)
		  	{
				tmp_quene=txq_service_list[j];
				NPLIB_DBG("tmp_quene pthread_id:%d\n",tmp_quene->service_id);
				if(tmp_quene->service_id==quene->service_id)//找到指针数组空项
				{
					txq_service_list[j]=NULL;//将注册队列头结点卸载
					break;
				}
		  	}
		}
	   pthread_mutex_unlock(&txq_mutex);
	}
	else if(qtype==RQ)
	{
	   pthread_mutex_lock(&rxq_mutex);
	   
       for(int j=0;j<MAX_SERVICE_NUM;j++)
		{
		  if(rxq_service_list[j]!=NULL)
		  	{
		
			      tmp_quene=rxq_service_list[j];
				  NPLIB_DBG("tmp_quene :%d\n",tmp_quene->service_id);
					if(tmp_quene->service_id==quene->service_id)//找到指针数组空项
					{
						rxq_service_list[j]=NULL;//将注册队列头结点卸载
						break;
					}
		  	}
		}
	   pthread_mutex_unlock(&rxq_mutex);
	}
    tmp_quene=NULL;
   

   //销毁队列节点
    struct msg_quene_node* cur_node=quene->front;
	struct msg_quene_node* tmp_node=NULL;
	int i=0;
	while(cur_node->next!=quene->front)
	{
	  tmp_node=cur_node->next;
	  free(cur_node);
	  cur_node=tmp_node;
	  i++;
	}
	i++;
	free(cur_node);
	if(i!=quene->size)//释放节点数是否等于申请节点数
	{
	  NPLIB_DBG("quene_destroy fail\n");
	  return -1;
	}
    NPLIB_DBG("quene_destroy num：%d\n",i);
	quene->front=NULL;
	quene->rear=NULL;

    return SUCCESS;
}
int hx_msg_quene_print(struct msg_quene* quene)
{
   struct msg_quene_node* tmp_node=quene->front;
   while(tmp_node->next!=quene->front)
   	{
   	   if(tmp_node->msg!=NULL)
   	   	{
   	      NPLIB_DBG("quene_print :%p %p\n",tmp_node,tmp_node->msg);
   	   	}
	   else
	   	{
	   	   NPLIB_DBG("quene_print :%p %p\n",tmp_node,tmp_node->msg);
	   	}
	   tmp_node=tmp_node->next;
   	}
    NPLIB_DBG("quene_print :%p %p\n",tmp_node,tmp_node->msg);//环形链表的最后一个
}


int hx_write_msg_quene_node_blocking(struct msg_quene* quene, struct msg_node *node)//队列阻塞写
{
   if(node==NULL) return ERR;
	while(1)
		{
			if(quene->rear->next==quene->front)//队列已经满了
			{


			   //NPLIB_DBG("quene is full\n");
			   usleep(100);
			}
			else
			{
			  quene->rear->msg= node;//挂入消息节点
			  quene->rear=quene->rear->next;//尾节点后移
			  return 0;
			}
		}

	return SUCCESS;
}
int hx_write_msg_quene_node(struct msg_quene* quene, struct msg_node *node)//队列写
{
    if(node==NULL) return ERR;
	if(quene->rear->next==quene->front)//队列已经满了
	{
	   return ERR;
	}
	else
	{
	  quene->rear->msg= node;//挂入消息节点
	  quene->rear=quene->rear->next;//尾节点后移
	  return SUCCESS;
	}
}


struct msg_node* hx_read_msg_quene_node_blocking(struct msg_quene* quene)//队列阻塞读
{
	struct msg_node* tmp_node=NULL;
    while(1)
  	{
		if(quene->rear==quene->front)//队列空
		{
		   usleep(100);
		}
		else
		{
		  tmp_node= quene->front->msg;//取出头结点

		  quene->front->msg=NULL;//add by psz 6.5
		  quene->front=quene->front->next;//头节点后移
		  return tmp_node;
		}
  	}
	return NULL;
}


struct msg_node* hx_read_msg_quene_node(struct msg_quene* quene)//队列读
{
	struct msg_node* tmp_node=NULL;
   
		if(quene->rear==quene->front)//队列空
		{
		   return NULL;
		}
		else
		{
		  tmp_node= quene->front->msg;//取出头结点

		  quene->front->msg=NULL;//add by psz 6.5
		  quene->front=quene->front->next;//头节点后移
		  return tmp_node;
		}
  	
	return NULL;
}


#if 0
struct hx_context  hx_init(struct hx_context_arg *arg)
{
	struct hx_context tmp_context;

	memset(&tmp_context,0,sizeof(struct hx_context));

	if(arg->rxq_size > 0)//注册输入队列
	{

	     NPLIB_DBG(" rxq 11111 \n");
	    tmp_context.rxq.flag=1;
		tmp_context.rxq.service_id=arg->service_id;
		tmp_context.rxq.size=arg->rxq_size;
		if(hx_msg_quene_init(&tmp_context.rxq,RQ)==ERR) NPLIB_DBG("rxq creat fail\n");
		
	}
   
   if(arg->txq_size > 0)//注册输出队列
	{
	   NPLIB_DBG(" txq 11111 \n");
	    tmp_context.txq.flag=1;
		tmp_context.txq.service_id=arg->service_id;
		tmp_context.txq.size=arg->txq_size;
		if(hx_msg_quene_init(&tmp_context.txq,TQ)==ERR) NPLIB_DBG("rxq creat fail\n");

		 NPLIB_DBG(" txq 11111 :%p\n",&tmp_context.txq.front);
	}

   //获取空闲组缓存池
   tmp_context.buffer_list=hx_buf_list_get();//取一组

   NPLIB_DBG(" buf list 11111 :%p\n",tmp_context.buffer_list);
   if(tmp_context.buffer_list.head==NULL) 
   	    NPLIB_DBG(" get buf fail \n");	

   return tmp_context;
   
}
#endif


int hx_init(struct hx_context *tmp_context,struct hx_context_arg *arg)
{


	if(arg->rxq_size > 0)//注册输入队列
	{
	    tmp_context->rxq.flag=1;
		tmp_context->rxq.service_id=arg->service_id;
		tmp_context->rxq.size=arg->rxq_size;
		if(hx_msg_quene_init(&tmp_context->rxq,RQ)==ERR) NPLIB_DBG("rxq creat fail\n");
		
	}
   
   if(arg->txq_size > 0)//注册输出队列
	{
	    tmp_context->txq.flag=1;
		tmp_context->txq.service_id=arg->service_id;
		tmp_context->txq.size=arg->txq_size;
		if(hx_msg_quene_init(&tmp_context->txq,TQ)==ERR) NPLIB_DBG("rxq creat fail\n");

		// NPLIB_DBG(" hx_init txq  :%p\n",tmp_context->txq.front);
	}

   //获取空闲组缓存池
   tmp_context->buffer_list=hx_buf_list_get();//取一组

   //NPLIB_DBG(" hx_init buf list :%p txq:%p\n",tmp_context->buffer_list.head,tmp_context->txq.front);
   if(tmp_context->buffer_list.head==NULL) 
   	    NPLIB_DBG(" get buf fail \n");	

   return SUCCESS;
   
}

void hx_destroy(struct hx_context* context)
{

   if(context->rxq.flag==1)
   	{
      hx_msg_quene_destroy(&context->rxq,RQ);
   	}
   if(context->txq.flag==1)
   	{
      hx_msg_quene_destroy(&context->txq,TQ);
   	}
   hx_free_buf_list(&context->buffer_list);
}


#if 0
int main()
{

     pthread_mutex_init(&rxq_mutex,NULL);
	 pthread_mutex_init(&txq_mutex,NULL);
	 for(int j=0;j<MAX_SERVICE_NUM;j++)
		{
		  txq_service_list[j]=NULL;
		  rxq_service_list[j]=NULL;
		}
    struct msg_quene daq_msg_tq;//创建队列1
    daq_msg_tq.num=4;
	daq_msg_tq.flag=1;
	daq_msg_tq.pthread_id=1;
	if(hx_msg_quene_init(&daq_msg_tq,TQ)==ERR)
        NPLIB_DBG("daq_msg_tx creat fail\n");
	#if 0   //创建队列及注册测试
	struct msg_quene daq_msg_tq1;//创建队列2
    daq_msg_tq1.num=4;
	daq_msg_tq1.flag=1;
	daq_msg_tq1.pthread_id=2;
	if(hx_msg_quene_init(&daq_msg_tq1,TQ)==ERR)
        NPLIB_DBG("daq_msg_tx creat fail\n");

	 for(int j=0;j<MAX_SERVICE_NUM;j++)
		{
		  NPLIB_DBG("txq_service_list %p\n",txq_service_list[j]);
		  NPLIB_DBG("rxq_service_list %p\n",rxq_service_list[j]);
		}
    #endif


	   //队列写测试
      struct msg_node* node1=(struct msg_node*)malloc(sizeof(struct msg_node));
	  node1->flow_id=1000;
	  node1->outport=5; 
      //hx_write_msg_quene_node_blocking(&daq_msg_tq,node1);
     NPLIB_DBG("daq_msg_tq front %p rear %p\n",daq_msg_tq.front,daq_msg_tq.rear); 
	  hx_write_msg_quene_node(&daq_msg_tq,node1);
	  NPLIB_DBG("daq_msg_tq front %p rear %p\n",daq_msg_tq.front,daq_msg_tq.rear);
#if 1
      struct msg_node* node2=(struct msg_node*)malloc(sizeof(struct msg_node));
	  node2->flow_id=2000;
	  node2->outport=25; 
      //hx_write_msg_quene_node_blocking(&daq_msg_tq,node2);
      hx_write_msg_quene_node(&daq_msg_tq,node2);
	  
	  struct msg_node* node3=(struct msg_node*)malloc(sizeof(struct msg_node));
	  node3->flow_id=3000;
	  node3->outport=35; 
     // hx_write_msg_quene_node_blocking(&daq_msg_tq,node3);
      hx_write_msg_quene_node(&daq_msg_tq,node3);
	  
	  struct msg_node* node4=(struct msg_node*)malloc(sizeof(struct msg_node));
	  node4->flow_id=4000;
	  node4->outport=45; 
      hx_write_msg_quene_node(&daq_msg_tq,node4);

   #endif

	  
	  hx_msg_quene_print(&daq_msg_tq);


	  //队列读测试

       struct msg_node* read_node=NULL;
	  //read_node=hx_read_msg_quene_node_blocking(&daq_msg_tq);
	  read_node=hx_read_msg_quene_node(&daq_msg_tq);
	  if(read_node!=NULL)
	  NPLIB_DBG("read_node :%p %d %d\n",read_node,read_node->flow_id,read_node->outport);

	  read_node=hx_read_msg_quene_node(&daq_msg_tq);
	  if(read_node!=NULL)
	  NPLIB_DBG("read_node :%p %d %d\n",read_node,read_node->flow_id,read_node->outport);

	  read_node=hx_read_msg_quene_node(&daq_msg_tq);
	  if(read_node!=NULL)
	  NPLIB_DBG("read_node :%p %d %d\n",read_node,read_node->flow_id,read_node->outport);

      read_node=hx_read_msg_quene_node(&daq_msg_tq);
	  if(read_node!=NULL)
	  NPLIB_DBG("read_node :%p %d %d\n",read_node,read_node->flow_id,read_node->outport);
	 
	// hx_msg_quene_print(&daq_msg_tq);
	 hx_msg_quene_destroy(&daq_msg_tq,TQ);
	// hx_msg_quene_destroy(&daq_msg_tq1,RQ);

	
    return 0;
 }
#endif
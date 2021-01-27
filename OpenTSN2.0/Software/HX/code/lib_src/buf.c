/** *************************************************************************
 *  @file       buf.c
 *  @brief	    NP平台缓冲区管理API
 *  @date		2020/06/05  星期四
 *  @author		psz
 *  @version	0.1.0
 ****************************************************************************/
#include "../include/np.h"



//空闲缓冲区资源池
u8 *idle_buf_pool[MAX_POOL_NUM];
struct buf_list idle_buf_list_bak;

//空闲缓冲区资源池互斥锁
pthread_mutex_t buf_pool_mutex;




int hx_buf_pool_init()//缓存池初始化
{
   struct buf_node* head_node = NULL;
   struct buf_node* tmp_node = NULL;
   struct buf_node* new_node = NULL;
   int i=0,j=0;
   for(i=0;i<MAX_POOL_NUM;i++)
   	{
   	  idle_buf_pool[i]=NULL;//空闲缓冲区组先指向空指针
   	}
   idle_buf_list_bak.count=0;//备用缓存池初始化
   idle_buf_list_bak.head=NULL;
   pthread_mutex_init(&buf_pool_mutex,NULL);//创建空闲缓冲区资源池互斥锁

  
   for(i=0;i<MAX_POOL_NUM;i++)//缓存组个数
   	{
       tmp_node=(struct buf_node*)malloc(BUF_SIZE);
		if (tmp_node == NULL)
		{ 
			NPLIB_DBG("malloc fail\n");
			return ERR; 
		}
	   tmp_node->next=NULL;
		tmp_node->buf=NULL;//目前未用
	   memset((u8*)tmp_node+16,0x00,BUF_SIZE-16);
	   head_node=tmp_node;
	  // NPLIB_DBG("buf_list_head[%i] %p\n",i,head_node);//先malloc头结点
	   for(j=0;j<MAX_LIST_NUM-1;j++)//每组的个数
	   	{
			new_node=(struct buf_node* )malloc(BUF_SIZE);
			
			if (new_node == NULL)
			{ 
				NPLIB_DBG("malloc fail\n");
				return ERR; 
			}
			// NPLIB_DBG("new_node %p\n",new_node);//先malloc头结点
			new_node->next=NULL;
			new_node->buf=NULL;//目前未用
			memset((u8*)new_node+16,0x00,BUF_SIZE-16);
			tmp_node->next=new_node;
			tmp_node=new_node;
	   	}
	   idle_buf_pool[i]=(u8*)head_node;//将头结点加入缓存池组
   	}
   return SUCCESS;
}
int hx_buf_pool_destroy( )//缓存池销毁
{
   struct buf_node* tmp_node = NULL;
   struct buf_node* new_node = NULL;
   int i=0,j=0;
   for(i=0;i<MAX_POOL_NUM;i++)//缓存组个数
   	{
   	   tmp_node=(struct buf_node*)idle_buf_pool[i];
	   if (tmp_node != NULL)
		{ 
		   for(j=0;j<MAX_LIST_NUM;j++)
		   	{
		   	   new_node=tmp_node->next;
			   if(tmp_node!=NULL) free(tmp_node);
		   	   tmp_node=new_node;
		   	}
		   if(j!=MAX_LIST_NUM) NPLIB_DBG("buf_pool[%d] %d fail\n",i,j);
		}
	   idle_buf_pool[i]=NULL;
   	}


   tmp_node=idle_buf_list_bak.head;
   idle_buf_list_bak.head=NULL;
   idle_buf_list_bak.count=0;
   while(tmp_node!=NULL)
   	{
   	   new_node=tmp_node->next;
	  if(tmp_node!=NULL) free(tmp_node);
	  tmp_node=new_node;
   	}
    pthread_mutex_destroy(&buf_pool_mutex);
}
struct buf_list hx_buf_list_get( )//得到空闲缓冲区组
{

   struct buf_list tmp_buf_list;
   tmp_buf_list.count=0;
   tmp_buf_list.head=NULL;

   for(int i=0;i<MAX_POOL_NUM;i++)
   	{
   	    if(idle_buf_pool[i]!=NULL)
	    {
	      pthread_mutex_lock(&buf_pool_mutex);
	      tmp_buf_list.head=(struct buf_node *)idle_buf_pool[i];
		  
          idle_buf_pool[i]=NULL;
		  tmp_buf_list.count=MAX_LIST_NUM;

		  NPLIB_DBG("hx_buf_list_get idle_buf_pool[%d]\n",i);
		  pthread_mutex_unlock(&buf_pool_mutex);
		  return tmp_buf_list;
	    }
   	}
   
    return tmp_buf_list;
   
   
}
u8* hx_malloc_eth_pkt_buf(struct buf_list *buf_head)//从组缓存区得到一个buf节点中的eth地址
{//从链表头取节点
   u8* tmp_ptr=NULL;
   struct buf_list tmp_buf_list;
   if(buf_head->head!=NULL)
   	{
   	  buf_head->count--;
	  tmp_ptr=(u8 *)buf_head->head+BUF_NODE_LEN+MSG_NODE_LEN+PAD_BUF_LEN+METADATA_BUF_LEN;

	  //NPLIB_DBG("hx_malloc_eth_pkt_buf head :%p %p count:%d\n",buf_head->head,tmp_ptr,buf_head->count);


	  buf_head->head=buf_head->head->next;
       
	  return tmp_ptr;
   	}
    else
    {
       tmp_buf_list=hx_buf_list_get();//获取新的缓存区组
	   buf_head->head=tmp_buf_list.head;
       buf_head->count=tmp_buf_list.count;
	  // NPLIB_DBG("hx_malloc_eth_pkt_buf head:%p count:%d\n",buf_head->head,buf_head->count);
       if(buf_head->head==NULL) 
      	{
	  	  NPLIB_DBG("hx_buf_list_get fail \n");
		  return NULL;
      	}
	    else
	    {
	       buf_head->count--;
	       tmp_ptr=(u8* )(buf_head->head)+BUF_NODE_LEN+MSG_NODE_LEN+PAD_BUF_LEN+METADATA_BUF_LEN;
          // NPLIB_DBG("hx_malloc_eth_pkt_buf head :%p count:%d\n",buf_head->head,buf_head->count);
		   buf_head->head=buf_head->head->next;
	       return tmp_ptr;
		}
    }
   

}

u8* hx_malloc_metedata_buf(struct buf_list *buf_head)//从组缓存区得到一个buf节点中的metedata地址
{//从链表头取节点
   u8* tmp_ptr=NULL;
   struct buf_list tmp_buf_list;
   if(buf_head->head!=NULL)
   	{
   	  buf_head->count--;
	  tmp_ptr=(u8 *)buf_head->head+BUF_NODE_LEN+MSG_NODE_LEN+PAD_BUF_LEN;

	  //NPLIB_DBG("hx_malloc_metedata_buf :%p count:%d\n",buf_head->head,buf_head->count);


	  buf_head->head=buf_head->head->next;
       
	  return tmp_ptr;
   	}
    else
    {
       tmp_buf_list=hx_buf_list_get();
	   buf_head->head=tmp_buf_list.head;
       buf_head->count=tmp_buf_list.count;
	  // NPLIB_DBG("hx_malloc_metedata_buf head:%p count: %d\n",buf_head->head,buf_head->count);
       if(buf_head->head==NULL) 
      	{
	  	  NPLIB_DBG("hx_buf_list_get fail \n");
		  return NULL;
      	}
	    else
	    {
	       buf_head->count--;
	       tmp_ptr=(u8* )(buf_head->head)+BUF_NODE_LEN+MSG_NODE_LEN+PAD_BUF_LEN;
          // NPLIB_DBG("hx_malloc_metedata_buf head :%p count:%d\n",buf_head->head,buf_head->count);
		   buf_head->head=buf_head->head->next;
	       return tmp_ptr;
		}
    }
   

}
int hx_free_buf(struct buf_list *buf_head,struct msg_node *msg)//归还地址，缓冲区新增一个节点
{

   int i;
   struct buf_node *new_buf_node=NULL;//先用头插法插入节点
   if(msg==NULL) return ERR;
   new_buf_node=(struct buf_node *)((u8*)(msg)-BUF_NODE_LEN);

   if(buf_head->head==NULL)
   	{
   	   buf_head->head=new_buf_node;
	   buf_head->head->next=NULL;
	   buf_head->count++;
   	}
   else
   	{
		new_buf_node->next=buf_head->head;
		buf_head->head=new_buf_node;
		buf_head->count++;
	
   	}
   //NPLIB_DBG("hx_free_buf %p count: %d\n",buf_head->head,buf_head->count);
     
   
   struct buf_node *new_buf_head=NULL;//归还组缓存
   struct buf_node *tmp_buf_node=NULL;
   if(buf_head->count==2*MAX_LIST_NUM)
   {
      // NPLIB_DBG("hx_free_buf %p count: %d\n",buf_head->head,buf_head->count);
		new_buf_head=buf_head->head;
		tmp_buf_node=new_buf_head;//截断形成新链表
		for(int i=0;i<MAX_LIST_NUM-1;i++)
		{
			buf_head->head=buf_head->head->next;
			buf_head->count--;
			tmp_buf_node=tmp_buf_node->next;
		}
		buf_head->head=buf_head->head->next;
		buf_head->count--;
		tmp_buf_node->next=NULL;
        //NPLIB_DBG("hx_free_buf1111 %p count: %d\n",buf_head->head,buf_head->count);

		for(int i=0;i<MAX_POOL_NUM;i++)
		{
		   if(idle_buf_pool[i]==NULL)
		   	{
				pthread_mutex_lock(&buf_pool_mutex);
				idle_buf_pool[i]=(u8*)new_buf_head;
				NPLIB_DBG("hx_free_buf idle_buf_pool[%d]\n",i);   
				pthread_mutex_unlock(&buf_pool_mutex);
				return SUCCESS;
		   	}
		 }
	  
   }
   return SUCCESS;
}
int hx_free_buf_list(struct buf_list *buf_head)//主线程调用，释放所有
{

    struct buf_node *tmp_head=NULL;
    if(buf_head->head==NULL) return ERR;

	//第一步归还至整组归还至空闲缓存池，第二步把备用的返还空闲缓存池
	if(buf_head->count>MAX_LIST_NUM)
	{
		struct buf_node *new_buf_head=NULL;//归还组缓存
		struct buf_node *tmp_buf_node=NULL;
		new_buf_head=buf_head->head;
		tmp_buf_node=new_buf_head;//截断形成新链表,先归还至空闲缓存区组
		for(int i=0;i<MAX_LIST_NUM-1;i++)
		{
			buf_head->head=buf_head->head->next;
			buf_head->count--;
			tmp_buf_node=tmp_buf_node->next;
		}
		buf_head->head=buf_head->head->next;
		buf_head->count--;
		tmp_buf_node->next=NULL;

		for(int i=0;i<MAX_POOL_NUM;i++)
		{
		   if(idle_buf_pool[i]==NULL)
		   	{
				pthread_mutex_lock(&buf_pool_mutex);
				idle_buf_pool[i]=(u8*)new_buf_head;
				NPLIB_DBG("hx_free_buf_list idle_buf_pool[%d]\n",i);   
				pthread_mutex_unlock(&buf_pool_mutex);
				break;
		   	}
		 }
	    //剩余的归还至备用缓存池
        
		if(idle_buf_list_bak.head==NULL)
		{
		  pthread_mutex_lock(&buf_pool_mutex);
		  idle_buf_list_bak.head=buf_head->head;
		  idle_buf_list_bak.count=buf_head->count;
		  pthread_mutex_unlock(&buf_pool_mutex);
          buf_head->head=NULL;
		  buf_head->count=0;
		}
		else
		{
		   if(buf_head->head!=NULL)
		   	{
				tmp_head=buf_head->head;
				while(tmp_head->next!=NULL)//头插法(整体插入)，先把链表起来
				{
				  tmp_head=tmp_head->next;
				}
				pthread_mutex_lock(&buf_pool_mutex);
				tmp_head->next=idle_buf_list_bak.head;
				idle_buf_list_bak.head=buf_head->head;
				idle_buf_list_bak.count += buf_head->count;
				pthread_mutex_unlock(&buf_pool_mutex);
				buf_head->head=NULL;
				buf_head->count=0;
		   	}
		}
	    
		
	}
	else if(buf_head->count==MAX_LIST_NUM)
	{
	    for(int i=0;i<MAX_POOL_NUM;i++)
		{
		   if(idle_buf_pool[i]==NULL)
		   	{
				pthread_mutex_lock(&buf_pool_mutex);
				idle_buf_pool[i]=(u8*)buf_head->head;
				buf_head->head=NULL;
				buf_head->count=0;
				NPLIB_DBG("hx_free_buf_list idle_buf_pool[%d]\n",i);   
				pthread_mutex_unlock(&buf_pool_mutex);
				break;
		   	}
		 }
	}
	else
	{
	   if(idle_buf_list_bak.head==NULL)
		{
		  pthread_mutex_lock(&buf_pool_mutex);
		  idle_buf_list_bak.head=buf_head->head;
		  idle_buf_list_bak.count=buf_head->count;
		  pthread_mutex_unlock(&buf_pool_mutex);
          buf_head->head=NULL;
		  buf_head->count=0;
		}
		else
		{
		  
			tmp_head=buf_head->head;
			while(tmp_head->next!=NULL)//头插法(整体插入)，先把链表起来
			{
			  tmp_head=tmp_head->next;
			}
			
			pthread_mutex_lock(&buf_pool_mutex);
			tmp_head->next=idle_buf_list_bak.head;
			idle_buf_list_bak.head=buf_head->head;
			idle_buf_list_bak.count += buf_head->count;
			pthread_mutex_unlock(&buf_pool_mutex);
			buf_head->head=NULL;
			buf_head->count=0;
		}
	}


   //归还备用的至缓存池
	if(idle_buf_list_bak.count > MAX_LIST_NUM)
	{
		
	    struct buf_node *new_buf_head=NULL;//归还组缓存
		struct buf_node *tmp_buf_node=NULL;

		new_buf_head=idle_buf_list_bak.head;
		tmp_buf_node=new_buf_head;//截断形成新链表,先归还至空闲缓存区组
		for(int i=0;i<MAX_LIST_NUM-1;i++)
		{
			idle_buf_list_bak.head=idle_buf_list_bak.head->next;
			idle_buf_list_bak.count--;
			tmp_buf_node=tmp_buf_node->next;
		}
		idle_buf_list_bak.head=idle_buf_list_bak.head->next;
		idle_buf_list_bak.count--;
		tmp_buf_node->next=NULL;

		for(int i=0;i<MAX_POOL_NUM;i++)
		{
		   if(idle_buf_pool[i]==NULL)
		   	{
				pthread_mutex_lock(&buf_pool_mutex);
				idle_buf_pool[i]=(u8*)new_buf_head;
				NPLIB_DBG("hx_free_buf_list idle_buf_pool[%d]\n",i);   
				pthread_mutex_unlock(&buf_pool_mutex);
				break;
		   	}
		 }
	}
	else if(idle_buf_list_bak.count == MAX_LIST_NUM)
    {
       for(int i=0;i<MAX_POOL_NUM;i++)
		{
		   if(idle_buf_pool[i]==NULL)
		   	{
				pthread_mutex_lock(&buf_pool_mutex);
				idle_buf_pool[i]=(u8*)idle_buf_list_bak.head;
				idle_buf_list_bak.head=NULL;
				idle_buf_list_bak.count=0;
				NPLIB_DBG("hx_free_buf idle_buf_pool[%d]\n",i);   
				pthread_mutex_unlock(&buf_pool_mutex);
				break;
		   	}
		 }
      
    }
  return SUCCESS;
}

void np_pkt_print(u8 *pkt,int len)
{
	int i=0;

	printf("-----------------------***NP PACKET***-----------------------\n");
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
	printf("-----------------------***NP PACKET***-----------------------\n\n");
}


#if 0
int main()
{
   hx_buf_pool_init();
   struct buf_node *tmp_head=NULL;

   struct buf_list daq_buf_list;
   daq_buf_list=hx_buf_list_get();//取一组
   if(daq_buf_list.head==NULL) NPLIB_DBG("daq get buf fail \n");


   struct buf_list daq_buf_list1;
   daq_buf_list1=hx_buf_list_get();//取一组
   if(daq_buf_list1.head==NULL) NPLIB_DBG("111111daq get buf fail \n");
   
   #if 1

	//实验步骤：先全部取走，后再全部归还
	u8 *mt;
	mt=hx_malloc_metedata_buf(&daq_buf_list);//取一个
	NPLIB_DBG("mt :%p %d\n",mt,daq_buf_list.count);

	u8 *mt1;
	mt1=hx_malloc_metedata_buf(&daq_buf_list);//再取一个
	NPLIB_DBG("mt1 :%p %d\n",mt1,daq_buf_list.count);

	u8 *mt2;
	mt2=hx_malloc_metedata_buf(&daq_buf_list);//再取一个
	NPLIB_DBG("mt2 :%p %d\n",mt2,daq_buf_list.count);


	for(int i=0;i<MAX_POOL_NUM;i++)
		{
			 if(idle_buf_pool[i]!=NULL)
			 {
			   NPLIB_DBG("idle_buf_pool[%d]!=NULL\n",i);
			 }
		}

	struct msg_node *msg;
	msg=(struct msg_node *)((u8*)mt-MSG_NODE_LEN-PAD_BUF_LEN);
	if(hx_free_buf(&daq_buf_list,msg)==ERR)
		{
		   NPLIB_DBG("post_buf_addr is fail \n");
		}
    
	struct msg_node *msg1;
	msg1=(struct msg_node *)((u8*)mt1-MSG_NODE_LEN-PAD_BUF_LEN);
	if(hx_free_buf(&daq_buf_list,msg1)==ERR)
		{
		   NPLIB_DBG("post_buf_addr is fail \n");
		}
	#if 0
	struct msg_node *msg2;
	
	msg2=(struct msg_node *)((u8*)mt2-MSG_NODE_LEN-PAD_BUF_LEN);
	if(hx_free_buf(&daq_buf_list,msg2)==ERR)
		{
		   NPLIB_DBG("post_buf_addr is fail \n");
		}
    #endif
	tmp_head=daq_buf_list.head;
	while(tmp_head!=NULL)
		{
	  NPLIB_DBG("daq_buf_list  %p  %p\n",tmp_head,tmp_head->next); 
	  tmp_head=tmp_head->next;	  
		}
	
  #endif

  #if 1

	//实验步骤：先全部取走，后再全部归还
	u8 *m1t;
	m1t=hx_malloc_metedata_buf(&daq_buf_list1);//取一个
	NPLIB_DBG("m1t :%p %d\n",m1t,daq_buf_list1.count);

	u8 *m1t1;
	m1t1=hx_malloc_metedata_buf(&daq_buf_list1);//再取一个
	NPLIB_DBG("m1t1 :%p %d\n",m1t1,daq_buf_list1.count);

	u8 *m1t2;
	m1t2=hx_malloc_metedata_buf(&daq_buf_list1);//再取一个
	NPLIB_DBG("mt2 :%p %d\n",m1t2,daq_buf_list1.count);


	for(int i=0;i<MAX_POOL_NUM;i++)
		{
			 if(idle_buf_pool[i]!=NULL)
			 {
			   NPLIB_DBG("idle_buf_pool[%d]!=NULL\n",i);
			 }
		}

	struct msg_node *m1sg;
	m1sg=(struct msg_node *)((u8*)m1t-MSG_NODE_LEN-PAD_BUF_LEN);
	if(hx_free_buf(&daq_buf_list1,m1sg)==ERR)
		{
		   NPLIB_DBG("post_buf_addr is fail \n");
		}
    
	struct msg_node *m1sg1;
	m1sg1=(struct msg_node *)((u8*)m1t1-MSG_NODE_LEN-PAD_BUF_LEN);
	if(hx_free_buf(&daq_buf_list1,m1sg1)==ERR)
		{
		   NPLIB_DBG("post_buf_addr is fail \n");
		}
	#if 0
	struct msg_node *m1sg2;
	
	m1sg2=(struct msg_node *)((u8*)m1t2-MSG_NODE_LEN-PAD_BUF_LEN);
	if(hx_free_buf(&daq_buf_list1,m1sg2)==ERR)
		{
		   NPLIB_DBG("post_buf_addr is fail \n");
		}
    #endif
	tmp_head=daq_buf_list1.head;
	while(tmp_head!=NULL)
		{
	  NPLIB_DBG("daq_buf_list1  %p  %p\n",tmp_head,tmp_head->next); 
	  tmp_head=tmp_head->next;	  
		}
	
  #endif
   NPLIB_DBG("111111111111111111111111111\n");

   hx_free_buf_list(&daq_buf_list);
   tmp_head=(struct buf_node *)idle_buf_pool[0];
	while(tmp_head!=NULL)
		{
	  NPLIB_DBG("idle_buf_pool  %p  %p\n",tmp_head,tmp_head->next);
	  tmp_head=tmp_head->next;
		}
   NPLIB_DBG("idle_buf_list_bak:%p %d\n",idle_buf_list_bak.head,idle_buf_list_bak.count);

   
   NPLIB_DBG("2222222222222222222\n");
   
   hx_free_buf_list(&daq_buf_list1);
   NPLIB_DBG("idle_buf_list_bak:%p %d\n",idle_buf_list_bak.head,idle_buf_list_bak.count);

   hx_buf_pool_destroy();


   
   return 0;
 }
#endif

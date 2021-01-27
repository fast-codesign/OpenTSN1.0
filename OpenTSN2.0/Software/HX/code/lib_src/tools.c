/** *************************************************************************
 *  @file       main.c
 *  @brief	    NP平台主线程
 *  @date		2020/06/05  星期四
 *  @author		psz
 *  @version	0.1.0
 ****************************************************************************/
#include "../include/tools.h"


 //文本最多1024行
#define MAX_LINES 1024
 
 //文本每行最大256字节
#define LINE_LEN  256
 
#define LINE(x)   file.lines[x].line
#define LINE_CNT  file.line_cnt
 
 //读写文本相关结构体
 struct one_line {
	 char line[LINE_LEN];
	 int char_cnt;
 };
 
 //读写文本相关结构体
 struct file_content {
	 struct one_line lines[MAX_LINES];
	 int line_cnt;
 };


 static void riprt(char *str)
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
 
  int get_cfgx_file(const char *filpath, const char *nam, char *val)
  {
	  FILE *fd = NULL;
	  struct file_content file;
	  char *saveptr1;
	  char *saveptr2;
	  char *pstr = NULL;
	  int i = 0;
	  int ret = -1;
  
	  if ( (NULL == filpath) || (NULL == nam) || (NULL == val))
		  return ret;
		  
	  fd = fopen(filpath, "r");
	  if (fd == NULL)
		  return ret;
	  memset(&file, 0, sizeof(file));
		  
		  //read file stream to memory
	  while (fgets(LINE(LINE_CNT), LINE_LEN, fd) != NULL)
		  LINE_CNT++;
  
		  //compare and put out the value
	  for (i = 0; i < LINE_CNT; i++)
	  {
		  if (LINE(i)[0] == '#')
			  continue;
				  
		  if ((pstr = strtok_r(LINE(i), "=", &saveptr1)) != NULL)
		  {
			  if (!strcmp(pstr, nam))
			  {
				  pstr = strtok_r(NULL, "=", &saveptr1);
				  strcpy(val, pstr);
				  riprt(val);
				  ret = 0;
				  break;
			  }
		  }
				  
		  if ((pstr = strtok_r(LINE(i), " ", &saveptr2)) != NULL)
		  {
			  if (!strcmp(pstr, nam))
			  {
				  pstr = strtok_r(NULL, " ", &saveptr2);
				  strcpy(val, pstr);
				  riprt(val);
				  ret = 0;
				  break;
			  }
		  }
	  }
	  
	  fclose(fd);
	  return ret;
  }





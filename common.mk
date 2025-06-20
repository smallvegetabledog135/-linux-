﻿
#.PHONY:all clean 

ifeq ($(DEBUG),true)
#-g是生成调试信息。GNU调试器可以利用该信息
CC = g++ -std=c++11 -g 
VERSION = debug
else
CC = g++ -std=c++11
VERSION = release
endif

#CC = gcc

# $(wildcard *.c)表示扫描当前目录下所有.c文件
#SRCS = nginx.c ngx_conf.c
SRCS = $(wildcard *.cpp)

#OBJS = nginx.o ngx_conf.o  这么一个一个增加.o太麻烦，下行换一种写法：把字符串中的.c替换为.o
OBJS = $(SRCS:.cpp=.o)

#把字符串中的.c替换为.d
#DEPS = nginx.d ngx_conf.d
DEPS = $(SRCS:.cpp=.d)

#可以指定BIN文件的位置,addprefix是增加前缀函数
#BIN = /mnt/hgfs/linux/nginx
BIN := $(addprefix $(BUILD_ROOT)/,$(BIN))

#定义存放ojb文件的目录，目录统一到一个位置才方便后续链接，不然整到各个子目录去，不好链接
#注意下边这个字符串，末尾不要有空格等否则会语法错误 
LINK_OBJ_DIR = $(BUILD_ROOT)/app/link_obj
DEP_DIR = $(BUILD_ROOT)/app/dep

#-p是递归创建目录，没有就创建，有就不需要创建了
$(shell mkdir -p $(LINK_OBJ_DIR))
$(shell mkdir -p $(DEP_DIR))

#把目标文件生成到上述目标文件目录去，利用函数addprefix增加个前缀
#处理后形如 /mnt/hgfs/linux/nginx/app/link_obj/ngx_signal2.o /mnt/hgfs/linux/nginx/app/link_obj/ngx_signal.o
# := 在解析阶段直接赋值常量字符串【立即展开】，而 = 在运行阶段，实际使用变量时再进行求值【延迟展开】
# /mnt/hgfs/linux/nginx/app/link_obj/nginx.o   /mnt/hgfs/linux/nginx/app/link_obj/ngx_conf.o 
OBJS := $(addprefix $(LINK_OBJ_DIR)/,$(OBJS))
DEPS := $(addprefix $(DEP_DIR)/,$(DEPS))

#找到目录中的所有.o文件（编译出来的）
LINK_OBJ = $(wildcard $(LINK_OBJ_DIR)/*.o)
#因为构建依赖关系时app目录下这个.o文件还没构建出来，所以LINK_OBJ是缺少这个.o的，我们 要把这个.o文件加进来
LINK_OBJ += $(OBJS)

#-------------------------------------------------------------------------------------------------------
#make找第一个目标开始执行[每个目标[就是我们要生成的东西]，其实都是定义一种依赖关系]，目标的格式为：
#目标：目标依赖【可以省略】
#	要执行的命令【可以省略】
#如下这行会是开始执行的入口，执行就找到依赖项$(BIN)去执行了，同时，这里也依赖了$(DEPS)，这样就会生成很多.d文件了
all:$(DEPS) $(OBJS) $(BIN)

#这里是诸多.d文件被包含进来，每个.d文件里都记录着一个.o文件所依赖哪些.c和.h文件。内容诸如 nginx.o: nginx.c ngx_func.h
#有必要先判断这些文件是否存在，不然make可能会报一些.d文件找不到
ifneq ("$(wildcard $(DEPS))","")   #如果不为空,$(wildcard)是函数【获取匹配模式文件名】，这里 用于比较是否为""
include $(DEPS)  
endif

#----------------------------------------------------------------1begin------------------  
#$(BIN):$(OBJS)  
$(BIN):$(LINK_OBJ)  
	@echo "------------------------build $(VERSION) mode--------------------------------!!!"  

#一些变量：$@：目标，     $^：所有目标依赖  
# gcc -o 是生成可执行文件  
	$(CC) -o $@ $^ -lpthread -lmysqlclient   # 在这里添加 -lmysqlclient  

#----------------------------------------------------------------1end-------------------

#----------------------------------------------------------------2begin-----------------  
#%.o:%.c  
$(LINK_OBJ_DIR)/%.o:%.cxx  
# gcc -c是生成.o目标文件   -I可以指定头文件的路径  
#如下不排除有其他字符串，所以从其中专门把.c过滤出来   
#$(CC) -o $@ -c $^  
	$(CC) -I$(INCLUDE_PATH) -I/usr/include/mysql -o $@ -c $(filter %.cpp,$^)  
#----------------------------------------------------------------2end-------------------


#----------------------------------------------------------------3begin-----------------
#.d文件中的内容可能形如：nginx.o: nginx.c ngx_func.h
#%.d:%.c
$(DEP_DIR)/%.d:%.cpp
#gcc -MM $^ > $@
#gcc -MM $^ | sed 's,\(.*\)\.o[ :]*,$(LINK_OBJ_DIR)/\1.o:,g' > $@
#echo 中 -n表示后续追加不换行
	echo -n $(LINK_OBJ_DIR)/ > $@
#	gcc -MM $^ | sed 's/^/$(LINK_OBJ_DIR)&/g' > $@
#  >>表示追加
#	gcc -I$(INCLUDE_PATH) -MM $^ >> $@
	$(CC) -I$(INCLUDE_PATH) -MM $^ >> $@

#上行处理后，.d文件中内容应该就如：/mnt/hgfs/linux/nginx/app/link_obj/nginx.o: nginx.c ngx_func.h ../signal/ngx_signal.h

#----------------------------------------------------------------4begin-----------------



#----------------------------------------------------------------nbegin-----------------
#clean:			
#rm 的-f参数是不提示强制删除
#可能gcc会产生.gch这个优化编译速度文件
#	rm -f $(BIN) $(OBJS) $(DEPS) *.gch
#----------------------------------------------------------------nend------------------






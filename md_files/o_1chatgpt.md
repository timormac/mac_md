## 搭建流程

搭建图文链接

https://doc.muluhub.com/docs/gpt4turbo

香草云服务器官网

https://www.xiangcaoyun.com/?i5ad099

香草云账号

18018981934

lpc19950419

云服务器

ip地址 ：   198.44.176.203

账号：root     Lpc121995



## 服务器相关

40G硬盘 1核  1G 内存    3ms 带宽  

目前用了3g

 

## 操作

服务器操作

管理，添加规则 新增 tcp协议 2023端口 



获取中转key   [https://openai-hk.com/](https://openai-hk.com/?i=1088)

hk-zxnwv71000008135023a70e621025f861141e9eba234a17d



连接服务器

下载docker

curl -fsSL https://get.docker.com -o get-docker.sh

安装docker

bash get-docker.sh

启动docker

systemctl start docker

查看docker状态

systemctl status docker



docker安装gpt

2023应该是2023转发3000的gpt端口吧，后续用2023访问服务器

页面访问密码为121995 -e CODE=121995设置的

```shell
docker run  --name chatgpt-next-web   -d -p 2023:3000 \
-e OPENAI_API_KEY=hk-zxnwv71000008135023a70e621025f861141e9eba234a17d \
-e CODE=121995 \
-e HIDE_USER_API_KEY=1 \
-e BASE_URL=https://twapi.openai-hk.com   yidadaa/chatgpt-next-web
```

查看运行情况

docker ps

访问gpt页面  198.44.176.203:2023

优先访问3.5-turbo 不行再 4-1106-preview


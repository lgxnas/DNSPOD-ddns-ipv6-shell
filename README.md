# DNSPod-ddns

利用dnspod域名服务商API制作的DDNS工具，在公网IPV6变化时把新的IPV6地址更新到域名解析上。

# 开始使用

```
mv ipv6.conf.example ipv6.conf
```

## 修改配置文件`ipv6.conf`

1. domain : 你的域名 `example.com`

2. subdomain : 需要更新的二级域名 `test.example.com` 填写 `test`

3. id : 用于鉴权的 API id

4. token : 用于鉴权的 API Token

   **获取服务商ID和Token**

   生成方法详见：https://support.dnspod.cn/Kb/showarticle/tsid/227/ ,完整的 API Token 是由 ID,Token 组合而成的，用英文的逗号分割。

5. FTPUSH : 是否使用方糖推送信息 1--使用 0--不使用(默认)

6. ftsckey : 方糖SCKEY

   **Server酱-微信推送 API , 感谢Server酱提供的服务**

   官方地址：sc.ftqq.com , [登入网站](http://sc.ftqq.com/?c=github&a=login)，就能获得一个[SCKEY](http://sc.ftqq.com/?c=code)

## 加入计划任务

```
crontab -e
#示例:
#*/30 * * * * /bin/bash /path/to/ddnspod.sh >> /home/usrname/xxx.log 2>&1
```

# 工作方式 

1. 获取本机IPV6地址

2. 获取已绑定域名的IPV6地址

   在ddnspod.sh同级文件夹生成record.json，用于保存https://dnsapi.cn/Record.List 获取的记录列表信息。**以后工作时取得record_id和已绑定ipv6地址不再重复通过api取得**。

   响应代码：

   - 共通返回
   - -7 企业账号的域名需要升级才能设置
   - -8 代理名下用户的域名需要升级才能设置
   - 6 域名ID错误
   - 7 记录开始的偏移无效
   - 8 共要获取的记录的数量无效
   - 9 不是域名所有者
   - 10 没有记录

3. 本机IPV6地址变更时更新dnspod解析地址

4. 保存更新记录

   在ddnspod.sh同级文件夹生成update.log，保存更新的地址和时间信息

5. FTPUSH设置值为1时，通过方糖微信推送API推送变更记录到微信

# 更新

- 2019/11/13 初始化
- 2021/02/01 按官方要求加入UserAgent
- 2022/07/08 加入获取本机ipv6失败判断，发生错误退出更新

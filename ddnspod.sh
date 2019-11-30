#!/bin/bash

LIST_URL="https://dnsapi.cn/Record.List"
#https://dnsapi.cn/Record.Ddns 更新动态DNS记录为ipv4 
MODIFY_URL="https://dnsapi.cn/Record.Modify"

#shell脚本所在路径
WORKDIRECTORY=$(dirname $(readlink -f "$0"))"/"
#查询记录得到的Json，用于获取record_id
JSONFILE=${WORKDIRECTORY}"record.json"
#修改记录的IP和时间log文件
LOGFILE=${WORKDIRECTORY}"update.log"
#配置文件
CONFFILE=${WORKDIRECTORY}"ipv6.conf"

. ${CONFFILE}

#查询记录列表的基本参数
ARG="login_token="${ID}','${TOKEN}"&format=json&domain="${DOMAIN}"&sub_domain="${SUBDOMAIN}

#get localipv6 and remoteipv6
LOCALIPV6=$(ip route get 240c::6666|awk -F'src ' '{print $2}'|cut -d' ' -f1)
if [ ! -f "$JSONFILE" ]
then
	LIST_JSON=$(curl -s -X POST ${LIST_URL} -d ${ARG})
	if [ $(echo ${LIST_JSON}|grep successful|wc -l) -eq 0 ];then
		echo -e "获取DnsPod记录信息失败\t$(date +%F' '%T)\n"
		exit
	fi
	echo ${LIST_JSON} > ${JSONFILE}
	REMOTEIPV6=$(echo ${LIST_JSON#*\"value\"}|cut -d'"' -f2)
else
	LIST_JSON=$(cat ${JSONFILE})
	REMOTEIPV6=$(echo ${LIST_JSON#*\"value\"}|cut -d'"' -f2)
fi
#修改记录补充参数
#取得record_id
RECORD_ID=$(echo ${LIST_JSON#*\"records\"\:\[\{\"id\"}|cut -d'"' -f2)
MODIFYARG=${ARG}"&record_id="${RECORD_ID}"&record_type=AAAA&record_line_id=0&value="${LOCALIPV6}

#update
function ftPush(){
	TEXT="${SUBDOMAIN}.${DOMAIN} ipv6更新"
	DESP=${LOCALIPV6}"  
		subdomain: ${SUBDOMAIN}.${DOMAIN}  
		date: $(date +%F' '%T)  
		record_id: ${RECORD_ID}"
	FT_JSON=$(curl -s -F"text=$TEXT" \
			-F"desp=$DESP" \
			"http://sc.ftqq.com/${FTSCKEY}.send")
	if [ $(echo ${FT_JSON}|grep success|wc -l) -eq 0 ];then
		echo -e "$(date +%F' '%T)\n${FT_JSON}\n"
		exit
	fi	
}
#echo -e "local ip:"$LOCALIPV6"\nremote ip:"$REMOTEIPV6
if [ "$LOCALIPV6" == "$REMOTEIPV6" ];then
	#echo "ip was not changed , exiting..."
	exit
else
	MODIFY_JSON=$(curl -s -X POST ${MODIFY_URL} -d ${MODIFYARG})
	if [ $(echo ${MODIFY_JSON}|grep success|wc -l) -eq 0 ];then
		echo -e "$(date +%F' '%T)\tMODIFY\n"
		exit
	fi	
	echo ${MODIFY_JSON}|sed 's/record":{"id":/records":[{"id":"/g'|sed 's/,"name/","name/g' > ${JSONFILE}
	echo -e "${LOCALIPV6}\t$(date +%F' '%T)\n" >> ${LOGFILE}	
	if [ $FTPUSH -eq 1 ];then
		ftPush
	fi
fi

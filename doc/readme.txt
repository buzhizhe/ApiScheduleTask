
使用install.bat 安装和卸载服务
setup.bat 是使用sc命令执行的，由于不好设置工作路径，默认从system32目录读数据写数据，因此废弃掉此方法。

bin 下要放发布的realse软件包
bin\crontab.txt 配置接口任务，配置方式请参考：《cron设置说明.docx》
bin\log 是计划任务日志，job_[index]_yyyMMdd 格式



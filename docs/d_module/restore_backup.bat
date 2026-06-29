@echo off
echo 拖拽备份sql文件到此窗口，回车恢复
set /p sqlFile=
mysql -uadmin_db -padm123456 < %sqlFile%
echo 数据恢复完成！
pause
@echo off
set "today=%date:~0,4%%date:~5,2%%date:~8,2%"
set saveDir=D:\score_back
md %saveDir% 2>nul
mysqldump -uadmin_db -padm123456 --databases score_system --single-transaction --default-character-set=utf8mb4 > %saveDir%\score_%today%.sql
echo 备份完成，路径：%saveDir%\score_%today%.sql
pause
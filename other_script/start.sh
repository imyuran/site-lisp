#!/bin/bash

xmodmap -e "keycode 94 = grave asciitilde " 
#cd ~/bin/xptray/ && ./xptray.py &
#virtualbox --startvm xp  &
#fcitx
rm ~/.emacs.d/.emacs.desktop.lock
#emacs& 
firefox&
#gnome-terminal --maximize &
if [ "X"$(/sbin/ifconfig  | grep eth0 | wc -l)  ==   "X1" ] ; then
    ~/work/sshmount.sh &
fi
goldendict &

setxkbmap -option terminate:ctrl_alt_bksp 


#/opt/cxoffice/bin/wine --bottle "腾讯通RTX客户端_2010" --check --wait-children --start "C:/users/Public/Desktop/腾讯通RTX.lnk"  &
#VBoxManage setextradata global GUI/Customizations noMenuBar,noStatusBar
#halt: shutduwn -h now
#--------------- 设置 xp 自动登录 -------------
#根键位置：
#HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
#修改内容：
#在右边的窗口中的新建字符串"AutoAdminlogon"，并把他们的键值为"1"，把“DefaultUserName”的值设置为用户名，并且另外新建一个字符串值“DefaultPassword”，并设其值为用户的密码。:142857@xcwen

#flash 开启本地存储
#echo "LocalStorageLimit = 1" > /etc/adobe/mms.cfg 


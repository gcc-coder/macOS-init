#################################################################
#!/bin/bash
# Initialization tool for macOS.sh
# Author by Ricklong
# CreateDate 2019-11-07
# Function Description：
#	1. Add to a domain - contoso.com for macOS
#	2. Set hostname
#	3. Add account to group of administrators
#	4. Install all of the PKG installer, Number.pkg Pages.pkg etc..
#	5. Copy the common files to the Shared Directory
#
# Modified Date: 2019-12-25 to 12-30
#	完善相关功能；
#	整合加域和不加域；  
#################################################################

domain="contoso.com"
add_domain_user=addtest
login_user=$(whoami)
dir="/Volumes/Install-macOS/app/"
app_dir="/Applications/"
admin="admin"

# 获取登录密码
dscl . -read /groups/admin  GroupMembership |grep $login_user &> NULL
if [ $? -eq 0 ];
then
	echo "---------------------------------"
	echo "当前登录账户为 $login_user "
	echo "---------------------------------"
	
	while true;
	do
		# 后期加一个判断当前用户是否为空密码		

		read -p "请输入$login_user 的登录密码：" -s pwd_1
		echo
		read -p "请再次输入密码：" -s pwd_2
		echo
		
		if [[ $pwd_1 != $pwd_2 ]];then
			echo
			echo "++++++++++++++++++++++++++++"
			echo "两次密码不一致，请重新输入！"
			echo "++++++++++++++++++++++++++++"
		else
			break;
		fi
	done

	dscl . -list /Users |egrep ^"$admin" &> /dev/null
	if [ $? -eq 0 ];then
		echo $pwd_2 |sudo -S dscl . -create /Users/$admin  IsHidden 1 &> /dev/null
		if [ $? -eq 0 ];then
			echo "---------------------------------"
			echo "已隐藏admin账户"
			echo "---------------------------------"
		else
			echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo "隐藏admin账户失败，请确认$login_user 登陆密码输入是否正确！"
			echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			exit 1;
		fi
	else
		echo
		echo "++++++++++++++++++++++++++++"
		echo "$admin 不存在"
		echo "++++++++++++++++++++++++++++"
	fi
else
	echo "$login_user 没有本机管理员权限，请切换admin登录"
	exit 1；
fi	

# 获取用户工号
while true; 
do
	read -p "请输入7位用户工号：" NUM
	if [ ${#NUM} == 7 ];
	then
		read -r -p "请确认工号是否为 $NUM [y/n]：" input
		case $input in
		[yY][eE][sS]|[yY])		
			break
			;;

		[nN][oO]|[nN])
			echo "++++++++++++++++++++++++++++"
			echo "请重新输入！"
			echo "++++++++++++++++++++++++++++"
			;;

		*)	
			echo "++++++++++++++++++++++++++++"
			echo "非法字符，请输入 y/n ！"
			echo "++++++++++++++++++++++++++++"
			;;
		esac
	else
		echo "++++++++++++++++++++++++++++"
		echo "工号需要7位，请确认后再次输入！"
		echo "++++++++++++++++++++++++++++"
	fi
done

# 根据工号设置电脑名称
NAME=EBJ$NUM
echo $pwd_2 | sudo -S scutil --set HostName $NAME &> /dev/null
echo $pwd_2 | sudo -S scutil --set LocalHostName $NAME &> /dev/null
echo $pwd_2 | sudo -S scutil --set ComputerName $NAME &> /dev/null
echo "---------------------------------"
echo "已将计算机名设置为$(hostname)"
echo "---------------------------------"

# 电脑是否加域
while true;
do
	id $add_domain_user &> /dev/null
    if [ $? -eq 0 ];then
        echo "++++++++++++++++++++++++++++"
        echo "该电脑已加域!"
        echo "++++++++++++++++++++++++++++"		
		break;
    else
		read -r -p "此电脑是否要加入$domain 域？ [y/n]：" input
		echo "---------------------------------"

		case $input in
		[yY][eE][sS]|[yY])			
			while true;
			do
				read -p "请输入加域账户$add_domain_user 的密码：" -s d_pwd_1
				echo
				read -p "请再次输入密码：" -s d_pwd_2
				echo		
				if [[ $d_pwd_1 != $d_pwd_2 ]];
				then
					echo
					echo "++++++++++++++++++++++++++++"
					echo "两次密码不一致，请重新输入！"
					echo "++++++++++++++++++++++++++++"
				else
					#JoinAD
					echo "---------------------------------"
					echo "本机正在加域，请稍等! "
					echo "---------------------------------"
					echo $pwd_2 | sudo -S dsconfigad -u $add_domain_user -p $d_pwd_2  -domain $domain
					echo $pwd_2 | sudo -S dsconfigad -mobile enable &> /dev/null  
					echo $pwd_2 | sudo -S dsconfigad -mobileconfirm disable &> /dev/null
					break;
				fi
			done
			
			# 判断是否加域成功及添加用户至admin组
			id $add_domain_user &> /dev/null
			if [ $? -eq 0 ];then
				echo "---------------------------------"
				echo "加域成功!"	
				echo "---------------------------------"
				while true;
				do
					read -p "本机已加域，请输入该机所属员工的AD账户：" USER
					read -r -p "请确认账户是否为 $USER ? [y/n]：" input
					
					case $input in
					[yY][eE][sS]|[yY])										
						echo $pwd_2 | sudo -S dscl . -read /groups/admin  GroupMembership |grep $USER &> /dev/null
						if [ $? -eq 0 ];
						then
							echo "---------------------------------"
							echo "$USER 已拥有本机管理员权限"
							echo "---------------------------------"
						else
							echo "---------------------------------"
							echo $pwd_2 | sudo -S dscl . -append /Groups/admin GroupMembership $USER  && echo "已将$USER 添加至本机管理员组"
							echo "---------------------------------"
						fi	
						
						break
						;;

					[nN][oO]|[nN])
						echo "++++++++++++++++++++++++++++"
						echo "请重新输入！"  
						echo "++++++++++++++++++++++++++++"
						;;

					*)
						echo "++++++++++++++++++++++++++++"
						echo "非法字符，请输入 y/n ！"
						echo "++++++++++++++++++++++++++++"
						;;
					esac
				done
				
			else
				echo "++++++++++++++++++++++++++++++++++++++++++++"
				echo "加域失败！请检查配置信息后，再次运行该脚本！";
				echo "++++++++++++++++++++++++++++++++++++++++++++"
				exit 111;
			fi	
			break
			;;
		[nN][oO]|[nN])			
			while true;
			do
				read -p "本机不加域哦！请设置本机所属员工的本地登录账户：" USER
				echo "---------------------------------"
				read -r -p "请确认账户是否为 $USER ? [y/n]：" input
				echo "---------------------------------"

				case $input in
				[yY][eE][sS]|[yY])
					# 创建账户并将其添加至admin组
					dscl . -list /Users |egrep ^"$USER" &> /dev/null
					if [ $? -eq 0 ];then
						echo "++++++++++++++++++++++++++++"
						echo "$USER 已是本机账户！"
						echo "++++++++++++++++++++++++++++"
					else
						echo $pwd_2 | sudo -S dscl . -create /Users/$USER 
						echo $pwd_2 | sudo -S dscl . -create /Users/$USER UserShell /bin/zsh
						echo $pwd_2 | sudo -S dscl . -create /Users/$USER RealName $USER
						echo $pwd_2 | sudo -S dscl . -create /Users/$USER UniqueID 506  && echo "已创建用户账户$USER" || echo "创建用户账户$USER 失败！"
						echo $pwd_2 | sudo -S dscl . -create /Users/$USER PrimaryGroupID 1001
						echo $pwd_2 | sudo -S dscl . -create /Users/$USER NFSHomeDirectory /Users/$USER
						echo $pwd_2 | sudo -S dscl . -passwd /Users/$USER ''
						echo $pwd_2 | sudo -S dscl . -read /groups/admin  GroupMembership |grep $USER &> /dev/null					
						echo "---------------------------------"
						echo $pwd_2 | sudo -S dscl . -append /Groups/admin GroupMembership $USER  && echo "已将$USER 添加至本机管理员组"
						echo "---------------------------------"						
					fi
					break
					;;

				[nN][oO]|[nN])
					echo "++++++++++++++++++++++++++++"
					echo "请重新输入！"  
					echo "++++++++++++++++++++++++++++"
					;;

				*)
					echo "++++++++++++++++++++++++++++"
					echo "非法字符，请输入 y/n ！"
					echo "++++++++++++++++++++++++++++"
					;;
				esac
			done

			break;
			;;

		*)
			echo "++++++++++++++++++++++++++++"
			echo "非法字符，请输入 y/n ！"
			echo "++++++++++++++++++++++++++++"
			;;
		esac
	fi
done

# 将办公文件拷贝到共享目录
/bin/cp -rf $dir"手册"/ /Users/Shared
echo "------------------------------------------------"
echo "已将员工入职说明文件,拷贝到共享目录/Users/Shared"
echo "------------------------------------------------"


echo
echo
echo "##############开始安装应用程序，时间较久##############"
numbers=Numbers
keynote=Keynote
pages=Pages

tv=TeamViewer
foxmail=Foxmail
reader="Adobe Reader"
wxwork="企业微信"
wechat=WeChat
chrome="Google Chrome"
qq=QQ

# 静默安装pkg程序
for app in $numbers $keynote $pages $guanjia $tv;
do
	a=$(ls $app_dir$app.app &> /dev/null)
	if [ $? -ne 0 ];then
		for PKG in $dir$app.pkg; do
			echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"			
			echo "开始安装$app ,请稍后"
			echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			echo $pwd_2 | sudo -S installer -allowUntrusted -pkg $PKG -target / &> /dev/null
			if [ $? -eq 0 ];then
				echo "---------------------------------"				
				echo "$app 安装完成"
				echo "---------------------------------"
			else
				echo "++++++++++++++++++++++++++++"
				echo "$app 安装失败，请手动安装！"
				echo "++++++++++++++++++++++++++++"
			fi
		done

    else
		echo "++++++++++++++++++++++++++++"
		echo "本机已安装$app"
		echo "++++++++++++++++++++++++++++"

    fi 

done

# 移动免安装app到/Applications目录
for app in $wxwork $wechat $qq $foxmail;do
	ls $app_dir$app.app &> /dev/null 
	if [ $? -ne 0 ];then
		for move_app in $dir$app.app;do
		 	cp -R $move_app $app_dir
			if [ $? -eq 0 ];then
				echo "---------------------------------"
                echo "$app 安装完成"
				echo "---------------------------------"
            else
				echo "++++++++++++++++++++++++++++"
				echo "$app 安装失败，请手动安装！"
				echo "++++++++++++++++++++++++++++"
			fi

		done
   	else
		echo "++++++++++++++++++++++++++++"
		echo "本机已安装$app"
		echo "++++++++++++++++++++++++++++"

   fi 
done

# 移动chrome.app到/Applications目录
ls "$app_dir$chrome.app" &> /dev/null
if [ $? -ne 0 ];then
	cp -R "$dir$chrome.app" $app_dir
	if [ $? -eq 0 ];then
		echo "---------------------------------"
		echo "$chrome 安装完成"
		echo "---------------------------------"
	else
		echo "+++++++++++++++++++++++++++++++"
		echo "$chrome 安装失败，请手动安装！"
		echo "+++++++++++++++++++++++++++++++"
	fi
else
	echo "++++++++++++++++++++++++++++"
	echo "本机已安装$chrome"
	echo "++++++++++++++++++++++++++++"
fi

open $dir$tq

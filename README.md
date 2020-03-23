## macOS-init
用于初始化mac系统
- 语言环境：bash shell
- 脚本名称：macOS_init.sh


## 功能描述：
1. Add to a domain - contoso.com for macOS
2. Set hostname
3. Add account to group of administrators
4. Install all of the PKG installer, Number.pkg Pages.pkg etc..
5. Copy the common files to the Shared Directory

## 本地账户说明
1. 本地账户需要自定义名称
2. 本地账户密码为空


## 加域说明
1. 须将domain修改为自己所在公司的域名
2. 须指定具有加域权限的账户，add_domain_user

## 其他说明
1. 将脚本文件和要安装的程序包等都存放到U盘 
2. U盘名称为Install_macOS
3. 要安装的软件存放在Install_macOS/app目录下
4. 入职说明文件存放在【Install_macOS/app/手册】目录下
5. 入职说明文件拷贝至mac的/Users/Shared目录下

## 运行方法
1. 插入U盘
2. 打开终端输入sh /Volumes/Install-macOS/macOS_init.sh（可直接将其拖入终端）并回车
3. 根据提示输入相关信息 

## 命令方式安装系统
/Volumes/Install-macOS/Install\ macOS\ Catalina.app/Contents/Resources/startosinstall --eraseinstall --newvolumename macos --agreetolicense

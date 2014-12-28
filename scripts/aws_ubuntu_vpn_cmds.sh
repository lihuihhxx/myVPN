#! /bin/sh

USER="vpn"
PASSWD="test123"

sudo apt-get install -y pptpd
sudo iptables --flush POSTROUTING --table nat
sudo iptables --flush FORWARD
sudo iptables -L

# remore log for pptpd
sudo sed -i 's/^logwtmp/#logwtmp/g' /etc/pptpd.conf

# set vpn client ip range
echo "localip 192.168.240.1" | sudo tee -a /etc/pptpd.conf
echo "remoteip 192.168.240.2-100" | sudo tee -a /etc/pptpd.conf

# enable ip forward
sudo sed -i 's/^#net.ipv4.ip_forward/net.ipv4.ip_forward = 1\n#/g' /etc/sysctl.conf
sudo sysctl -p

# get dns of vm and set for pptpd
echo "ms-dns `sudo cat /etc/resolv.conf  | grep nameserver | head -n 1 | awk '{print $2}'`"  | sudo tee -a /etc/ppp/pptpd-options
echo "ms-dns 8.8.8.8" | sudo tee -a /etc/ppp/pptpd-options

# set VPN user, passwd info
echo "$USER pptpd $PASSWD *" | sudo tee -a /etc/ppp/chap-secrets

# add iptables rule
sudo iptables -t nat -A POSTROUTING -s 192.168.240.0/24 -j SNAT --to-source `sudo ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk 'NR==1 { print $1}'`
sudo iptables -A FORWARD -p tcp --syn -s 192.168.240.0/24 -j TCPMSS --set-mss 1356
sudo iptables -L

# start pptpd
sudo service pptpd restart

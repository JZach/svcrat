sudo \cp -f ./svcrat.sh /usr/local/bin
sudo \cp -f ./svcrat.conf /etc/svcrat
sudo \cp -f ./svcrat.service /etc/systemd/system/svcrat.service
sudo systemctl daemon-reload
#sudo systemctl start svcrat.service
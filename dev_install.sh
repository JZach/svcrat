set -x
sudo adduser svcrat --gecos "" --no-create-home --disabled-login

#working-directory
sudo mkdir -p /usr/local/bin/svcrat
#configuration
sudo mkdir -p /usr/local/etc/svcrat

sudo cp -f ./svcrat.sh /usr/local/bin/svcrat
sudo cp -f ./svcrat.conf.example /usr/local/etc/svcrat
sudo cp -n /usr/local/etc/svcrat/svcrat.conf.example /usr/local/etc/svcrat/svcrat.conf

sudo chown -R svcrat:svcrat /usr/local/bin/svcrat/
sudo chmod +x /usr/local/bin/svcrat/svcrat.sh

sudo cp -f ./svcrat.service /etc/systemd/system/svcrat.service
#sudo systemctl enable svcrat.service
sudo systemctl start svcrat.service
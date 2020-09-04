#!/bin/bash
# If command line argument is init, setup startup service

basename=`basename "$0"`
file_loc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/$basename"

home="/usr/local/bin/"

function startup_service {
 
 # Get current file path
 # Create a file that calls this one and runs it as a bash script
 usbip_fh="/usr/local/bin/usbip_host_startup_run.sh"
 eval "sudo echo \"#!/bin/bash\" > $usbip_fh "
 eval "sudo echo \"eval \\\"sudo bash $file_loc >  ${home}startup_service.txt 2>&1 \\\"\" >> $usbip_fh"
 eval "sudo chmod +x $usbip_fh"
 # Create a service that runs previous file at startup (runs this file at startup)
 service_fh="/etc/systemd/system/startup_usbip_host.service"
 eval "sudo echo \"[Unit]\" > $service_fh "
 eval "sudo echo \"Description=USB/IP host startup\" >> $service_fh "
 eval "sudo echo \"[Service]\" >> $service_fh "
 eval "sudo echo \"Type=simple \" >> $service_fh " 
 eval "sudo echo \"ExecStart=/usr/bin/usbipd \" >> $service_fh " 
 eval "sudo echo \"ExecStartPost=$usbip_fh \" >> $service_fh "
 eval "sudo echo \"RemainAfterExit=yes\" >> $service_fh "
 eval "sudo echo \"[Install]\" >>  $service_fh"
 eval "sudo echo \"WantedBy=multi-user.target\" >>  $service_fh"

 # Enable the service 
 eval "sudo systemctl disable startup_usbip_host"
 eval "sleep 2"

 eval "sudo systemctl daemon-reload"
 eval "sudo systemctl enable startup_usbip_host"

}

if [[ ${1} == "init" ]]; then
 
 eval "echo \"Creating startup services.\""
 eval "echo "
 startup_service

fi

# Update driver
eval "sudo modprobe usbip-host"
sleep 1

# Get a list of available USB devices
dev_list_txt=$(eval "sudo usbip list -l > ${home}dev_list.txt 2>&1")
# Bind all Intel FPGA development kit USB devices

echo ""
echo "Begin binding Intel FPGA development kits..."
echo ""

while IFS= read -r line 
do
 line_arr=($line) 
 if [[ ${line_arr[1]} == "busid"  && ${line_arr[3]} == *"09fb"* ]]; then 
  eval "sudo usbip unbind -b ${line_arr[2]}"
  eval "sudo usbip bind -b ${line_arr[2]}"
 fi
done <  ${home}dev_list.txt

echo ""
echo "Done binding!"
echo ""

ipv4_pw=$( eval "ip addr show | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'" )
echo "Local IPv4 address: $ipv4_pw"

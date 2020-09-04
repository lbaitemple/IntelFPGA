#!/bin/bash

usbip_host_bus_id=""
JTAG_pw=""
usbip_host_ipv4=""
qp_install_directory=""
usbip_host_discovered=0

basename=`basename "$0"`
file_loc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/$basename"

home="/usr/local/bin/"
param_fh="${home}jtag_server_params.sh"

function get_jtag_server_params {

 # If some parameters exist, use them as suggestions
 if [[ -e "${param_fh}" ]]; then
   source "${param_fh}"
 fi

 eval "echo "

 read -p "Enter the Quartus Programmer intall directory: " -i $qp_install_directory -e qp_install_directory
 eval "echo \"qp_install_directory=\\\"$qp_install_directory\\\"\" > ${home}jtag_server_params.sh "

 read -p "Enter the USB/IP server host's local IP: " -i $usbip_host_ipv4 -e usbip_host_ipv4
 eval "echo \"usbip_host_ipv4=\\\"$usbip_host_ipv4\\\"\" >> ${home}jtag_server_params.sh"

 read -p "Enter the bus ID this machine will attach to: " -i $usbip_host_bus_id -e usbip_host_bus_id
 eval "echo \"usbip_host_bus_id=\\\"$usbip_host_bus_id\\\" \" >> ${home}jtag_server_params.sh "

 read -p "Enter the remote client JTAG server password: " -i $JTAG_pw -e  JTAG_pw
 eval "echo \"JTAG_pw=\\\"$JTAG_pw\\\"\" >> ${home}jtag_server_params.sh "
 eval "echo "

}

function create_startup_service {

 eval "echo \"Creating startup services.\""
 eval "echo "

 eval "sudo echo \"#!/bin/bash\" > /usr/local/bin/JTAGd_run.sh "
 eval "sudo echo \"eval \\\"sudo bash ${file_loc} predaemon > ${home}startup_service_log.txt 2>&1 \\\"\" >> /usr/local/bin/JTAGd_run.sh "
 eval "sudo echo \"eval \\\"sudo bash ${file_loc} daemonstart >> ${home}startup_service_log.txt 2>&1 \\\"\" >> /usr/local/bin/JTAGd_run.sh "
 eval "sudo chmod +x /usr/local/bin/JTAGd_run.sh"

 eval "sudo echo \"#!/bin/bash\" > /usr/local/bin/JTAG_startup_run.sh "
 eval "sudo echo \"eval \\\"sudo bash ${file_loc} jtagserverstart >> ${home}startup_service_log.txt 2>&1 \\\"\" >> /usr/local/bin/JTAG_startup_run.sh "
 eval "sudo chmod +x /usr/local/bin/JTAG_startup_run.sh"

 eval "sudo echo \"[Unit]\" > /etc/systemd/system/startup_JTAG_server.service "
 eval "sudo echo \"Description=JTAG server startup\" >> /etc/systemd/system/startup_JTAG_server.service "
 eval "sudo echo \"Wants=startup_JTAGd.service\" >> /etc/systemd/system/startup_JTAG_server.service "
 eval "sudo echo \"After=syslog.target network.target startup_JTAGd.service\" >> /etc/systemd/system/startup_JTAG_server.service "
 eval "sudo echo \"[Service]\" >> /etc/systemd/system/startup_JTAG_server.service "
 eval "sudo echo \"Type=simple\" >> /etc/systemd/system/startup_JTAG_server.service "
 eval "sudo echo \"TimeoutSec=900\" >> /etc/systemd/system/startup_JTAG_server.service "
 eval "sudo echo \"ExecStart=/usr/local/bin/JTAG_startup_run.sh\" >> /etc/systemd/system/startup_JTAG_server.service "
 eval "sudo echo \"[Install]\" >> /etc/systemd/system/startup_JTAG_server.service "
 eval "sudo echo \"WantedBy=multi-user.target\" >> /etc/systemd/system/startup_JTAG_server.service "

 eval "sudo echo \"[Unit]\" > /etc/systemd/system/startup_JTAGd.service "
 eval "sudo echo \"Description=JTAGd startup\" >> /etc/systemd/system/startup_JTAGd.service"
 eval "sudo echo \"[Service]\" >> /etc/systemd/system/startup_JTAGd.service "
 eval "sudo echo \"Type=simple\" >> /etc/systemd/system/startup_JTAGd.service "
 eval "sudo echo \"ExecStart=/usr/local/bin/JTAGd_run.sh\" >> /etc/systemd/system/startup_JTAGd.service "
 eval "sudo echo \"RemainAfterExit=yes\" >> /etc/systemd/system/startup_JTAGd.service "
 eval "sudo echo \"[Install]\" >> /etc/systemd/system/startup_JTAGd.service "
 eval "sudo echo \"WantedBy=multi-user.target\" >> /etc/systemd/system/startup_JTAGd.service "

 eval "sudo systemctl disable startup_JTAG_server"
 eval "sudo systemctl disable startup_JTAGd"
 eval "sleep 1"
 
 eval "sudo systemctl daemon-reload"
 eval "sleep 1"

 eval "sudo systemctl enable startup_JTAG_server" 
 eval "sudo systemctl enable startup_JTAGd"
 eval "echo "

}

function create_shutdown_service {
 
 eval "echo \"Creating shutdown service.\""
 eval "echo "

 eval "sudo echo \"#!/bin/bash\" > /usr/local/bin/JTAG_shutdown_run.sh "
 eval "sudo echo \"eval \\\"sudo bash ${file_loc} shutdown > ${home}shutdown_service_log.txt 2>&1 \\\"\" >> /usr/local/bin/JTAG_shutdown_run.sh "
 eval "sudo chmod +x /usr/local/bin/JTAG_shutdown_run.sh"

 eval "sudo echo \"Description=JTAG server shutdown\" >> /etc/systemd/system/shutdown_JTAG_server.service "
 eval "sudo echo \"[Service]\" >> /etc/systemd/system/shutdown_JTAG_server.service "
 eval "sudo echo \"Type=oneshot\" >> /etc/systemd/system/shutdown_JTAG_server.service"
 eval "sudo echo \"RemainAfterExit=true\" >> /etc/systemd/system/shutdown_JTAG_server.service "
 eval "sudo echo \"ExecStop=/usr/local/bin/JTAG_shutdown_run.sh\" >> /etc/systemd/system/shutdown_JTAG_server.service "
 eval "sudo echo \"[Install]\" >> /etc/systemd/system/shutdown_JTAG_server.service "
 eval "sudo echo \"WantedBy=multi-user.target\" >> /etc/systemd/system/shutdown_JTAG_server.service " 

 eval "sudo systemctl disable shutdown_JTAG_server"
 eval "sleep 1"

 eval "sudo systemctl daemon-reload"
 eval "sleep 1"

 eval "sudo systemctl enable shutdown_JTAG_server --now"
 eval "echo "

}

function init {

 get_jtag_server_params
 create_startup_service
 create_shutdown_service

}

function get_and_check_params {

 while true; do

  # If it is inform user, else initialize
  if [[ -e "${param_fh}" ]]; then
   eval "echo \"Found params file.\""
   eval "echo "

  else
   eval "echo \"JTAG server params file missing!\""
   eval "echo "
   init
  fi

  source ${param_fh}

  # Check that all necessary variables are defined
  if { [ -z ${usbip_host_bus_id+x} ] || [ -z ${JTAG_pw+x} ] || [ -z ${usbip_host_ipv4+x} ] || [ -z ${qp_install_directory+x} ]; }; then

   eval "echo \"Couldn't find setup variables!\""
   eval "echo "
   init

  else

   eval "echo \"All setup variables defined.\""
   eval "echo "
   break

  fi

 done
}

function usbip_host_wait {

 num_attempts=0
 while true; do

  eval "sudo ping -q -c 1 $usbip_host_ipv4 > /dev/null"

  if [ $? -eq 0 ]; then

   eval "echo \"USB/IP host online.\""
   eval "echo "
   break

  else

   eval "echo \"USB/IP host not online, trying again...\""
   sleep 1

  fi

  if [ $num_attempts -gt 10 ]; then

   eval "echo \"USB/IP host could not connect. Exiting.\""
   exit 1

  fi
 
  num_attempts=$((num_attempts + 1))

 done
}

function bind_usbip_host_bus {

 lsusb > ${home}usb_list.txt
 num_usb_dev=$(wc -l < ${home}usb_list.txt)
 eval "sudo rm -rf ${home}startup_log.txt"
 eval "echo \"Removing devices\" > ${home}startup_log.txt"

 for (( i=0; i<=${num_usb_dev}; i++ ))
 do

   eval "sudo usbip detach -p ${i} >> ${home}startup_log.txt 2>&1"

 done
 
 # Get number of USB devices before attaching to USBIP server bus
 lsusb > ${home}usb_list.txt
 num_usb_dev_pre_attach=$(wc -l < ${home}usb_list.txt) 
 num_usb_dev_pre_attach=$(( num_usb_dev_pre_attach + 0 ))

 # Attach to the usb device on the bus_id bus of the machine at usbip_ipv4
 eval "sudo usbip attach -r ${usbip_host_ipv4} -b ${usbip_host_bus_id}"

 sleep 2

 # Get number of USB devices after attaching to USBIP server bus
 lsusb > ${home}usb_list.txt
 num_usb_dev_post_attach=$(wc -l < ${home}usb_list.txt)
 num_usb_dev_post_attach=$(( num_usb_dev_post_attach + 0 ))

 sudo rm -rf ${home}usb_list.txt

 # Check that device was actually added
 if (( "$num_usb_dev_pre_attach" >= "$num_usb_dev_post_attach" )) ; then
  eval "echo \"Error attaching. Target bus ${usbip_host_bus_id} at USB/IP host on ${usbip_host_ipv4} not attached.\""
  eval "echo "
  exit 1
 else
  eval "echo \"Target bus ${usbip_host_bus_id} at USB/IP host on ${usbip_host_ipv4} successfully attached.\""
  eval "echo "
 fi

 eval "sleep 5"
}

function clear_jtag_daemon {

 # Stop all jtagconfig and jtag daemon processes
 eval "sudo killall -9 jtagd >> ${home}startup_log.txt 2>&1"
 eval "sleep 2"

 # Double check
 eval "sudo killall -9 jtagd >> ${home}startup_log.txt 2>&1"
  eval "sleep 2"

 # Remove all data from previous jtagd
 eval "sudo rm -rf /etc/jtagd/ >> ${home}startup_log.txt 2>&1"

 # Create new directory for jtagd and update priveledges
 eval "sudo mkdir /etc/jtagd/ >> ${home}startup_log.txt 2>&1"
 eval "sudo chmod +rwx /etc/jtagd/ >> ${home}startup_log.txt 2>&1"
 eval "sleep 2"

}

function start_jtag_daemon {

  eval "sudo ${qp_install_directory}qprogrammer/bin/jtagd"
  eval "echo \"JTAG daemon started.\""
  eval "echo "
  eval "sleep 2"

}

function start_jtag_server {

 # Start JTAG server with JTAG_pw password
 eval "sudo ${qp_install_directory}qprogrammer/bin/jtagconfig --enableremote $JTAG_pw >> ${home}startup_log.txt 2>&1"
 eval "sleep 2"
 eval "echo \"JTAG server connected devices:\""
 eval "sudo ${qp_install_directory}qprogrammer/bin/jtagconfig"

}

function startup {

 # Source the jtag server startup parameters
 get_and_check_params 

 # Update kernel to include usbip client modules
 eval "sudo modprobe vhci-hcd"

 # Wait for successful ping to usbip host
 usbip_host_wait

 # Bind this JTAG server to a usbip host USB bus
 bind_usbip_host_bus

 # Start the jtag server daemon
 clear_jtag_daemon

 # Start the jtag server daemon
 start_jtag_daemon

 # Start the JTAG server
 start_jtag_server

}

# Check if user provided an argument, evaluate provided option
if ! [ -z ${1+x} ]; then

 if [ "${1}" = "init" ]; then

  init
  startup
  exit 0

 fi

 if [ "${1}" = "shutdown" ]; then

  lsusb > ${home}usb_list.txt
  num_usb_dev=$(wc -l <${home}usb_list.txt)

  for (( i=0; i<=${num_usb_dev}; i++ ))
  do

   eval "sudo usbip detach -p ${i}"

  done

   eval "sudo rm -rf ${home}usb_list.txt"
   eval "sudo rm -rf ${home}startup_service.log"

  exit 0

 fi

 if [ "${1}" = "predaemon" ]; then
 
  clear_jtag_daemon
  exit 0

 fi

 if [ "${1}" = "daemonstart" ]; then

  get_and_check_params 
  start_jtag_daemon
  exit 0 

 fi

 if [ "${1}" = "jtagserverstart" ]; then

  # Source the jtag server startup parameters
  get_and_check_params 

  # Update kernel to include usbip client modules
  eval "sudo modprobe vhci-hcd"

  # Wait for successful ping to usbip host
  usbip_host_wait

  # Bind this JTAG server to a usbip host USB bus
  bind_usbip_host_bus

  # Start the JTAG server
  start_jtag_server

 fi

fi

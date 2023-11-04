# neo
[NEORV32](https://github.com/stnolting/neorv32) on [ULX3S](https://www.crowdsupply.com/radiona/ulx3s)
<br><br>

## Prerequisites
Install the [RISC-V toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain.git) and [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build#installation) tools.
<br>
The script below is for linux installation only.
<br>
```bash
# For RISC-V
mkdir risc-v
cd risc-v
git clone https://github.com/riscv/riscv-gnu-toolchain
sudo mkdir /opt/riscv
./configure --prefix=/opt/riscv
make linux
export PATH="$PATH:/opt/riscv/bin" >> ~/.bashrc
source ~/.bashrc

# For OSS-CAD-SUITE
curl -L https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2023-10-01/oss-cad-suite-linux-riscv64-20231001.tgz > oss-cad-suite
sudo tar xzf oss-cad-suite-linux-riscv64-20231001.tgz -C /opt
rm -rf oss-cad-suite
export PATH="$PATH:/opt/oss-cad-suite/bin" >> ~/.bashrc
source ~/.bashrc
```

## Build Design
Plug the USB1 of ULX3S Board to your PC, then run:
```bash
git clone --recursive https://github.com/fedy0/neo.git && cd neo
make flash
```
This will perform the systhesis, place and route, constrain mapping, bitstream generation and upload

## Test
To test, run the following command. Press any key to invoke the bootloader menu, then select 'u' to upload and 'e' to execute
```bash
cd ./neorv32/sw/example/hello_world
make exe
sudo sh ../../image_gen/uart_upload.sh /dev/ttyUSB0 neorv32_exe.bin
sudo apt install gtkterm
gtkterm --port /dev/ttyUSB0 --speed 19200
```
![Build](./images/helloworld.png)

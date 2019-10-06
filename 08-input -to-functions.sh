sample(){
echo "inide the function"
echo ipaddress = $1
echo username = $2
echo password = $3
echo no of arguments = $#
echo all aguments passed = $@
}
echo "inside the main script"
echo ipaddress = $1
echo username = $2
echo password = $3
echo no of arguments = $#
echo all aguments passed = $@
sample   132.16.12.122 anil anil123
sample   0.00.0.0 sirisha sirisha123
sample   1.1.1.1 ashreya shreya123
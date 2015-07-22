# network_test
Simple test of ping, bandwidth, and packet drop

On computer A, run:
`ruby server.rb -n LocationA`

On computer B, run:
`ruby net_test.rb -n LocationB -r <ip address of remote machine> -i <number of minutes between runs> -d <number of hours to run>`


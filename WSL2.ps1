PARA CONECTAR WSL2

$Listener = [System.Net.Sockets.TcpListener]80;
$Listener.Start();
$Listener.AcceptSocket();


telnet $(cat /etc/resolv.conf | grep nameserver | cut -d' ' -f2) 80

$myIp = (ubuntu.exe run "cat /etc/resolv.conf | grep nameserver | cut -d' ' -f2")
New-NetFirewallRule -DisplayName "WSL" -Direction Inbound  -LocalAddress $myIp -Action Allow


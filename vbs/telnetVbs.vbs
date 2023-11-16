Dim vHosts(100)
vHosts(0) = "192.168.56.10"
vHosts(1) = "192.168.56.11"
vHosts(2) = "192.168.56.12"

For Each strHost In vHosts
 If strHost = "" Then Exit For

 ' Make sure we are disconnected before attempting a connection
 If crt.Session.Connected Then crt.Session.Disconnect

 ' Connect to the next host
 crt.Session.Connect "/SSH2 /L admin /PASSWORD admin " & strHost

 ' Do work on the remote machine.
 ' The Disconnect() action is done at the top of the loop (in the event
 ' that the tab in which this script is launched already has an
 ' active connection).
Next
servers = {"tomcat":"up","websphere":"down","ngnix":"running","apache":"running"}

for server,server_status in servers.items() :
    print(f"Server Name : {server} and Status : {server_status}")
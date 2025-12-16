from ping3 import ping, verbose_ping

def ping_server(host):
    try:
        response_time = ping(host)
        if response_time is not None:
            print(f"Ping to {host} successful! Response time: {response_time:.2f} ms")
        else:
            print(f"Ping to {host} failed!")
    except Exception as e:
        print(f"Error pinging server: {e}")

# Test the function
for i in range(100000):
    ping_server("google.com")

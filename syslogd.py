import socket, logging
from logging.handlers import RotatingFileHandler

# 1. Setup the Rotating File Logger
LOG_FILE = "/var/log/pylogd.log"
MAX_BYTES = 4 * 1024 * 1024  # 4 MB per file
BACKUP_COUNT = 2             # Keep pylogd.log, pylogd.log.1, pylogd.log.2

logger = logging.getLogger("UDP_log")
logger.setLevel(logging.INFO)

# Create the rotating handler
handler = RotatingFileHandler(LOG_FILE, maxBytes=MAX_BYTES, backupCount=BACKUP_COUNT)
formatter = logging.Formatter('%(asctime)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
handler.setFormatter(formatter)
logger.addHandler(handler)

# 2. Setup UDP Socket
UDP_IP = "0.0.0.0"
UDP_PORT = 10514

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))

print(f"Python log daemon running on PORT {UDP_PORT} and saving to {LOG_FILE} with auto-rotation 4Mb.")

# 3. Main Loop
while True:
    data, addr = sock.recvfrom(4096)
    log_message = data.decode('utf-8', errors='ignore').strip()
    
    # Write cleanly to the rotating log file
    logger.info(f"[{addr[0]}] {log_message}")
    print(f"Source: {addr[0]} | Log: {log_message.strip()}")
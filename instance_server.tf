resource "aws_instance" "websocket_server" {
  ami           = "ami-0a01fe64fe4ac6319"  # Ubuntu AMI ID
  instance_type = "t3.micro"
  key_name      = "your-key-name"

  user_data = <<-EOF
              #!/bin/bash
              # Update packages and install MariaDB
              sudo apt update
              sudo apt install -y mariadb-server python3-pip

              # Start MariaDB
              sudo systemctl start mariadb
              sudo mysql -e "CREATE DATABASE binance_data;"
              sudo mysql -e "CREATE USER 'binance_user'@'localhost' IDENTIFIED BY 'password';"
              sudo mysql -e "GRANT ALL PRIVILEGES ON binance_data.* TO 'binance_user'@'localhost';"
              sudo mysql -e "FLUSH PRIVILEGES;"

              # Install Python dependencies
              pip3 install websocket-client mysql-connector-python

              # Create Python script for WebSocket and MariaDB logging
              cat << 'SCRIPT' > /home/ubuntu/binance_ws.py
              import websocket
              import mysql.connector

              # Connect to MariaDB
              db = mysql.connector.connect(
                  host="localhost",
                  user="binance_user",
                  password="password",
                  database="binance_data"
              )
              cursor = db.cursor()

              # WebSocket callback
              def on_message(ws, message):
                  print(message)
                  cursor.execute("INSERT INTO trades (data) VALUES (%s)", (message,))
                  db.commit()

              ws = websocket.WebSocketApp("wss://stream.binance.com:9443/ws/btcusdt@trade", on_message=on_message)
              ws.run_forever()

              SCRIPT

              # Create database table for storing WebSocket data
              sudo mysql -u binance_user -ppassword -D binance_data -e "CREATE TABLE trades (id INT AUTO_INCREMENT PRIMARY KEY, data TEXT);"

              # Run WebSocket script
              nohup python3 /home/ubuntu/binance_ws.py &
              EOF

  tags = {
    Name = "websocket-maria-server"
  }
}

resource "aws_security_group" "websocket_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

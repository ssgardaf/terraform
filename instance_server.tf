resource "aws_security_group" "websocket_sg" {
  name        = "websocket-sg"
  description = "Allow inbound traffic for WebSocket"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




resource "aws_instance" "websocket_server" {
  ami           = "ami-01abb191f665c021f"  # Ubuntu AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.websocket_sg.id]


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


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

  tags = {
    Name = "websocket-sg"
    Environment = "Production"  # 예시 태그 추가
  }
}

# Elastic IP 생성
resource "aws_eip" "websocket_eip" {
  domain = "vpc"
}




resource "aws_instance" "websocket_server" {
  ami           = "ami-01abb191f665c021f"  # Ubuntu AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets[0].id
  vpc_security_group_ids = [aws_security_group.websocket_sg.id]
  key_name               = "eks-ec2-key"  # SSH 키 이름 추가
  root_block_device {
    volume_size = 500  # EBS 볼륨 크기 (GB)
    volume_type = "gp2"  # 일반적인 SSD
  }
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
              import json
              import mysql.connector

              # Connect to MariaDB
              db = mysql.connector.connect(
                  host="localhost",
                  user="binance_user",
                  password="password",
                  database="binance_data"
              )
              cursor = db.cursor()

              def on_message(ws, message):
                  data = json.loads(message)
                  if 's' in data and data['s'] == 'LTCUSDT':  # LTCUSDT 데이터만 처리
                      print(data)
                      cursor.execute("INSERT INTO trades (data) VALUES (%s)", (json.dumps(data),))
                      db.commit()

              def on_open(ws):
                  subscribe_message = {
                      "method": "SUBSCRIBE",
                      "params": ["ltcusdt@trade"],  # 라이트코인 거래 데이터
                      "id": 1
                  }
                  ws.send(json.dumps(subscribe_message))

              ws = websocket.WebSocketApp("wss://stream.binance.com:9443/ws", on_message=on_message, on_open=on_open)
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

# Elastic IP를 EC2 인스턴스에 연결
resource "aws_eip_association" "websocket_associate" {
  instance_id = aws_instance.websocket_server.id
  allocation_id = aws_eip.websocket_eip.id
}
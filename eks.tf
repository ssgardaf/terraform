module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                    = "streaming-cluster"
  cluster_version                 = "1.27"  # 최신 Kubernetes 버전
  cluster_endpoint_private_access = false  # 클러스터 엔드포인트에 대한 Private Access를 비활성화합니다.
  cluster_endpoint_public_access  = true  # Public Access를 활성화합니다.

  # 최신 Kubernetes Add-ons
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private_subnets[*].id  # 프라이빗 서브넷 사용

  cloudwatch_log_group_retention_in_days = 7  # 로그 보존 기간 7일

eks_managed_node_groups = {
  kafka_ec2_group = {
    desired_capacity = 3
    max_capacity     = 5
    min_capacity     = 1
    instance_type    = "t3.medium"
    key_name         = "eks-ec2-key"  # SSH 액세스용 키
  }
}
# desired_capacity: 클러스터에 유지할 기본 EC2 인스턴스의 수입니다.
# max_capacity: 클러스터에서 자동으로 확장할 수 있는 최대 인스턴스 수입니다.
# min_capacity: 클러스터에서 항상 유지해야 할 최소 인스턴스 수입니다.
# instance_type: EC2 인스턴스의 유형을 지정합니다 (t3.medium).
# key_name: EC2 인스턴스에 SSH 접속할 때 사용할 SSH 키를 지정합니다.


}

resource "aws_security_group" "eks_sg" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "streaming-eks-sg"
  }
}

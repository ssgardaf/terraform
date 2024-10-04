module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                    = "streaming-cluster"
  cluster_version                 = "1.31"  # 최신 Kubernetes 버전
  cluster_endpoint_private_access = false    # 클러스터 엔드포인트에 대한 Private Access를 비활성화합니다.
  cluster_endpoint_public_access  = true     # Public Access를 활성화합니다.

  # 최신 Kubernetes Add-ons
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }

    aws-ebs-csi-driver = {}  # EBS CSI 드라이버를 추가
  }

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private_subnets[*].id  # 프라이빗 서브넷 사용

  cloudwatch_log_group_retention_in_days = 7  # 로그 보존 기간 7일

  eks_managed_node_groups = {
    ec2_group = {
      desired_capacity = 6
      max_capacity     = 8
      min_capacity     = 3
      instance_type    = "m5.large"
      key_name         = "eks-ec2-key"  # SSH 액세스용 키 
    }
  }
}
 

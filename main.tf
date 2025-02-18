terraform {
  backend "s3" {
    bucket         = "terraform-backend-fiapeats-2" # Substitua pelo nome do bucket
    key            = "state/fiapeats-ms-pedido-db/terraform.tfstate"         # Caminho do estado no bucket
    region         = "us-east-1"                       # Região do bucket
    encrypt        = true                              # Criptografia no bucket
  }
}

provider "aws" {
    region = "us-east-1"  # Substitua pela região desejada
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_docdb_cluster" "mongodb_cluster" {
  cluster_identifier      = "fiapeats-mspedido-mongodb"
  engine                 = "docdb"
  master_username        = "sa"
  master_password        = "fiapeats-mspedido-db-pass"
  backup_retention_period = 1
  skip_final_snapshot    = true

  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]  # 🚀 Associação explícita
}

resource "aws_docdb_cluster_instance" "mongodb_instance" {
  count               = 1
  cluster_identifier = aws_docdb_cluster.mongodb_cluster.id
  instance_class     = "db.t3.medium"
}

resource "aws_security_group" "mongodb_sg" {
  vpc_id = data.aws_vpc.default.id
  name   = "mongodb-security-group"

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Abra apenas para redes seguras
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_docdb_cluster.mongodb_cluster]  # 🚀 Garante que o Cluster é removido primeiro
}
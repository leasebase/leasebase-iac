################################################################################
# RDS Aurora Serverless v2 Module - LeaseBase v2
################################################################################

resource "aws_security_group" "db" {
  name_prefix = "${var.name_prefix}-db-"
  description = "Security group for Aurora database"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "PostgreSQL from service"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db"
  subnet_ids = var.subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

################################################################################
# Secrets Manager - DB Credentials
################################################################################

resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}|:,.<>?"
}

resource "aws_secretsmanager_secret" "db" {
  name       = "${var.name_prefix}-db-credentials"
  kms_key_id = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    dbname   = var.db_name
    host     = aws_rds_cluster.main.endpoint
    port     = aws_rds_cluster.main.port
    engine   = "postgres"
  })
}

################################################################################
# Aurora Cluster
################################################################################

resource "aws_rds_cluster" "main" {
  cluster_identifier = "${var.name_prefix}-db"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = var.engine_version
  database_name      = var.db_name
  master_username    = var.master_username
  master_password    = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  storage_encrypted = true
  kms_key_id        = var.kms_key_id

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-db-final"

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db"
  })
}

resource "aws_rds_cluster_instance" "main" {
  count = var.instance_count

  identifier         = "${var.name_prefix}-db-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  publicly_accessible = false

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-${count.index}"
  })
}

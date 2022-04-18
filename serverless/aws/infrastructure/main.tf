provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_public_cidr_block
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-subnet-public"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-internet-gateway"
  }
}

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.project}-route-table-public"
  }
}

resource "aws_route_table_association" "route_table_association_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_eip" "eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "${var.project}-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet_public.id

  tags = {
    Name = "${var.project}-nat-gateway"
  }
}

resource "aws_subnet" "subnet_private" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_private_cidr_block
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-subnet-private"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "main"
  subnet_ids = [aws_subnet.subnet_public.id, aws_subnet.subnet_private.id]

  tags = {
    Name = "${var.project}-db-subnet-group"
  }
}

resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.project}-route-table-private"
  }
}

resource "aws_route_table_association" "route_table_association_private" {
  subnet_id      = aws_subnet.subnet_private.id
  route_table_id = aws_route_table.route_table_private.id
}

resource "aws_default_network_acl" "default_network_acl" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id
  subnet_ids             = [aws_subnet.subnet_public.id, aws_subnet.subnet_private.id]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project}-default-network-acl"
  }
}

resource "aws_security_group" "lambdafunction_security_group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["127.0.0.1/32"]
  }

  tags = {
    Name = "${var.project}-lambdafunction-security-group"
  }
}

resource "aws_security_group" "rds_security_group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    security_groups = [aws_security_group.lambdafunction_security_group.id]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks  = ["69.157.38.115/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["127.0.0.1/32"]
  }

  tags = {
    Name = "${var.project}-rds-security-group"
  }
}


#######################################################################
######################### DATABASE CREATION ###########################
#######################################################################

# Creates a Postgres RDS instance.
resource "aws_db_instance" "postgres-db" {
  identifier              = "${var.project}-database"
  storage_type            = "gp2" # General Purpose (Optional)
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "13.4" # (Optional)
  instance_class          = "db.m6g.large"
  # The name of the DB subnet group. The DB instance will be created in the vpc associated with the db subnet group.
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_security_group.id] #[var.security_group_id]
  name                    = "${var.project}DB"  # Name of the database.
  username                = var.username
  password                = var.password
  publicly_accessible     = true
  skip_final_snapshot     = true

  tags = {
      Name                = "${var.project} PostgresQL DB Instance"
  } 
}


#######################################################################
######################### LAMBDA LAYER ################################
#######################################################################

data "archive_file" "dependencies" {
  type        = "zip"
  source_dir  = "../dependencies"
  output_path = "zip/dependencies/python.zip"
}

resource "aws_lambda_layer_version" "dependencies_layer" {
  layer_name          = "${var.project}-dependencies"
  filename            = data.archive_file.dependencies.output_path
  source_code_hash    = filebase64sha256(data.archive_file.dependencies.output_path)
  compatible_runtimes = ["python3.8", "python3.9"]
}


#######################################################################
######################### LAMBDA FUNCTIONS ############################
#######################################################################

# Creating ROLE:

data "aws_iam_policy_document" "AWSLambdaTrustPolicy" {
  version         = "2012-10-17"
  statement {
    actions       = ["sts:AssumeRole"]
    effect        = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_role" {
  assume_role_policy = data.aws_iam_policy_document.AWSLambdaTrustPolicy.json
  name               = "${var.project}-iam-role-lambda-trigger"
}

# Attaching polices to ROLE:

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_lambda_basic_execution" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_vpc_access_execution" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_lambda_role" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

provider "archive" {}

# Creating SEARCH lambda function:

data "archive_file" "search" {
  type        = "zip"
  source_dir  = "../routes/search"
  output_path = "zip/search.zip"
}

resource "aws_lambda_function" "search_lambda_function" {
  code_signing_config_arn = ""
  description             = ""
  filename                = data.archive_file.search.output_path
  function_name           = "${var.project}-dev-search"
  role                    = aws_iam_role.iam_role.arn
  handler                 = "dev.lambda_function.lambda_handler"
  runtime                 = "python3.8"
  source_code_hash        = filebase64sha256(data.archive_file.search.output_path)
  timeout                 = 120
  layers                  = [aws_lambda_layer_version.dependencies_layer.arn]
  environment {
    variables = {
      PINECONE_INDEX          = var.pinecone_index
      API_KEY_PINECONE        = var.pinecone_api_key
      ENV_PINECONE            = var.pinecone_env
      HUGGINGFACE_API_TOKEN   = var.huggingface_api_token
      PSQL_CONNECT_STR        = var.psql_connect_str
    }
  }
  vpc_config {
    subnet_ids         = [aws_subnet.subnet_public.id, aws_subnet.subnet_private.id]
    security_group_ids = [aws_security_group.lambdafunction_security_group.id]
  }
}

# Creating SIMILAR lambda function:

data "archive_file" "similar" {
  type        = "zip"
  source_dir  = "../routes/similar"
  output_path = "zip/similar.zip"
}

resource "aws_lambda_function" "similar_lambda_function" {
  code_signing_config_arn = ""
  description             = ""
  filename                = data.archive_file.similar.output_path
  function_name           = "${var.project}-dev-similar"
  role                    = aws_iam_role.iam_role.arn
  handler                 = "dev.lambda_function.lambda_handler"
  runtime                 = "python3.8"
  source_code_hash        = filebase64sha256(data.archive_file.similar.output_path)
  layers                  = [aws_lambda_layer_version.dependencies_layer.arn]
  environment {
    variables = {
      PSQL_CONNECT_STR        = var.psql_connect_str
    }
  }
  vpc_config {
    subnet_ids         = [aws_subnet.subnet_public.id, aws_subnet.subnet_private.id]
    security_group_ids = [aws_security_group.lambdafunction_security_group.id]
  }
}

# Creating SIMILAR_ITEM lambda function:

data "archive_file" "similar_item" {
  type        = "zip"
  source_dir  = "../routes/similar_item"
  output_path = "zip/similar_item.zip"
}

resource "aws_lambda_function" "similar_item_lambda_function" {
  code_signing_config_arn = ""
  description             = ""
  filename                = data.archive_file.similar_item.output_path
  function_name           = "${var.project}-dev-similar-item"
  role                    = aws_iam_role.iam_role.arn
  handler                 = "dev.lambda_function.lambda_handler"
  runtime                 = "python3.8"
  source_code_hash        = filebase64sha256(data.archive_file.similar_item.output_path)
  timeout                 = 120
  layers                  = [aws_lambda_layer_version.dependencies_layer.arn]
  environment {
    variables = {
      PINECONE_INDEX          = var.pinecone_index
      API_KEY_PINECONE        = var.pinecone_api_key
      ENV_PINECONE            = var.pinecone_env
      HUGGINGFACE_API_TOKEN   = var.huggingface_api_token
      PSQL_CONNECT_STR        = var.psql_connect_str
    }
  }
  vpc_config {
    subnet_ids         = [aws_subnet.subnet_public.id, aws_subnet.subnet_private.id]
    security_group_ids = [aws_security_group.lambdafunction_security_group.id]
  }
}

# Creating GEOSEARCH lambda function:

data "archive_file" "geo_search" {
  type        = "zip"
  source_dir  = "../routes/geo_search"
  output_path = "zip/geo_search.zip"
}

resource "aws_lambda_function" "geo_search_lambda_function" {
  code_signing_config_arn = ""
  description             = ""
  filename                = data.archive_file.geo_search.output_path
  function_name           = "${var.project}-dev-geo-search"
  role                    = aws_iam_role.iam_role.arn
  handler                 = "dev.lambda_function.lambda_handler"
  runtime                 = "python3.8"
  source_code_hash        = filebase64sha256(data.archive_file.geo_search.output_path)
  timeout                 = 120
  layers                  = [aws_lambda_layer_version.dependencies_layer.arn]
  environment {
    variables = {
      PINECONE_INDEX          = var.pinecone_index
      API_KEY_PINECONE        = var.pinecone_api_key
      ENV_PINECONE            = var.pinecone_env
      HUGGINGFACE_API_TOKEN   = var.huggingface_api_token
      PSQL_CONNECT_STR        = var.psql_connect_str
    }
  }
  vpc_config {
    subnet_ids         = [aws_subnet.subnet_public.id, aws_subnet.subnet_private.id]
    security_group_ids = [aws_security_group.lambdafunction_security_group.id]
  }
}

# Creating FEEDBACK lambda function:

data "archive_file" "feedback" {
  type        = "zip"
  source_dir  = "../routes/feedback"
  output_path = "zip/feedback.zip"
}

resource "aws_lambda_function" "feedback_lambda_function" {
  code_signing_config_arn = ""
  description             = ""
  filename                = data.archive_file.feedback.output_path
  function_name           = "${var.project}-dev-feedback"
  role                    = aws_iam_role.iam_role.arn
  handler                 = "dev.lambda_function.lambda_handler"
  runtime                 = "python3.8"
  source_code_hash        = filebase64sha256(data.archive_file.feedback.output_path)
  timeout                 = 120
  layers                  = [aws_lambda_layer_version.dependencies_layer.arn]
  environment {
    variables = {
      PSQL_CONNECT_STR        = var.psql_connect_str
    }
  }
  vpc_config {
    subnet_ids         = [aws_subnet.subnet_public.id, aws_subnet.subnet_private.id]
    security_group_ids = [aws_security_group.lambdafunction_security_group.id]
  }
}


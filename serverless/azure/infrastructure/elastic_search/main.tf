terraform {
  required_version = ">= 0.12.29"
  required_providers {
    ec = {
      source = "elastic/ec"
      version = "0.2.1"
    }
  }
}

provider "ec" {
}

data "ec_stack" "latest" {
  version_regex = "latest"
  region = "azure-eastus"
}

resource "ec_deployment" "cords_elasticsearch" {
  name = "cords-elasticsearch"
  deployment_template_id = "azure-io-optimized"
  region = data.ec_stack.latest.region
  version = data.ec_stack.latest.version
  elasticsearch {
    topology {
      id = "hot_content"
      size = "4g"
    }
  }
  kibana {
    topology {
      size = "1g"
    }
  }
}

output "elasticsearch_endpoint" {
  value = ec_deployment.cords_elasticsearch.elasticsearch[0].https_endpoint
}

output "kibana_endpoint" {
  value = ec_deployment.cords_elasticsearch.kibana[0].https_endpoint
}

output "elasticsearch_username" {
  value = ec_deployment.cords_elasticsearch.elasticsearch_username
}

output "elasticsearch_password" {
  value = ec_deployment.cords_elasticsearch.elasticsearch_password
  sensitive = true
}
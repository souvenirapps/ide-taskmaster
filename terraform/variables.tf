variable "project_id" {
  default = "ide-api-318715"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "zone_2" {
  default = "us-central1-c"
}

variable "private_subnet_cidr" {
  default = "10.11.11.0/24"
}

variable "machine_type" {
  default = "e2-standard-2"
}

variable "instance_service_account" {
  default = "ide-worker@ide-api-318715.iam.gserviceaccount.com"
}

variable "min_replica" {
  default = 2
}

variable "max_replica" {
  default = 10
}

variable "cool_down_period" {
  default = 300
}

variable "max_unavailable_fixed" {
  default = 0
}

variable "max_surge_fixed" {
  default = 2
}

variable "ide_tasks_name" {
  default = "projects/ide-api-318715/topics/ide-tasks"
}

variable "ide_tasks_subscription" {
  default = "ide-tasks-subscription"
}

variable "ide_task_results_topic" {
  default = "projects/ide-api-318715/topics/ide-tasks-results"
}

variable "app_env" {
  default = "production"
}

variable "single_instance_max_task" {
  default = 40
}

variable "worker_app_github" {
  default = "souvenirapps/ide-taskmaster"
}

variable "single_instance_concurrent_task" {
  default = 20
}

variable "worker_output_path" {
  default = "/tmp/box"
}

variable "docker_pull_workers" {
  description = "Set of docker pull commands to pull all the worker containers."
}

variable "container_registry_path" {
  description = "GCR Base URL"
}

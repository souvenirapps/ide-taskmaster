data "google_compute_image" "vm_image" {
  family  = "centos-7"
  project = "centos-cloud"
}

resource "google_compute_instance_template" "ide_worker" {
  name_prefix = "ide-worker-template"
  description = "This template is used to create IDE worker instances which handles execution of user-submitted code."

  tags = ["ide-worker"]

  labels = {
    service = "ide"
    class   = "worker"
  }

  machine_type = var.machine_type

  disk {
    source_image = data.google_compute_image.vm_image.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = 16
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.name
    access_config {}
  }

  service_account {
    email = var.instance_service_account
    // The best practice is to set the full "cloud-platform" access scope on the instance,
    // then securely limit your service account's access by granting IAM roles to the service account.
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata_startup_script = <<SCRIPT
  #!/bin/bash

  sudo yum -y update
  sudo yum install epel-release
  sudo yum -y update
  sudo yum -y install supervisor
  sudo systemctl start supervisord
  sudo systemctl enable supervisord

  sudo curl https://get.docker.com | sh
  sudo systemctl start docker

  sudo curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
  sudo yum clean all
  sudo yum makecache fast
  sudo yum -y install gcc-c++ make
  sudo yum -y install nodejs

  sudo yum -y install git

  sudo groupadd docker
  sudo adduser node
  sudo usermod -aG docker node

  sudo mkdir -p /home/node/taskmaster
  git clone git@github.com:${var.worker_app_github} /home/node/taskmaster
  cd /home/node/taskmaster
  npm install
  npm run build
  rm -rf node_modules/*
  npm install --only=production

  mkdir -p ${var.worker_output_path}
  chmod 777 -R ${var.worker_output_path}

  iptables -A INPUT -d 172.17.0.0/16 -i docker0 -j DROP

  docker network create --internal --subnet 10.1.1.0/24 --opt com.docker.network.bridge.enable_icc=false no-internet

  ${var.docker_pull_workers}

  tee -a /etc/supervisord.conf > /dev/null <<CONF
[program:taskmaster]
command=node /home/node/taskmaster/dist/taskmaster.js
autostart=true
autorestart=true
environment=
    WORKER_BOX_DIR=${var.worker_output_path}/jobs
    PUBSUB_IDE_TOPIC=${var.ide_tasks_name},
    PUBSUB_IDE_SUBSCRIPTION=${var.ide_tasks_subscription},
    PUBSUB_IDE_OUTPUT_TOPIC=${var.ide_task_results_topic},
    MAX_CONCURRENT_JOBS=${var.single_instance_concurrent_task},
    NODE_ENV=${var.app_env}
stderr_logfile=/var/log/taskmaster.err.log
stdout_logfile=/var/log/taskmaster.out.log
user=node
CONF

  supervisorctl reread
  supervisorctl update
  SCRIPT
}

resource "google_compute_instance_group_manager" "ide_taskmaster_2_instance_group" {
  provider = "google-beta"
  project  = var.project_id

  name               = "ide-taskmaster-2"
  base_instance_name = "ide-taskmaster-2"
  zone               = var.zone_2
  target_size        = var.min_replica

  version {
    name              = "ide-taskmaster-2"
    instance_template = google_compute_instance_template.ide_worker.self_link
  }

  update_policy {
    minimal_action        = "REPLACE"
    type                  = "PROACTIVE"
    min_ready_sec         = var.cool_down_period
    max_unavailable_fixed = var.max_unavailable_fixed
    max_surge_fixed       = var.max_surge_fixed
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.ide_taskmaster.self_link
    initial_delay_sec = var.cool_down_period + 10
  }
}

resource "google_compute_autoscaler" "ide_taskmaster_2_autoscaler" {
  provider = "google-beta"
  project  = var.project_id

  name   = "ide-taskmaster-2-autoscaler"
  zone   = var.zone_2
  target = google_compute_instance_group_manager.ide_taskmaster_2_instance_group.self_link

  autoscaling_policy {
    max_replicas    = var.max_replica
    min_replicas    = var.min_replica
    cooldown_period = var.cool_down_period

    metric {
      name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
      filter                     = "resource.type = pubsub_subscription AND resource.label.subscription_id = ${var.ide_tasks_subscription}"
      single_instance_assignment = var.single_instance_max_task
    }

    cpu_utilization {
      target = 0.6
    }
  }
}

resource "google_compute_health_check" "ide_taskmaster" {
  name = "ide-taskmaster-health-check"

  check_interval_sec = 5
  timeout_sec        = 5

  http_health_check {
    request_path = "/_/healthcheck"
    response     = "OK"
    port         = 3001
  }
}

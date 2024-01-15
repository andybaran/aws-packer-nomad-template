packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

locals {
  mounts = replace(join(", ", var.nfs_shares), ",", "")
}

source "amazon-ebs" "hashistack" {
  ami_name              = "hashistack-${local.timestamp}"
  instance_type         = "t2.medium"
  region                = var.region
  source_ami            = "ami-0ec3d9efceafb89e0"
  ssh_username          = "admin"
  force_deregister      = true
  force_delete_snapshot = true

  tags = {
    Name          = "nomad-alb"
    source        = "hashicorp/learn"
    purpose       = "demo"
    OS_Version    = "Ubuntu"
    Release       = "Latest"
    Base_AMI_ID   = "{{ .SourceAMI }}"
    Base_AMI_Name = "{{ .SourceAMIName }}"
  }

  snapshot_tags = {
    Name    = "nomad-alb"
    source  = "hashicorp/learn"
    purpose = "demo"
  }
}

build {
  sources = ["source.amazon-ebs.hashistack"]

  provisioner "file" {
    destination = "/tmp/nomad.hcl"
    source      = "./${var.nomad_config}"
  }

  provisioner "file" {
    destination = "/tmp/license.hclic"
    source      = "./${var.license}"
  }

  provisioner "file" {
    destination = "/tmp/nomad.service"
    source      = "./nomad.service.pkrtpl"
  }

  provisioner "shell" {
    script            = "./post.sh"
    pause_before      = "60s"
    expect_disconnect = true
    timeout           = "30m"
    environment_vars = [
      "NOMAD_VERSION=${var.nomad_ver}",
      "OS_USER=${var.os_user}",
      "ENTERPRISE=${var.enterprise}",
    ]
  }

  provisioner "shell" {
    inline = ["systemctl enable nomad"]
  }

}

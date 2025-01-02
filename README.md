# Terraform & AWS EKS

## Project Overview
This project automates the provisioning of an Amazon EKS cluster using Terraform. Additionally, it deploys an NGINX application to the cluster to demonstrate its functionality.

### Technologies
- **Terraform**: Infrastructure as Code (IaC) tool for managing and provisioning resources.
- **AWS EKS**: Managed Kubernetes service for deploying containerized applications.
- **Docker**: Used for containerizing applications.
- **Linux**: The operating system used for the development environment.
- **Git**: Version control system.

## Files in the Project

### Key Configuration Files
1. **`eks-cluster.tf`**: Defines the EKS cluster and managed node groups.
2. **`providers.tf`**: Specifies the required providers and their versions.
3. **`vpc.tf`**: Configures the VPC and networking components for the EKS cluster.
4. **`nginx-config.yaml`**: Kubernetes YAML for deploying an NGINX application and exposing it via a LoadBalancer.

---

## Project Setup and Execution

### Step 1: Write VPC configuration 
#### Configuration
The VPC is provisioned using the Terraform AWS VPC module. It includes public and private subnets for EKS usage.

**File: `vpc.tf`**
```hcl
provider "aws" {
  region = "us-east-1"
}

variable "vpc_cidr_block" {}
variable "private_subnets_cidr_blocks" {}
variable "public_subnets_cidr_blocks" {}

data "aws_availability_zones" "azs" {}

module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.15.0"

  name            = "myapp-vpc"
  cidr            = var.vpc_cidr_block
  private_subnets = var.private_subnets_cidr_blocks
  public_subnets  = var.public_subnets_cidr_blocks
  azs             = data.aws_availability_zones.azs.names

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                  = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"         = 1
  }
}
```

#### Steps
1. **Initialize Terraform**:
   ```bash
   terraform init
   ```
2. **Validate the Configuration**:
   ```bash
   terraform plan
   ```
3. **Apply the Configuration**:
   ```bash
   terraform apply --auto-approve
   ```

---

### Step 2: Write EKS Cluster configuration
#### Configuration
The EKS cluster and managed node groups are defined using the Terraform AWS EKS module.

**File: `eks-cluster.tf`**
```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.29.0"

  cluster_name = "myapp-eks-cluster"
  cluster_version = "1.31"
  cluster_endpoint_public_access = true

  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id = module.myapp-vpc.vpc_id

  tags = {
    environment = "development"
    application = "myapp"
  }

  eks_managed_node_groups = {
    dev = {
      instance_types = ["t2.small"]
      min_size     = 1
      max_size     = 3
      desired_size = 3
    }
  }
}
```

### Step 3: Execute Terraform commands to apply the configurations

1. **Reinitialize Terraform**:
   ```bash
   terraform init
   ```
2. **Plan and Apply**:
   ```bash
   terraform plan
   terraform apply --auto-approve
   ```

---

### Step 4: Deploy NGINX to the Cluster
#### Configuration
The NGINX deployment and service configuration is written in `nginx-config.yaml`.

**File: `nginx-config.yaml`**
```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
  type: LoadBalancer
```

#### Steps
1. **Update Kubeconfig**:
   ```bash
   aws eks update-kubeconfig --name myapp-eks-cluster --region us-east-1
   ```
2. **Check Cluster Connection**:
   ```bash
   kubectl get nodes
   ```
3. **Deploy NGINX**:
   ```bash
   kubectl apply -f nginx-config.yaml
   ```
4. **Verify Deployment**:
   ```bash
   kubectl get pods
   kubectl get services
   ```

---



# AWS EKS & ECR Microservices Deployment — CI/CD Automation

End-to-end DevOps pipeline that provisions **AWS infrastructure with Terraform**, containerizes microservices and pushes to **Amazon ECR**, and deploys to an **Amazon EKS** cluster — all automated through a **GitHub Actions CI/CD** workflow.

> **Note:** The application code is based on the [Docker Example Voting App](https://github.com/dockersamples/example-voting-app). This project focuses entirely on the **DevOps and infrastructure side** — cloud provisioning, containerization, orchestration, and CI/CD automation.

---

## What I Built

### 1. Infrastructure as Code (Terraform)

Provisioned the complete AWS environment using Terraform with official AWS modules, managed through **Terraform Cloud** for remote state and collaboration.

- **VPC** — Custom network (`10.0.0.0/16`) with 3 public and 3 private subnets across 3 Availability Zones (`ap-southeast-1a/b/c`), NAT gateway, DNS hostnames, and proper subnet tagging for Kubernetes load balancers
- **EKS Cluster** — Managed Kubernetes cluster (`v1.33`) with a node group of `t3.medium` instances (auto-scaling 1–3 nodes), IRSA enabled, essential addons (CoreDNS, kube-proxy, VPC CNI, Pod Identity Agent), and cluster admin access configured
- **ECR Repositories** — Three private Docker registries (`vote-app`, `worker-app`, `result-app`) with image scan on push enabled

### 2. Kubernetes Manifests

Wrote Kubernetes deployment and service manifests for all five services:

- **3 application deployments** (vote, result, worker) with ECR image placeholders that are dynamically injected at deploy time
- **2 infrastructure deployments** (Redis, PostgreSQL) using public images with `emptyDir` volumes
- **4 services** — `LoadBalancer` type for vote and result (publicly accessible via AWS ELB), `ClusterIP` for Redis and PostgreSQL (internal only)
- Configured replica scaling (tested scaling vote app up to 10 replicas and back down to 2)

### 3. CI/CD Pipeline (GitHub Actions)

Built a fully automated deployment pipeline triggered on every push to `main`:

1. **Checkout** code
2. **Authenticate** with AWS using IAM credentials (stored as GitHub Secrets)
3. **Login** to Amazon ECR
4. **Build** Docker images for all 3 microservices and **push** to their respective ECR repos (tagged with commit SHA for traceability)
5. **Configure kubectl** to target the EKS cluster
6. **Inject** ECR image URIs into Kubernetes manifests (replacing placeholders via `sed`)
7. **Deploy** all manifests to the EKS cluster with `kubectl apply`

### 4. Debugging & Iteration

Worked through real infrastructure challenges including:

- Fixing EKS module configuration errors
- Enabling public endpoint access on the EKS cluster for CI/CD connectivity
- Resolving ECR lifecycle policy conflicts
- Fixing YAML filename references in the GitHub Actions workflow
- Scaling and testing deployment replicas

---

## Architecture

```
                          ┌──────────────────────────────────────────────────┐
                          │                  AWS Cloud                       │
                          │                                                  │
   GitHub Actions ──────▶│   ┌─────────┐     ┌─────────┐     ┌─────────┐    │
   (Build & Push)         │   │vote-app │     │worker-  │     │result-  │    │
                          │   │  (ECR)  │     │app(ECR) │     │app(ECR) │    │
                          │   └────┬────┘     └────┬────┘     └────┬────┘    │
                          │        │               │               │         │
   GitHub Actions ──────▶│   ┌────▼───────────────▼───────────────▼──────┐  │
   (kubectl apply)        │   │              EKS Cluster                  │  │
                          │   │                                           │  │
                          │   │  ┌───────┐    ┌───────┐    ┌──────────┐   │  │
                          │   │  │ Vote  │──▶│ Redis  │◀──│  Worker  │   │  │
                          │   │  │(Flask)│    │(Queue)│    │  (.NET)  │   │  │
                          │   │  └───────┘    └───────┘    └────┬─────┘   │  │
                          │   │                                 │         │  │
                          │   │  ┌──────────┐    ┌──────────────▼────┐    │  |
                          │   │  │  Result  │◀─ │    PostgreSQL     │    │  │
                          │   │  │(Node.js) │    │    (Database)     │    │  │
                          │   │  └──────────┘    └───────────────────┘    │  │
                          │   │                                           │  │
                          │   └───────────────────────────────────────────┘  │
                          │                                                  │
                          │            VPC (3 AZs, Public + Private Subnets) │
                          └──────────────────────────────────────────────────┘
```

---

## Project Structure

```
.
├── .github/workflows/
│   └── deploy.yaml          # CI/CD — build, push to ECR, deploy to EKS
├── terraform/
│   ├── providers.tf         # AWS provider, Terraform Cloud backend
│   ├── vpc.tf               # VPC, subnets, NAT gateway
│   ├── eks.tf               # EKS cluster, node groups, addons
│   └── ecr.tf               # 3 ECR repositories
├── k8s/
│   ├── vote-deployment.yaml
│   ├── vote-service.yaml    # LoadBalancer
│   ├── result-deployment.yaml
│   ├── result-service.yaml  # LoadBalancer
│   ├── worker-deployment.yaml
│   ├── redis-deployment.yaml
│   ├── redis-service.yaml   # ClusterIP
│   ├── db-deployment.yaml
│   └── db-service.yaml      # ClusterIP
├── vote/                    # Python/Flask app + Dockerfile
├── result/                  # Node.js/Express app + Dockerfile
└── worker/                  # .NET 7/C# app + Dockerfile
```

---

## Tools & Technologies

| Category               | Tools                          |
| ---------------------- | ------------------------------ |
| **Cloud Provider**     | AWS (VPC, EKS, ECR, ELB, IAM)  |
| **IaC**                | Terraform, Terraform Cloud     |
| **Containerization**   | Docker (multi-stage builds)    |
| **Container Registry** | Amazon ECR                     |
| **Orchestration**      | Kubernetes (Amazon EKS, v1.33) |
| **CI/CD**              | GitHub Actions                 |
| **OS / Runtime**       | Amazon Linux 2023 (EKS nodes)  |

---

## How to Run This Project

### Prerequisites

- AWS account with permissions for VPC, EKS, ECR, and IAM
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured
- [Terraform](https://developer.hashicorp.com/terraform/install) (v1.0+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Docker](https://docs.docker.com/get-docker/)

### 1. Provision Infrastructure

```bash
cd terraform

# Update providers.tf:
#   - Set your Terraform Cloud org/workspace, or switch to local backend
#   - Set your preferred AWS region

terraform init
terraform plan
terraform apply    # Takes ~15–20 min for EKS
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --name eks-microservices --region ap-southeast-1
kubectl get nodes   # Verify connectivity
```

### 3. Set Up CI/CD

Add these **GitHub Secrets** to your repository:

| Secret                  | Value                   |
| ----------------------- | ----------------------- |
| `AWS_ACCESS_KEY_ID`     | Your AWS IAM access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS IAM secret key |

Push to `main` and the pipeline will automatically build, push, and deploy.

### 4. Access the App

```bash
kubectl get svc vote result
```

Use the `EXTERNAL-IP` values (AWS ELB DNS names) to access the Vote and Result UIs in your browser.

### Cleanup

```bash
kubectl delete -f k8s/
cd terraform && terraform destroy
```

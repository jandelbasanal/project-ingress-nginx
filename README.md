# Hello World on EKS with Ingress via AWS ALB and ingress-nginx installed

This repository provisions a simple hello world app on Kubernetes and exposes it to the internet through an AWS Application Load Balancer (ALB) using an Ingress resource. It also installs `ingress-nginx` via Helm (optionally exposed with an NLB) and sets up a GitHub Actions workflow to deploy on merges to `master`.

Components:
- EKS cluster definition (3x t3.medium nodes)
- AWS Load Balancer Controller for ALB support
- ingress-nginx installed via Helm (not required for ALB, included per request)
- Hello world Deployment, Service, and Ingress (ALB)
- GitHub Actions workflow to deploy on push to master

## Prerequisites
- AWS account with permissions to manage EKS, IAM, EC2, VPC, ACM, and Load Balancers
- GitHub repository secrets configured:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION` (e.g., `us-east-1`)
  - `EKS_CLUSTER_NAME` (e.g., `demo-cluster`)
- Local tools if provisioning yourself: `eksctl`, `kubectl`, `helm`, `awscli`

## Create the cluster
You can create the cluster using `eksctl` with the provided config:

```bash
eksctl create cluster -f eks/cluster-config.yaml
```

This creates a 3-node t3.medium managed node group with OIDC enabled and common addon IAM policies.

## Install controllers
If not using the GitHub Actions workflow, install controllers manually:

```bash
# Configure kubeconfig
aws eks update-kubeconfig --name demo-cluster --region us-east-1

# Install ingress-nginx (optional for ALB exposure)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  -f helm/ingress-nginx-values.yaml

# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=demo-cluster \
  --set region=us-east-1 \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller
```

Note: For production, create and annotate a pre-existing IAM role for the controller using IRSA and set `serviceAccount.create=false` and `serviceAccount.annotations`. See AWS docs for the latest steps.

## Deploy the app
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/app/deployment.yaml
kubectl apply -f k8s/app/service.yaml
kubectl apply -f k8s/app/ingress.yaml
```

Get the ALB hostname:
```bash
kubectl -n demo get ingress hello-world -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```
Open http://<hostname>/

## GitHub Actions CI/CD
Workflow file: `.github/workflows/deploy.yaml`
- Triggers on push to master.
- Installs tools, configures kubeconfig for the specified cluster, installs ingress-nginx and the AWS Load Balancer Controller, then applies the app manifests.
- Publishes the ALB hostname as a build artifact.

## Notes
- If you want HTTPS, provision an ACM certificate in your region and add `alb.ingress.kubernetes.io/certificate-arn` and HTTPS listen ports in `k8s/app/ingress.yaml`.
- If you prefer using ingress-nginx as the internet entry point, switch the Service type in `helm/ingress-nginx-values.yaml` to `LoadBalancer` (already set), and change the Ingress to use `kubernetes.io/ingress.class: nginx` with `ingressClassName: nginx`. Then point Route53 to the NLB created by the ingress-nginx Service.
- For cost control, delete the cluster when done:
```bash
eksctl delete cluster --name demo-cluster --region us-east-1

```

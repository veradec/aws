# CI/CD Pipeline: Jenkins → Docker → Kubernetes (Flask App)

## Files

| File | Purpose |
|------|---------|
| `setup-jenkins-k8s.sh` | Installs Jenkins, Docker, kubectl on EC2 |
| `Jenkinsfile` | Full pipeline: Build → Test → Docker Push → K8s Deploy |
| `Dockerfile` | Containerizes Flask app with gunicorn |
| `app.py` | Simple Flask app with `/` and `/health` endpoints |
| `requirements.txt` | Python dependencies |
| `k8s-deployment.yaml` | K8s Deployment (3 replicas) + LoadBalancer Service |

---

## Quick Start

### 1. Copy to EC2
```bash
scp -i q1.pem setup-jenkins-k8s.sh Jenkinsfile Dockerfile app.py requirements.txt k8s-deployment.yaml ec2-user@54.224.143.74:~/
```

### 2. Run Setup on EC2
```bash
ssh -i q1.pem ec2-user@54.224.143.74
chmod +x setup-jenkins-k8s.sh
./setup-jenkins-k8s.sh
```

### 3. Configure Jenkins
1. Open `http://<EC2-PUBLIC-IP>:8080`
2. Use initial admin password from script output
3. Install suggested plugins
4. Create admin user

### 4. Add Credentials (Manage Jenkins → Credentials → Global)

| Credential ID | Type | Value |
|--------------|------|-------|
| `dockerhub-creds` | Username with password | Your Docker Hub username/password |
| `kubeconfig` | Secret file | Contents of your `~/.kube/config` |

### 5. Update Docker Hub Username
Edit `Jenkinsfile` and `k8s-deployment.yaml`:
- Replace `your-dockerhub-username` with your actual Docker Hub username

### 6. Create Pipeline Job
1. New Item → Pipeline → Name: `flask-app-pipeline`
2. Pipeline → Definition: **Pipeline script from SCM**
3. SCM: Git → Your repo URL
4. Branch: `*/main`
5. Script Path: `Jenkinsfile`
6. Save → Build Now

---

## Kubernetes Cluster Setup

### Option A: EKS (Recommended)
```bash
eksctl create cluster --name my-cluster --region us-east-1 --nodes 3
aws eks update-kubeconfig --name my-cluster --region us-east-1
```

### Option B: Minikube (on EC2)
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --driver=docker
```

### Option C: Kind (lightweight)
```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind
kind create cluster
```

Get kubeconfig for Jenkins credential:
```bash
cat ~/.kube/config
```

---

## Pipeline Stages

```
Checkout → Build → Unit Tests → Docker Build & Push → Deploy to K8s → Verify
```

- Tags image with `git-commit-hash-build-number` (e.g., `a1b2c3d-42`)
- Also tags as `latest`
- Uses image digest for immutable deployment
- Auto-rollback on failure

---

## Test Locally

```bash
# Build
docker build -t flask-app .

# Run
docker run -p 8000:8000 flask-app

# Test
curl http://localhost:8000/
curl http://localhost:8000/health
```

---

## Verify Deployment

```bash
kubectl get pods -l app=flask-app
kubectl get svc flask-app-service
kubectl logs -l app=flask-app --tail=50

# Get LoadBalancer IP
kubectl get svc flask-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

## Customize

- **Replicas**: Change `replicas` in `k8s-deployment.yaml`
- **Resources**: Adjust CPU/memory limits/requests
- **Port**: Update `containerPort` and `targetPort` if different
- **Env vars**: Add `env:` section in deployment spec
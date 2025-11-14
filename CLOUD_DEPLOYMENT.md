# Cloud Deployment Options

This guide covers deploying the microservices-demo on various cloud providers and self-hosted solutions.

## Cloud Providers

### Google Kubernetes Engine (GKE)

```bash
# Create cluster
gcloud container clusters create microservices-demo \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type n1-standard-2 \
  --enable-autoscaling \
  --min-nodes 3 \
  --max-nodes 6

# Get credentials
gcloud container clusters get-credentials microservices-demo --zone us-central1-a

# Deploy
./scripts/setup.sh

# Expose Grafana with LoadBalancer
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc prometheus-grafana -n monitoring

# Cleanup
gcloud container clusters delete microservices-demo --zone us-central1-a
```

**Cost Estimate**: ~$150-200/month for 3 n1-standard-2 nodes

---

### Amazon EKS

```bash
# Install eksctl
# https://eksctl.io/installation/

# Create cluster
eksctl create cluster \
  --name microservices-demo \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 3 \
  --nodes-max 6 \
  --managed

# Deploy
./scripts/setup.sh

# Expose Grafana with LoadBalancer
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc prometheus-grafana -n monitoring

# Cleanup
eksctl delete cluster --name microservices-demo --region us-east-1
```

**Cost Estimate**: ~$180-220/month (EKS control plane + 3 t3.medium nodes)

---

### Azure Kubernetes Service (AKS)

```bash
# Create resource group
az group create --name microservices-demo-rg --location eastus

# Create cluster
az aks create \
  --resource-group microservices-demo-rg \
  --name microservices-demo \
  --node-count 3 \
  --node-vm-size Standard_B2s \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group microservices-demo-rg --name microservices-demo

# Deploy
./scripts/setup.sh

# Expose Grafana with LoadBalancer
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc prometheus-grafana -n monitoring

# Cleanup
az group delete --name microservices-demo-rg --yes --no-wait
```

**Cost Estimate**: ~$150-180/month for 3 Standard_B2s nodes

---

### DigitalOcean Kubernetes (DOKS)

```bash
# Install doctl
# https://docs.digitalocean.com/reference/doctl/how-to/install/

# Create cluster
doctl kubernetes cluster create microservices-demo \
  --region nyc1 \
  --size s-2vcpu-4gb \
  --count 3 \
  --auto-upgrade=true

# Get credentials (automatic)

# Deploy
./scripts/setup.sh

# Expose Grafana with LoadBalancer
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc prometheus-grafana -n monitoring

# Cleanup
doctl kubernetes cluster delete microservices-demo
```

**Cost Estimate**: ~$120-150/month for 3 s-2vcpu-4gb droplets

---

### Linode Kubernetes Engine (LKE)

```bash
# Create cluster via Linode Cloud Manager or CLI
# https://www.linode.com/docs/products/compute/kubernetes/

# Download kubeconfig from Linode dashboard

# Deploy
./scripts/setup.sh

# Expose Grafana with NodeBalancer (LoadBalancer)
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc prometheus-grafana -n monitoring

# Cleanup via Linode dashboard
```

**Cost Estimate**: ~$90-120/month for 3 Linode 4GB nodes

---

## Self-Hosted Solutions

### Minikube (Local Development)

```bash
# Start minikube with sufficient resources
minikube start \
  --cpus=4 \
  --memory=8192 \
  --disk-size=40g \
  --driver=docker

# Enable addons
minikube addons enable metrics-server
minikube addons enable ingress

# Deploy
./scripts/setup.sh

# Access Grafana
minikube service prometheus-grafana -n monitoring

# Or use port-forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Cleanup
minikube delete
```

**Cost**: Free (local resources)

---

### Kind (Kubernetes in Docker)

```bash
# Create cluster with custom config
kind create cluster --config kind-config.yaml --name microservices-demo

# Deploy
./scripts/setup.sh

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Cleanup
kind delete cluster --name microservices-demo
```

**Cost**: Free (local resources)

---

### K3s (Lightweight Kubernetes)

Perfect for self-hosted on VPS or bare metal.

```bash
# Install K3s on server
curl -sfL https://get.k3s.io | sh -

# Copy kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
# Edit server address in config

# Deploy
./scripts/setup.sh

# Expose Grafana with NodePort
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "nodePort": 30080}]}}'

# Access via http://<server-ip>:30080

# Cleanup
/usr/local/bin/k3s-uninstall.sh
```

**Cost**: VPS cost (~$5-20/month for 4GB RAM VPS)

**Recommended VPS Providers**:
- Hetzner Cloud: €4.51/month (CX21: 2 vCPU, 4GB RAM)
- Vultr: $6/month (2 vCPU, 4GB RAM)
- DigitalOcean: $12/month (2 vCPU, 4GB RAM)
- Linode: $12/month (2 vCPU, 4GB RAM)

---

### MicroK8s (Ubuntu)

```bash
# Install MicroK8s
sudo snap install microk8s --classic

# Add user to group
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube
newgrp microk8s

# Enable addons
microk8s enable dns storage helm3 prometheus

# Setup kubectl alias
alias kubectl='microk8s kubectl'

# Deploy
./scripts/setup.sh

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Cleanup
microk8s reset
```

**Cost**: Free (local) or VPS cost

---

## Exposing Grafana Publicly (Non-ngrok)

### Option 1: Cloud LoadBalancer

```bash
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'

# Wait for external IP
kubectl get svc prometheus-grafana -n monitoring -w

# Access via http://<EXTERNAL-IP>
```

**Pros**: Easy, automatic SSL with cert-manager
**Cons**: Additional cost (~$10-15/month)

---

### Option 2: NodePort + Firewall

```bash
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "nodePort": 30080}]}}'

# Open firewall port
# GCP: gcloud compute firewall-rules create grafana --allow tcp:30080
# AWS: Add security group rule for port 30080
# Azure: Add NSG rule for port 30080

# Access via http://<node-ip>:30080
```

**Pros**: No additional cost
**Cons**: Non-standard port, manual firewall management

---

### Option 3: Ingress with SSL

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Install nginx ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Create ingress with Let's Encrypt
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - grafana.yourdomain.com
    secretName: grafana-tls
  rules:
  - host: grafana.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-grafana
            port:
              number: 80
EOF

# Point DNS A record: grafana.yourdomain.com → LoadBalancer IP
# Access via https://grafana.yourdomain.com
```

**Pros**: Professional, SSL, custom domain
**Cons**: Requires domain name

---

### Option 4: Cloudflare Tunnel (Free)

```bash
# Install cloudflared
# https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/

# Create tunnel
cloudflared tunnel create microservices-demo

# Configure tunnel
cat > ~/.cloudflared/config.yml <<EOF
tunnel: <tunnel-id>
credentials-file: /root/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: grafana.yourdomain.com
    service: http://localhost:3000
  - service: http_status:404
EOF

# Run tunnel
cloudflared tunnel run microservices-demo

# Or deploy in Kubernetes
kubectl create secret generic tunnel-credentials \
  --from-file=credentials.json=/root/.cloudflared/<tunnel-id>.json \
  -n monitoring

# Deploy cloudflared
# (See Cloudflare docs for full deployment)
```

**Pros**: Free, no firewall changes, DDoS protection
**Cons**: Requires Cloudflare account

---

## Cost Comparison

| Solution | Monthly Cost | Setup Time | Best For |
|----------|-------------|------------|----------|
| Minikube | $0 | 5 min | Local dev |
| Kind | $0 | 5 min | Local dev |
| K3s on VPS | $5-20 | 15 min | Self-hosted |
| DigitalOcean | $120-150 | 10 min | Simplicity |
| Linode | $90-120 | 10 min | Cost-effective |
| GKE | $150-200 | 15 min | Google ecosystem |
| EKS | $180-220 | 20 min | AWS ecosystem |
| AKS | $150-180 | 15 min | Azure ecosystem |

---

## Recommendations

### For This Assignment (Interview Guarantee)

**Best Option**: K3s on Hetzner Cloud VPS
- Cost: €4.51/month (~$5)
- Public IP included
- Easy NodePort access
- Can run for a month for evaluation

**Setup**:
```bash
# On Hetzner VPS (Ubuntu 22.04)
curl -sfL https://get.k3s.io | sh -
sudo cat /etc/rancher/k3s/k3s.yaml

# On local machine
# Copy kubeconfig and update server IP
./scripts/setup.sh

# Expose Grafana
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "nodePort": 30080}]}}'

# Share: http://<vps-ip>:30080
```

### For Production

**Best Option**: Managed Kubernetes + Ingress + SSL
- Use GKE/EKS/AKS/DOKS
- Install nginx-ingress + cert-manager
- Use custom domain with SSL
- Enable monitoring and backups

---

## Security Considerations

### For Public Exposure

1. **Change default passwords**:
```bash
kubectl patch secret prometheus-grafana -n monitoring -p '{"data":{"admin-password":"'$(echo -n "NewSecurePassword123!" | base64)'"}}'
kubectl rollout restart deployment prometheus-grafana -n monitoring
```

2. **Enable authentication**:
- Grafana has built-in auth (already enabled)
- Consider OAuth/LDAP for production

3. **Use HTTPS**:
- Always use SSL in production
- Let's Encrypt is free

4. **Restrict access**:
```bash
# Firewall rules
# Allow only specific IPs if possible
```

5. **Regular updates**:
```bash
helm repo update
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

---

## Monitoring the Monitoring

```bash
# Check Prometheus health
kubectl exec -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 -- \
  wget -qO- localhost:9090/-/healthy

# Check Loki health
kubectl exec -n monitoring loki-0 -- wget -qO- localhost:3100/ready

# Check Grafana health
kubectl exec -n monitoring deployment/prometheus-grafana -- \
  wget -qO- localhost:3000/api/health
```

---

## Troubleshooting Cloud Deployments

### LoadBalancer Pending
```bash
# Check cloud provider integration
kubectl describe svc prometheus-grafana -n monitoring

# For minikube
minikube tunnel

# For kind
# LoadBalancer not supported, use NodePort
```

### Insufficient Resources
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Scale cluster
# GKE: gcloud container clusters resize microservices-demo --num-nodes 4
# EKS: eksctl scale nodegroup --cluster=microservices-demo --nodes=4
```

### Persistent Volume Issues
```bash
# Check storage class
kubectl get storageclass

# Check PVCs
kubectl get pvc -n microservices-demo
kubectl get pvc -n monitoring

# Describe for details
kubectl describe pvc postgres-pvc -n microservices-demo
```

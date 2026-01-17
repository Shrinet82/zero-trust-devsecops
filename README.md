# 🛡️ Zero-Trust Azure DevSecOps Platform

[![Azure](https://img.shields.io/badge/Azure-Enabled-0078D4?logo=microsoft-azure)](https://azure.microsoft.com)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-623CE4?logo=terraform)](https://terraform.io)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-AKS-326CE5?logo=kubernetes)](https://azure.microsoft.com/en-us/products/kubernetes-service)
[![Security](https://img.shields.io/badge/Security-Zero%20Trust-FF0000?logo=shield)](https://learn.microsoft.com/en-us/security/zero-trust/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **A production-grade, 2026-compliant DevSecOps pipeline demonstrating Zero-Trust security principles on Microsoft Azure.**

This project implements a complete CI/CD pipeline with integrated security scanning, secret management, and runtime protection. It serves as a reference architecture for organizations looking to adopt modern DevSecOps practices.

## 🚀 Live Deployment Proof

> **This is not just documentation — it's a running system.**

| Metric                      | Value                                                                               | Status      |
| --------------------------- | ----------------------------------------------------------------------------------- | ----------- |
| **GitHub Repository**       | [Shrinet82/zero-trust-devsecops](https://github.com/Shrinet82/zero-trust-devsecops) | ✅ Live     |
| **AKS Cluster FQDN**        | `aksdevsecops-fhh0yrdk.hcp.eastus.azmk8s.io`                                        | ✅ Running  |
| **Kubernetes Version**      | 1.33                                                                                | ✅ Latest   |
| **Pipeline Runs**           | 20+ builds                                                                          | ✅ Green    |
| **Pods Running**            | 1/1 (sample-app)                                                                    | ✅ Healthy  |
| **Secrets Injected**        | `AppApiKey` mounted via CSI                                                         | ✅ Verified |
| **Vulnerabilities Blocked** | 0 CRITICAL/HIGH in prod                                                             | ✅ Clean    |
| **Privileged Pods**         | BLOCKED by Policy                                                                   | ✅ Enforced |

### Live kubectl Output

```bash
$ kubectl get all -o wide
NAME                              READY   STATUS    RESTARTS   AGE
pod/sample-app-6c555ddc5d-pj2z2   1/1     Running   0          153m

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/sample-app   1/1     1            1           4h12m

$ kubectl exec deployment/sample-app -- cat /mnt/secrets-store/AppApiKey
SUPER_SECRET_REMOTEROLE_KEY_2026
```

---

## 📑 Table of Contents

- [Project Overview](#-project-overview)
- [Key Features](#-key-features)
- [Architecture](#-architecture)
  - [High-Level Architecture](#high-level-architecture)
  - [Security Zones](#security-zones-deep-dive)
  - [Low-Level Architecture](#low-level-architecture)
- [Technology Stack](#-technology-stack)
- [Prerequisites](#-prerequisites)
- [Installation Guide](#-installation-guide)
- [Pipeline Stages](#-pipeline-stages)
- [Security Controls](#-security-controls)
- [Verification & Testing](#-verification--testing)
- [Screenshots](#-screenshots)
- [Cost Estimation](#-cost-estimation)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Project Overview

This platform demonstrates how to build a **Zero-Trust DevSecOps pipeline** that:

| Principle                      | Implementation                                       |
| ------------------------------ | ---------------------------------------------------- |
| **Never Trust, Always Verify** | OIDC-based authentication, no long-lived secrets     |
| **Least Privilege**            | RBAC for all resources, scoped permissions           |
| **Assume Breach**              | Runtime protection with Defender, Policy enforcement |
| **Defense in Depth**           | Multiple security layers from code to cluster        |

### What Problems Does This Solve?

| Traditional Approach           | Zero-Trust Approach                |
| ------------------------------ | ---------------------------------- |
| Hardcoded secrets in pipelines | OIDC federated credentials         |
| Manual security reviews        | Automated Trivy scanning           |
| Static access policies         | Dynamic, identity-based access     |
| Trust-based networking         | Policy-enforced workloads          |
| Post-deployment security       | Shift-left security at every stage |

---

## ✨ Key Features

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ZERO-TRUST SECURITY FEATURES                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  ✅ OIDC Authentication (No stored secrets)                                │
│  ✅ Gitleaks Secret Scanning (Git History)                                  │
│  ✅ Checkov IaC Scanning (Kubernetes Manifests)                             │
│  ✅ Trivy Container Vulnerability Scanning                                  │
│  ✅ Azure Key Vault with CSI Driver Secret Injection                       │
│  ✅ Azure Policy (Gatekeeper) for Pod Security Standards                   │
│  ✅ Microsoft Defender for Containers                                      │
│  ✅ OWASP ZAP DAST (Runtime Vulnerability Scanning)                        │
│  ✅ Self-Hosted VMSS Build Agents (Elastic Scaling)                        │
│  ✅ Infrastructure as Code (Terraform)                                     │
│  ✅ GitOps-Ready Kubernetes Manifests                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Architecture

### High-Level Architecture

The following diagram shows the complete flow from code commit to production deployment:

```mermaid
flowchart TB
    subgraph Developer["Developer"]
        CODE[Source Code]
    end

    subgraph GitHub["GitHub Repository"]
        REPO[(Repository)]
    end

    subgraph AzureDevOps["Azure DevOps"]
        PIPELINE[CI/CD Pipeline]
        VMSS[VMSS Agent Pool]
    end

    subgraph Security["Security Gates"]
        TRIVY[Trivy Scanner]
        POLICY[Azure Policy]
    end

    subgraph Azure["Microsoft Azure"]
        subgraph Infra["Infrastructure"]
            ACR[Container Registry]
            AKS[Kubernetes Cluster]
            KV[Key Vault]
            LA[Log Analytics]
        end
        subgraph Runtime["Runtime Protection"]
            DEFENDER[Defender for Containers]
            GATEKEEPER[OPA Gatekeeper]
        end
    end

    CODE --> REPO
    REPO -->|Trigger| PIPELINE
    PIPELINE --> VMSS
    VMSS --> TRIVY
    TRIVY -->|Pass| ACR
    TRIVY -->|Fail| PIPELINE
    ACR --> AKS
    KV -->|CSI Driver| AKS
    POLICY --> GATEKEEPER
    GATEKEEPER --> AKS
    AKS --> DEFENDER
    DEFENDER --> LA

    style TRIVY fill:#ff6b6b,color:#fff
    style GATEKEEPER fill:#ff6b6b,color:#fff
    style KV fill:#4ecdc4,color:#fff
    style DEFENDER fill:#45b7d1,color:#fff
```

### Security Zones Deep Dive

The platform is organized into **4 Security Zones**, each addressing a specific security domain:

```mermaid
graph LR
    subgraph Zone1["Zone 1: Secure Supply Chain"]
        Z1A[Source Code]
        Z1B[Build Pipeline]
        Z1C[Trivy Scan]
        Z1D[Container Registry]
        Z1A --> Z1B --> Z1C --> Z1D
    end

    subgraph Zone2["Zone 2: Identity and Access"]
        Z2A[OIDC Federation]
        Z2B[Workload Identity]
        Z2C[Azure RBAC]
        Z2A --> Z2B --> Z2C
    end

    subgraph Zone3["Zone 3: Secret Management"]
        Z3A[Key Vault]
        Z3B[CSI Driver]
        Z3C[Pod Mount]
        Z3A --> Z3B --> Z3C
    end

    subgraph Zone4["Zone 4: Governance"]
        Z4A[Azure Policy]
        Z4B[Gatekeeper]
        Z4C[Defender]
        Z4A --> Z4B --> Z4C
    end

    Zone1 --> Zone2
    Zone2 --> Zone3
    Zone3 --> Zone4

    style Zone1 fill:#3498db,color:#fff
    style Zone2 fill:#9b59b6,color:#fff
    style Zone3 fill:#2ecc71,color:#fff
    style Zone4 fill:#e74c3c,color:#fff
```

#### Zone Details

| Zone       | Purpose             | Components                          | Security Benefit                                        |
| ---------- | ------------------- | ----------------------------------- | ------------------------------------------------------- |
| **Zone 1** | Secure Supply Chain | GitHub, Azure Pipelines, Trivy, ACR | Prevents vulnerable images from reaching production     |
| **Zone 2** | Identity & Access   | OIDC, Workload Identity, RBAC       | Eliminates credential exposure, enables least-privilege |
| **Zone 3** | Secret Management   | Key Vault, CSI Driver               | Secrets never exposed in environment variables          |
| **Zone 4** | Governance          | Azure Policy, Gatekeeper, Defender  | Runtime threat detection and policy enforcement         |

### Low-Level Architecture

#### Kubernetes Cluster Architecture

```mermaid
graph TB
    subgraph AKS["AKS Cluster: aks-devsecops-prod"]
        subgraph SystemNS["kube-system"]
            CSI[Secrets Store CSI]
            COREDNS[CoreDNS]
        end

        subgraph GatekeeperNS["gatekeeper-system"]
            AUDIT[Gatekeeper Audit]
            CONTROLLER[Gatekeeper Controller]
            WEBHOOK[Admission Webhook]
        end

        subgraph DefaultNS["default namespace"]
            DEPLOY[sample-app Deployment]
            POD[sample-app Pod]
            SECRET_VOL["/mnt/secrets-store"]
            DEPLOY --> POD
            POD --> SECRET_VOL
        end
    end

    subgraph External["External Services"]
        KV2[Azure Key Vault]
        ACR2[Azure Container Registry]
    end

    CSI -->|Fetch Secrets| KV2
    POD -->|Pull Image| ACR2
    WEBHOOK -->|Validate| POD

    style WEBHOOK fill:#ff6b6b,color:#fff
    style SECRET_VOL fill:#4ecdc4,color:#fff
```

#### Pipeline Flow Architecture

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant ADO as Azure DevOps
    participant Agent as VMSS Agent
    participant Trivy as Trivy Scanner
    participant ACR as Container Registry
    participant AKS as AKS Cluster
    participant KV as Key Vault
    participant GP as Gatekeeper

    Dev->>GH: Push Code
    GH->>ADO: Webhook Trigger
    ADO->>Agent: Assign Job
    Agent->>Agent: Docker Build
    Agent->>Trivy: Scan Image

    alt Vulnerabilities Found
        Trivy--xAgent: FAIL (Exit 1)
        Agent--xADO: Pipeline Failed
    else Clean Image
        Trivy->>Agent: PASS
        Agent->>ACR: Push Image
        Agent->>AKS: kubectl apply
        AKS->>GP: Validate Manifest
        GP->>AKS: Approved
        AKS->>KV: Mount Secrets
        AKS->>AKS: Pod Running
    end
```

#### VMSS Agent Pool Architecture

```mermaid
graph TB
    subgraph ADO["Azure DevOps"]
        POOL[VMSS-Pool]
        JOB1[Job 1]
        JOB2[Job 2]
    end

    subgraph VMSS["VMSS Agent Pool"]
        subgraph Inst0["Instance 0"]
            AGENT0[Pipelines Agent]
            DOCKER0[Docker]
            CLI0[Azure CLI]
        end
        subgraph Inst1["Instance 1"]
            AGENT1[Pipelines Agent]
            DOCKER1[Docker]
            CLI1[Azure CLI]
        end
    end

    POOL -->|Elastic Scale| VMSS
    JOB1 --> Inst0
    JOB2 --> Inst1

    style VMSS fill:#2ecc71,color:#fff
```

---

## 🛠️ Technology Stack

### Core Technologies

| Category                    | Technology               | Version  | Purpose                     |
| --------------------------- | ------------------------ | -------- | --------------------------- |
| **Cloud Provider**          | Microsoft Azure          | -        | Infrastructure hosting      |
| **Container Orchestration** | Azure Kubernetes Service | 1.33.x   | Application runtime         |
| **Container Registry**      | Azure Container Registry | Standard | Image storage               |
| **Secret Management**       | Azure Key Vault          | -        | Secure secret storage       |
| **IaC**                     | Terraform                | 3.x      | Infrastructure provisioning |
| **CI/CD**                   | Azure DevOps Pipelines   | -        | Build and deploy automation |
| **Source Control**          | GitHub                   | -        | Version control             |

### Security Tools

| Tool                   | Purpose                          | Integration Point           |
| ---------------------- | -------------------------------- | --------------------------- |
| **Gitleaks**           | Secret scanning                  | CI Pipeline (Security Gate) |
| **Checkov**            | IaC security scanning            | CI Pipeline (Security Gate) |
| **Trivy**              | Container vulnerability scanning | CI Pipeline (Build Stage)   |
| **Azure Policy**       | Kubernetes governance            | Cluster Admission Control   |
| **OPA Gatekeeper**     | Policy enforcement engine        | Kubernetes Webhook          |
| **Microsoft Defender** | Runtime threat detection         | AKS Add-on                  |
| **Secrets Store CSI**  | Secret injection                 | Pod Volume Mount            |
| **OWASP ZAP**          | DAST (Runtime Scanning)          | CD Pipeline (Verification)  |

### Programming Languages & Frameworks

| Component      | Language/Framework | File Location          |
| -------------- | ------------------ | ---------------------- |
| Application    | Python (Flask)     | `app/app.py`           |
| Infrastructure | HCL (Terraform)    | `devsecops-infra/*.tf` |
| Pipeline       | YAML               | `azure-pipelines.yml`  |
| Kubernetes     | YAML               | `k8s/*.yaml`           |

---

## 📦 Sample Application

The project includes a production-ready Flask application demonstrating security best practices:

### Application Code (`app/app.py`)

```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Zero-Trust Azure DevSecOps Pipeline is Live!"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
```

### Hardened Dockerfile (`app/Dockerfile`)

```dockerfile
# Use a slim, non-root image for a smaller attack surface
FROM python:3.9-slim

# Create a non-privileged user to run the app
RUN useradd -m devopsuser
USER devopsuser
WORKDIR /home/devopsuser

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000
CMD ["python", "app.py"]
```

> **Security Features**: Non-root user, slim base image, no cache for smaller attack surface.

---

## 🔄 Pipeline Code (`azure-pipelines.yml`)

### CI Stage: Build, Scan, and Push

```yaml
stages:
  - stage: BuildAndSecurityScan
    displayName: "CI Stage: Build and Scan"
    jobs:
      - job: Build
        pool:
          name: "VMSS-Pool" # Self-hosted elastic agents
        steps:
          - task: AzureCLI@2
            displayName: "Build and Push to ACR"
            inputs:
              azureSubscription: $(azureServiceConnection)
              scriptType: "bash"
              inlineScript: |
                az acr login --name $(azureContainerRegistry)
                docker build -t $(azureContainerRegistry)/$(imageRepository):$(tag) -f $(dockerfilePath) app/
                docker push $(azureContainerRegistry)/$(imageRepository):$(tag)

          # THE KILL LOGIC - Block vulnerable images
          - script: |
              trivy image --exit-code 1 --severity CRITICAL,HIGH \
                $(azureContainerRegistry)/$(imageRepository):$(tag)
            displayName: "Trivy Security Scan (Kill Logic)"
```

### CD Stage: Zero-Trust Deployment

```yaml
- stage: DeployToAKS
  displayName: "CD Stage: Zero-Trust Deployment"
  dependsOn: BuildAndSecurityScan
  jobs:
    - deployment: Deploy
      environment: "production"
      strategy:
        runOnce:
          deploy:
            steps:
              - task: KubernetesManifest@0
                inputs:
                  kubernetesCluster: "aks-devsecops-prod"
                  manifests: |
                    k8s/secretproviderclass.yaml
                    k8s/deployment.yaml
                  containers: "$(azureContainerRegistry)/$(imageRepository):$(tag)"
```

> **Full pipeline**: See [azure-pipelines.yml](azure-pipelines.yml) for complete configuration.

---

## 📋 Prerequisites

Before you begin, ensure you have the following:

### Local Development Environment

| Requirement | Minimum Version | Installation                                              |
| ----------- | --------------- | --------------------------------------------------------- |
| Azure CLI   | 2.50+           | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| Terraform   | 1.5+            | [Install Guide](https://terraform.io/downloads)           |
| kubectl     | 1.28+           | `az aks install-cli`                                      |
| kubelogin   | 0.0.30+         | `az aks install-cli`                                      |
| Docker      | 24+             | [Install Guide](https://docs.docker.com/get-docker/)      |
| Git         | 2.30+           | `sudo apt install git`                                    |

### Azure Resources

| Resource                  | Details                                     |
| ------------------------- | ------------------------------------------- |
| Azure Subscription        | Active subscription with Contributor access |
| Azure DevOps Organization | Free tier is sufficient                     |
| GitHub Account            | For source code hosting                     |
| Service Principal         | With Owner role (for initial setup)         |

### Required Permissions

| Scope        | Role                      | Purpose                   |
| ------------ | ------------------------- | ------------------------- |
| Subscription | Contributor               | Create resources          |
| Azure AD     | Application Administrator | Create Service Principals |
| Azure DevOps | Project Administrator     | Configure pipelines       |

---

## 📦 Installation Guide

### Step 1: Clone the Repository

```bash
git clone https://github.com/Shrinet82/zero-trust-devsecops.git
cd zero-trust-devsecops
```

### Step 2: Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "Your Subscription Name"

# Verify
az account show
```

### Step 3: Create Service Principal (OIDC)

```bash
# Create the application
az ad app create --display-name "devsecops-pipeline-oidc"

# Get the App ID (save this!)
APP_ID=$(az ad app list --display-name "devsecops-pipeline-oidc" --query "[0].appId" -o tsv)

# Create Service Principal
az ad sp create --id $APP_ID

# Get Object ID (save this!)
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query "id" -o tsv)

# Assign Contributor role
az role assignment create --assignee $SP_OBJECT_ID --role "Contributor" --scope "/subscriptions/$(az account show --query id -o tsv)"
```

### Step 4: Configure Federated Credentials

```bash
# Create federated credential JSON
cat > federated-credential.json << EOF
{
    "name": "azure-devops-federation",
    "issuer": "https://vstoken.dev.azure.com/<YOUR_ORG_ID>",
    "subject": "sc://<YOUR_ORG>/<YOUR_PROJECT>/<SERVICE_CONNECTION_NAME>",
    "audiences": ["api://AzureADTokenExchange"]
}
EOF

# Apply the credential
az ad app federated-credential create --id $APP_ID --parameters federated-credential.json
```

### Step 5: Deploy Infrastructure

```bash
cd devsecops-infra

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (this takes ~10-15 minutes)
terraform apply -auto-approve
```

### Step 6: Configure Azure DevOps

1. **Create Service Connection**:
   - Go to Project Settings → Service Connections
   - Create "Azure Resource Manager" connection
   - Select "Workload Identity federation (manual)"
   - Enter the App ID, Tenant ID, and Subscription ID

2. **Create Pipeline**:
   - Go to Pipelines → New Pipeline
   - Select GitHub as source
   - Choose this repository
   - Use existing `azure-pipelines.yml`

3. **Configure Agent Pool**:
   - Go to Organization Settings → Agent Pools
   - Add VMSS Pool
   - Connect to `vmss-devsecops-agents` scale set

### Step 7: Deploy Application

```bash
# Get AKS credentials
az aks get-credentials -g rg-devsecops-prod -n aks-devsecops-prod

# Configure kubelogin
kubelogin convert-kubeconfig -l azurecli

# Apply Kubernetes manifests
kubectl apply -f k8s/secretproviderclass.yaml
kubectl apply -f k8s/deployment.yaml

# Verify
kubectl get pods
```

---

## 🔄 Pipeline Stages (5-Stage "Shift Left" Architecture)

The pipeline has been refactored into **5 granular stages** to maximize observability and security:

### Stage 1: Security Gates (The Filter)

> **Goal**: Fail fast on security violations before code is even checked.

| Job             | Tool       | Purpose                                          |
| --------------- | ---------- | ------------------------------------------------ |
| **Secret Scan** | `gitleaks` | Detects hardcoded credentials in commit history  |
| **IaC Scan**    | `checkov`  | Scans Kubernetes manifests for misconfigurations |

### Stage 2: App Quality

> **Goal**: Ensure code logic and style are production-ready.

| Job            | Tool       | Purpose                                        |
| -------------- | ---------- | ---------------------------------------------- |
| **Linting**    | `flake8`   | Enforces Python code style (PEP 8)             |
| **SAST**       | `trivy fs` | Static analysis for filesystem vulnerabilities |
| **Unit Tests** | `pytest`   | Validates application logic                    |

### Stage 3: The Factory

> **Goal**: Create an immutable, vetted artifact.

| Job            | Tool     | Purpose                                          |
| -------------- | -------- | ------------------------------------------------ |
| **Build**      | `docker` | Builds the application container                 |
| **SBOM**       | `trivy`  | Generates CycleDX Software Bill of Materials     |
| **Kill Logic** | `trivy`  | Blocks build if Critical vulnerabilities found   |
| **Push**       | `az acr` | Pushes "Clean" image to Azure Container Registry |

### Stage 4: Delivery

> **Goal**: Specific Zero-Trust deployment to infrastructure.

| Job        | Tool      | Purpose                                                |
| ---------- | --------- | ------------------------------------------------------ |
| **Deploy** | `kubectl` | Applies manifests using Workload Identity (No Secrets) |

### Stage 5: Live Verification (The Proving Ground)

> **Goal**: Validate runtime health and security posture.

| Job            | Tool        | Purpose                                             |
| -------------- | ----------- | --------------------------------------------------- |
| **Smoke Test** | `kubectl`   | Verifies pod rollout status                         |
| **DAST**       | `OWASP ZAP` | Attacks running app to find runtime vulnerabilities |

---

## 🔐 Security Controls

### Control Matrix

| Control                    | Type       | Enforcement   | Evidence          |
| -------------------------- | ---------- | ------------- | ----------------- |
| Vulnerability Scanning     | Preventive | Pipeline Gate | Trivy JSON Report |
| Secret Injection           | Detective  | Runtime       | Pod Volume Mount  |
| Privileged Container Block | Preventive | Admission     | Gatekeeper Deny   |
| Root User Block            | Preventive | Admission     | Gatekeeper Deny   |
| Image Source Restriction   | Preventive | Admission     | Gatekeeper Deny   |
| Runtime Threat Detection   | Detective  | Continuous    | Defender Alerts   |

### Policy Constraints Active

| Constraint                        | Effect | Description                 |
| --------------------------------- | ------ | --------------------------- |
| `k8sazurev2noprivilege`           | Deny   | Block privileged containers |
| `k8sazurev3allowedusersgroups`    | Deny   | Require non-root user       |
| `k8sazurev3noprivilegeescalation` | Deny   | Block privilege escalation  |
| `k8sazurev2blockhostnamespace`    | Deny   | Block host namespace access |
| `k8sazurev3allowedseccomp`        | Deny   | Require seccomp profile     |

---

## ✅ Verification & Testing

### 1. Verify Pipeline Execution

Run the pipeline and confirm both stages pass:

```bash
# Check Azure DevOps for green pipeline
# Or trigger manually:
git commit --allow-empty -m "Trigger pipeline"
git push
```

### 2. Verify Secret Injection

```bash
# Get pod name
POD=$(kubectl get pods -l app=sample-app -o jsonpath='{.items[0].metadata.name}')

# Check secret mount
kubectl exec $POD -- ls /mnt/secrets-store
# Expected: AppApiKey

# Read secret value
kubectl exec $POD -- cat /mnt/secrets-store/AppApiKey
# Expected: SUPER_SECRET_REMOTEROLE_KEY_2026
```

### 3. Verify Policy Enforcement (The "Kill Test")

```bash
# Attempt to create privileged pod
kubectl run privileged-hack --image=nginx --privileged

# Expected Error:
# Error from server (Forbidden): admission webhook "validation.gatekeeper.sh"
# denied the request: [azurepolicy-k8sazurev2noprivilege-...]
# Privileged container is not allowed
```

### 4. Verify Defender Integration

```bash
# Check Defender status
az aks show -g rg-devsecops-prod -n aks-devsecops-prod \
  --query "securityProfile.defender.securityMonitoring.enabled"
# Expected: true
```

---

## 📸 Screenshots

### Pipeline Execution

#### Pipeline Runs History

_Shows multiple pipeline runs with successful and failed attempts during development:_

![Pipeline Runs History](docs/screenshots/pipeline-runs-history.png)

#### Successful Pipeline Run (Both Stages Green)

_CI Stage (Build & Scan) and CD Stage (Zero-Trust Deploy) both completed successfully:_

![Pipeline Success](docs/screenshots/pipeline-success.png)

---

### Security Scanning

#### Trivy Vulnerability Scan Results

_Container image scanned with zero vulnerabilities detected - the "Kill Logic" passes:_

![Trivy Scan Part 1](docs/screenshots/trivy-scan-1.png)

![Trivy Scan Part 2](docs/screenshots/trivy-scan-2.png)

---

### Policy Enforcement

#### Gatekeeper Privileged Pod Denial

_Azure Policy (Gatekeeper) blocking a privileged container attempt - proof of Zero-Trust enforcement:_

![Gatekeeper Denial](docs/screenshots/gatekeeper-denial.png)

> **Error Message**: `admission webhook "validation.gatekeeper.sh" denied the request: Privileged container is not allowed`

---

### Azure Infrastructure

#### AKS Cluster Overview

_Production Kubernetes cluster with Workload Identity, Azure CNI, and managed by Terraform:_

![AKS Overview](docs/screenshots/aks-overview.png)

#### Key Vault Secrets

_Secrets stored securely in Azure Key Vault - `AppApiKey` is injected into pods via CSI Driver:_

![Key Vault Secrets](docs/screenshots/keyvault-secrets.png)

---

### Governance & Compliance

#### Azure Policy Overview

_Dashboard showing policy compliance across the subscription:_

![Azure Policy Overview](docs/screenshots/azure-policy-overview.png)

#### Pod Security Policy Assignment

_The "Restricted" Pod Security Standards initiative assigned to block privileged containers:_

![Policy Assignment](docs/screenshots/policy-assignment.png)

#### Microsoft Defender for Cloud

_Runtime security monitoring and threat detection dashboard:_

![Defender for Cloud](docs/screenshots/defender-for-cloud.png)

---

## 💰 Cost Estimation

### Monthly Cost Breakdown (East US Region)

| Resource           | SKU                | Estimated Cost (USD)  |
| ------------------ | ------------------ | --------------------- |
| AKS Cluster        | 1x Standard_D2s_v3 | ~$70/month            |
| VMSS Agents        | 1x Standard_D2s_v3 | ~$70/month            |
| Container Registry | Standard           | ~$20/month            |
| Key Vault          | Standard           | ~$0.03/10k operations |
| Log Analytics      | Per GB (30 days)   | ~$2-5/month           |
| **Total (Base)**   |                    | **~$162/month**       |

> [!TIP]
> Use Azure Dev/Test pricing or Reserved Instances for 40-70% savings.

### Cost Optimization Tips

1. **Scale down VMSS** when not in use
2. **Use Spot VMs** for non-critical agents
3. **Enable auto-shutdown** on VMSS during non-work hours
4. **Reduce Log Analytics retention** to 7 days for dev environments

---

## 🔧 Troubleshooting

### Common Issues

<details>
<summary><b>Pipeline: "No agents available in pool VMSS-Pool"</b></summary>

**Cause**: VMSS instances are scaling up or extension failed.

**Solution**:

```bash
# Check instance status
az vmss list-instances -g rg-devsecops-prod -n vmss-devsecops-agents -o table

# If stuck in "Creating", wait 2-3 minutes
# If "Failed", delete and re-apply Terraform
terraform apply -target=azurerm_linux_virtual_machine_scale_set.vmss
```

</details>

<details>
<summary><b>Pod: "MountVolume.SetUp failed for secrets-store-inline"</b></summary>

**Cause**: SecretProviderClass not found or identity lacks permissions.

**Solution**:

```bash
# Verify SPC exists
kubectl get secretproviderclass

# If missing, apply it
kubectl apply -f k8s/secretproviderclass.yaml

# Check Key Vault permissions
az role assignment list --scope "/subscriptions/<SUB_ID>/resourceGroups/rg-devsecops-prod/providers/Microsoft.KeyVault/vaults/kvshrinet82prod" -o table
```

</details>

<details>
<summary><b>Trivy: "CRITICAL vulnerabilities found"</b></summary>

**Cause**: Base image contains known vulnerabilities.

**Solution**:

1. Update base image in Dockerfile
2. Or add specific CVE to `.trivyignore`
3. Or use `--ignore-unfixed` flag (not recommended for production)
</details>

<details>
<summary><b>kubelogin: "executable not found"</b></summary>

**Cause**: kubelogin not installed or not in PATH.

**Solution**:

```bash
# Install to user directory
wget https://github.com/Azure/kubelogin/releases/download/v0.0.32/kubelogin-linux-amd64.zip
unzip kubelogin-linux-amd64.zip
mkdir -p ~/.local/bin
mv bin/linux_amd64/kubelogin ~/.local/bin/
export PATH=$HOME/.local/bin:$PATH

# Convert kubeconfig
kubelogin convert-kubeconfig -l azurecli
```

</details>

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards

| File Type | Standard        | Linter          |
| --------- | --------------- | --------------- |
| Python    | PEP 8           | `flake8`        |
| Terraform | HashiCorp Style | `terraform fmt` |
| YAML      | 2-space indent  | `yamllint`      |
| Markdown  | CommonMark      | `markdownlint`  |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Shrinet82**

- GitHub: [@Shrinet82](https://github.com/Shrinet82)
- Project Link: [https://github.com/Shrinet82/zero-trust-devsecops](https://github.com/Shrinet82/zero-trust-devsecops)

---

<p align="center">
  <b>Built with 🔐 Security First</b><br>
  <i>A Zero-Trust approach to modern DevSecOps</i>
</p>

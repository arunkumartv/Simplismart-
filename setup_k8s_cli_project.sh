#!/bin/bash

# Base project directory
mkdir -p k8s_deployment_cli/modules
mkdir -p k8s_deployment_cli/configs

# main.py
cat > k8s_deployment_cli/main.py << 'EOF'
import argparse
from modules import k8s_client, helm_installer, keda_installer, deployment_creator, health_checker

parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(dest="command")

parser_connect = subparsers.add_parser("connect")
parser_install = subparsers.add_parser("install-tools")

parser_deploy = subparsers.add_parser("deploy")
parser_deploy.add_argument("--name", required=True)
parser_deploy.add_argument("--image", required=True)
parser_deploy.add_argument("--cpu-request", required=True)
parser_deploy.add_argument("--cpu-limit", required=True)
parser_deploy.add_argument("--memory-request", required=True)
parser_deploy.add_argument("--memory-limit", required=True)
parser_deploy.add_argument("--port", type=int, required=True)

parser_status = subparsers.add_parser("status")
parser_status.add_argument("--name", required=True)

args = parser.parse_args()

if args.command == "connect":
    print(k8s_client.check_kubectl_connection())
elif args.command == "install-tools":
    helm_installer.install_helm()
    helm_installer.add_helm_repo()
    keda_installer.install_keda()
    keda_installer.verify_keda()
elif args.command == "deploy":
    deployment_creator.create_deployment(
        args.name, args.image, args.cpu_request, args.cpu_limit,
        args.memory_request, args.memory_limit, args.port
    )
elif args.command == "status":
    health_checker.check_deployment_status(args.name)
EOF

# k8s_client.py
cat > k8s_deployment_cli/modules/k8s_client.py << 'EOF'
import subprocess

def check_kubectl_connection():
    try:
        output = subprocess.check_output(["kubectl", "cluster-info"])
        return output.decode()
    except subprocess.CalledProcessError as e:
        raise Exception("Failed to connect to Kubernetes cluster") from e
EOF

# helm_installer.py
cat > k8s_deployment_cli/modules/helm_installer.py << 'EOF'
import subprocess

def install_helm():
    subprocess.run(["helm", "version"], check=True)

def add_helm_repo():
    subprocess.run(["helm", "repo", "add", "kedacore", "https://kedacore.github.io/charts"], check=True)
    subprocess.run(["helm", "repo", "update"], check=True)
EOF

# keda_installer.py
cat > k8s_deployment_cli/modules/keda_installer.py << 'EOF'
import subprocess

def install_keda():
    subprocess.run([
        "helm", "install", "keda", "kedacore/keda",
        "--namespace", "keda",
        "--create-namespace"
    ], check=True)

def verify_keda():
    subprocess.run(["kubectl", "get", "pods", "-n", "keda"])
EOF

# deployment_creator.py
cat > k8s_deployment_cli/modules/deployment_creator.py << 'EOF'
import subprocess

def create_deployment(name, image, cpu_req, cpu_lim, mem_req, mem_lim, port):
    yaml = f"""
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {name}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {name}
  template:
    metadata:
      labels:
        app: {name}
    spec:
      containers:
      - name: {name}
        image: {image}
        ports:
        - containerPort: {port}
        resources:
          requests:
            memory: "{mem_req}"
            cpu: "{cpu_req}"
          limits:
            memory: "{mem_lim}"
            cpu: "{cpu_lim}"
"""
    with open(f"{name}_deployment.yaml", "w") as f:
        f.write(yaml)
    subprocess.run(["kubectl", "apply", "-f", f"{name}_deployment.yaml"])
EOF

# health_checker.py
cat > k8s_deployment_cli/modules/health_checker.py << 'EOF'
import subprocess

def check_deployment_status(name):
    subprocess.run(["kubectl", "get", "deployment", name])
    subprocess.run(["kubectl", "describe", "deployment", name])
EOF

# values.yaml
echo "# Placeholder for Helm values if needed" > k8s_deployment_cli/configs/values.yaml

# README.md
cat > k8s_deployment_cli/README.md << 'EOF'
# Kubernetes CLI Automation Tool

This CLI tool automates Kubernetes cluster management, including:
- Tool installation (Helm, KEDA)
- Deployment of containerized applications
- Health checks for deployments

## Requirements
- Python 3.x
- `kubectl` configured for your cluster
- Helm CLI

## Usage
See `main.py` and run with `python3 main.py --help`
EOF

# requirements.txt
touch k8s_deployment_cli/requirements.txt

echo " Project created in 'k8s_deployment_cli/'"

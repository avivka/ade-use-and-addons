# Azure Deployment Environments - Enterprise Extensions

This repository contains enterprise-grade extensions for Azure Deployment Environments (ADE) including:

## Disclaimer
### This solution is set up and demoed for dev environments, make sure that you test all proper scenarios before upgrading this onto prod.
### You may consult avivkabesa@microsoft.com 

## 🚀 Features

### 1. Slack Integration for Environment Notifications
- **Logic App-based solution** for zero-maintenance event processing
- **Event Grid integration** with ADE lifecycle events
- **Slack notifications** with actionable buttons
- **Secure webhook handling** with proper authentication

### 2. Budget Governance & User-Based Cost Management
- **Azure Policy enforcement** for automatic budget creation
- **Per-user budget allocation** ($200 per user across all environments)
- **Cost monitoring** with automated alerts
- **Compliance reporting** for cost governance

### 3. GitHub Actions Environment Management
- **Centralized workflow** for environment provisioning
- **Mandatory expiration date** enforcement
- **Catalog-based environment selection**
- **Approval gates** for production environments

## 📁 Repository Structure

```
├── .github/workflows/           # GitHub Actions workflows
├── infrastructure/             # Terraform modules for Azure resources
│   ├── terraform/
│   │   ├── modules/           # Reusable Terraform modules
│   │   │   ├── logic-app-slack/   # Slack integration Logic App
│   │   │   ├── policy-governance/ # Azure Policy definitions
│   │   │   └── budget-governance/ # Budget and cost management
│   │   └── complete/          # Complete solution orchestration
├── scripts/                   # PowerShell automation scripts
└── docs/                     # Documentation and architecture diagrams
```

## 🛠️ Prerequisites

- Azure subscription with ADE enabled
- GitHub repository with Actions enabled
- Slack workspace with incoming webhook capability
- Terraform CLI (v1.7.0+)
- Azure CLI or PowerShell with Az module
- Appropriate Azure RBAC permissions

## 📖 Quick Start

1. **Deploy Infrastructure**: Run the Terraform modules in the `infrastructure/terraform/` folder
2. **Configure GitHub Actions**: Set up repository secrets and run the workflow
3. **Set up Slack Integration**: Configure webhook URL in Key Vault
4. **Apply Governance Policies**: Deploy budget and policy modules

## 🏗️ Architecture

The solution follows enterprise patterns:
- **Event-driven architecture** for real-time notifications
- **Policy-as-Code** for governance enforcement
- **Infrastructure-as-Code** using Terraform modules
- **GitOps principles** for environment management

## 🔐 Security Considerations

- Managed Identity authentication throughout
- Key Vault for sensitive configuration
- Least privilege access patterns
- Secure webhook validation
- Audit logging for all operations

## 📊 Monitoring & Observability

- Application Insights for Logic App telemetry
- Cost Management alerts and reports
- GitHub Actions workflow monitoring
- Azure Policy compliance reporting

## 🤝 Contributing

This solution is designed for enterprise customers with specific ADE requirements. Please follow the established patterns when extending functionality.

---

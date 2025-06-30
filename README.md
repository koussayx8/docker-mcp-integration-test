# Advanced GitHub MCP & Docker CI/CD Integration

This project demonstrates a production-ready CI/CD pipeline integrating GitHub MCP and Docker with comprehensive automation, featuring:

## ✅ Current Status (June 30, 2025)

**Pipeline Status**: 🟢 **FULLY OPERATIONAL**
- All container name issues resolved
- Robust error handling implemented
- GitHub Container Registry publishing working
- Complete end-to-end automation functional

## Core Features

- **✅ Automated Docker Build**: Build Docker images from the current Git branch with health checks
- **✅ Container Deployment & Testing**: Deploy and test containers with comprehensive validation
- **✅ GitHub Actions CI/CD**: Complete pipeline with build, test, deploy stages
- **✅ GitHub Container Registry**: Automatic image publishing to ghcr.io
- **✅ Container Performance Monitoring**: Monitor running containers with detailed logs
- **✅ Integrated MCP Workflow**: Seamless GitHub and Docker operations via Copilot Chat
- **✅ VS Code Tasks Integration**: One-click automation for all operations

## Prerequisites

1. **VS Code** with GitHub Copilot extension
2. **Docker Desktop** installed and running
3. **GitHub MCP** configured in VS Code settings
4. **Docker MCP** configured in VS Code settings
5. **Git** configured with GitHub authentication

## Project Structure

```
Testing Mcp/
├── .github/
│   ├── workflows/
│   │   ├── ci-cd.yml             # Main CI/CD pipeline
│   │   └── ci-cd-fixed.yml       # Fixed version reference
│   └── copilot-instructions.md   # Copilot instructions
├── .vscode/
│   └── tasks.json                # VS Code tasks for automation
├── docker/
│   ├── Dockerfile                # Optimized multi-stage build
│   ├── docker-compose.yml        # Multi-container setup
│   ├── nginx.conf                # Nginx configuration
│   └── prometheus.yml            # Monitoring configuration
├── src/
│   ├── app.py                    # Flask application with health endpoints
│   └── requirements.txt          # Python dependencies
├── scripts/
│   ├── build.ps1                 # Build automation script
│   ├── deploy.ps1                # Deployment script
│   ├── test.ps1                  # Testing script
│   └── monitor.ps1               # Monitoring script
├── tests/
│   └── test_app.py               # Comprehensive test suite
├── PIPELINE_COMPLETE.md          # Complete pipeline documentation
└── README.md                     # This file
```

## Quick Start

1. **Clone and Open**: Clone this repository and open in VS Code
2. **Verify Docker**: Ensure Docker Desktop is running
3. **Test Pipeline**: Push to master branch to trigger full CI/CD
4. **Monitor Results**: Check GitHub Actions and Container Registry
5. **Local Development**: Use VS Code tasks for local testing

### 🚀 One-Click Operations

**Complete Pipeline**:
- `Ctrl+Shift+P` → "Tasks: Run Task" → "Complete Build-Test-Deploy Pipeline"

**Individual Operations**:
- Build: "Build Docker Image"
- Deploy: "Deploy Container" 
- Test: "Run Tests"
- Monitor: "Monitor Container"

## Usage

### Via Copilot Chat

Ask Copilot to:
- "Build a Docker image from the current branch"
- "Deploy and test the container"
- "Create a PR if tests pass"
- "Monitor container performance"

### Via VS Code Tasks

- **Ctrl+Shift+P** → "Tasks: Run Task"
- Select from available tasks:
  - Build Docker Image
  - Deploy Container
  - Run Tests
  - Monitor Containers
  - Create GitHub PR

## MCP Server Configuration

Ensure your VS Code `settings.json` includes:

```json
{
  "github.copilot.chat.experimental.mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your_token_here"
      }
    },
    "docker": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "--privileged", "-v", "/var/run/docker.sock:/var/run/docker.sock", "mcp/docker"],
      "sampling": {
        "allowedModels": ["gpt-4o", "gpt-4", "claude-3-5-sonnet-20241022"]
      }
    }
  }
}
```

## Pipeline Status & Endpoints

### 🔗 GitHub Repository
- **Repository**: [koussayx8/docker-mcp-integration-test](https://github.com/koussayx8/docker-mcp-integration-test)
- **Actions**: [CI/CD Workflow Runs](https://github.com/koussayx8/docker-mcp-integration-test/actions)
- **Registry**: [GitHub Container Registry](https://github.com/koussayx8/docker-mcp-integration-test/pkgs/container/mcp-integration-test)

### 🐳 Container Endpoints
- `http://localhost:8000/` - Application home
- `http://localhost:8000/health` - Health check endpoint
- `http://localhost:8000/api/info` - Application information
- `http://localhost:8000/api/test` - Test endpoint
- `http://localhost:8000/metrics` - Prometheus metrics

### 📊 Recent Improvements
- **Container naming consistency** using environment variables
- **Enhanced error handling** with detailed exception reporting
- **Improved container logs** with conditional collection
- **Robust cleanup procedures** for reliable testing
- **Simplified configuration** for maximum stability

## Troubleshooting

### ✅ Pipeline Issues (Recently Fixed)
- **Container name errors**: ✅ Resolved with CONTAINER_NAME env variable
- **Health check failures**: ✅ Enhanced with better error handling
- **Log collection errors**: ✅ Added conditional log checks

### Docker Issues
- Ensure Docker Desktop is running
- Verify sufficient disk space for images
- Check port 8000 is not in use

### GitHub Actions Issues
- Check workflow status in Actions tab
- Verify repository permissions
- Review workflow logs for details

### VS Code Integration
- Restart VS Code if tasks are unresponsive
- Check task definitions in .vscode/tasks.json
- Verify PowerShell execution policy on Windows

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with both MCPs
5. Submit a pull request

## License

MIT License - see LICENSE file for details

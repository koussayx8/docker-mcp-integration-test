# Advanced GitHub MCP & Docker MCP Integration

This project demonstrates advanced integration between GitHub MCP and Docker MCP in VS Code, featuring:

## Features

- **Automated Docker Build**: Build Docker images from the current Git branch
- **Container Deployment & Testing**: Deploy and test containers automatically
- **GitHub Pull Request Creation**: Automatically create PRs when tests pass
- **Container Performance Monitoring**: Monitor running containers
- **Integrated MCP Workflow**: Seamless GitHub and Docker operations via Copilot Chat

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
│   └── copilot-instructions.md    # Copilot instructions
├── .vscode/
│   └── tasks.json                 # VS Code tasks
├── docker/
│   ├── Dockerfile                 # Docker image definition
│   ├── docker-compose.yml         # Multi-container setup
│   └── nginx.conf                 # Nginx configuration
├── src/
│   ├── app.py                     # Sample Python application
│   └── requirements.txt           # Python dependencies
├── scripts/
│   ├── build.ps1                  # Build automation script
│   ├── deploy.ps1                 # Deployment script
│   ├── test.ps1                   # Testing script
│   └── monitor.ps1                # Monitoring script
├── tests/
│   └── test_app.py                # Application tests
└── README.md                      # This file
```

## Quick Start

1. **Open in VS Code**: Open this folder in VS Code
2. **Test MCP Integration**: Use Copilot Chat to test GitHub and Docker MCP
3. **Run Build Task**: Execute the build task from VS Code Command Palette
4. **Monitor Workflow**: Watch the automated process in action

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

## Workflow Overview

1. **Branch Detection**: Automatically detect current Git branch
2. **Docker Build**: Build image tagged with branch name
3. **Container Deploy**: Start container with health checks
4. **Automated Testing**: Run test suite against deployed container
5. **Performance Monitoring**: Collect container metrics
6. **GitHub Integration**: Create PR if all tests pass
7. **Cleanup**: Stop and remove test containers

## Troubleshooting

### Docker MCP Issues
- Ensure Docker Desktop is running
- Verify Docker MCP plugin is installed
- Check VS Code settings.json configuration

### GitHub MCP Issues
- Verify GitHub token permissions
- Check network connectivity
- Ensure repository access rights

### General Issues
- Restart VS Code if MCP servers are unresponsive
- Check VS Code Developer Console for error messages
- Verify all prerequisites are installed

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with both MCPs
5. Submit a pull request

## License

MIT License - see LICENSE file for details

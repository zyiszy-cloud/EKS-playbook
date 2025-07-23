# Contributing to EKS/TKE Serverless Performance Testing Playbook

Thank you for your interest in contributing to this project! We welcome contributions from the community.

## 🚀 Getting Started

### Prerequisites

- Kubernetes cluster (1.20+)
- kubectl configured
- Basic understanding of Argo Workflow
- Familiarity with TKE Serverless (for serverless-related contributions)

### Development Setup

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/your-username/EKS-playbook.git
   cd EKS-playbook
   ```

2. **Set up development environment**
   ```bash
   # Add upstream remote
   git remote add upstream https://github.com/wi1123/EKS-playbook.git
   
   # Create development branch
   git checkout -b feature/your-feature-name
   ```

3. **Test your setup**
   ```bash
   # Make script executable
   chmod +x run-serverless-tests.sh
   
   # Run tests to verify setup
   ./run-serverless-tests.sh --help
   ```

## 📝 How to Contribute

### Types of Contributions

1. **New Test Scenarios**
   - Add new performance testing workflows
   - Enhance existing test scenarios
   - Add support for new cloud providers

2. **Bug Fixes**
   - Fix issues in existing workflows
   - Improve error handling
   - Fix documentation errors

3. **Documentation**
   - Improve README files
   - Add usage examples
   - Translate documentation

4. **Tools and Scripts**
   - Enhance automation scripts
   - Add monitoring capabilities
   - Improve CI/CD integration

### Contribution Process

1. **Create an Issue**
   - Describe the problem or enhancement
   - Provide context and use cases
   - Wait for maintainer feedback

2. **Develop Your Changes**
   - Follow coding standards
   - Write clear commit messages
   - Test your changes thoroughly

3. **Submit a Pull Request**
   - Reference the related issue
   - Provide detailed description
   - Include testing instructions

## 🧪 Testing Guidelines

### Before Submitting

1. **Test Your Changes**
   ```bash
   # Test new workflows
   kubectl create -f playbook/workflow/your-new-workflow.yaml
   
   # Test automation scripts
   ./run-serverless-tests.sh your-test-type
   ```

2. **Validate YAML Files**
   ```bash
   # Check YAML syntax
   kubectl apply --dry-run=client -f playbook/workflow/your-workflow.yaml
   ```

3. **Test Documentation**
   - Verify all links work
   - Check formatting
   - Test code examples

### Test Environment

- Use non-production clusters for testing
- Ensure proper cleanup after tests
- Document any special requirements

## 📋 Coding Standards

### YAML Files

```yaml
# Use consistent indentation (2 spaces)
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: descriptive-name
  namespace: tke-chaos-test
spec:
  # Clear parameter descriptions
  arguments:
    parameters:
    - name: parameter-name
      value: "default-value"
      description: "Clear description of parameter purpose"
```

### Shell Scripts

```bash
#!/bin/bash
# Use strict error handling
set -e

# Clear function names and comments
function descriptive_function_name() {
    local param1="$1"
    # Implementation
}

# Use consistent logging
log_info "Informational message"
log_error "Error message"
```

### Documentation

- Use clear, concise language
- Include code examples
- Provide troubleshooting tips
- Keep README files up to date

## 🔄 Pull Request Process

### PR Requirements

1. **Description**
   - Clear title and description
   - Reference related issues
   - List changes made

2. **Testing**
   - Include test results
   - Provide testing instructions
   - Document any breaking changes

3. **Documentation**
   - Update relevant documentation
   - Add usage examples
   - Update changelog if needed

### Review Process

1. **Automated Checks**
   - YAML validation
   - Link checking
   - Basic syntax validation

2. **Manual Review**
   - Code quality review
   - Functionality testing
   - Documentation review

3. **Approval and Merge**
   - Maintainer approval required
   - Squash and merge preferred
   - Update version tags if needed

## 🐛 Reporting Issues

### Bug Reports

Include the following information:

```markdown
**Environment:**
- Kubernetes version:
- TKE/EKS version:
- Argo Workflow version:

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happened

**Logs:**
```
Relevant log output
```

**Additional Context:**
Any other relevant information
```

### Feature Requests

```markdown
**Feature Description:**
Clear description of the proposed feature

**Use Case:**
Why is this feature needed?

**Proposed Solution:**
How should this be implemented?

**Alternatives Considered:**
Other approaches considered

**Additional Context:**
Any other relevant information
```

## 📚 Resources

### Documentation
- [Argo Workflow Documentation](https://argoproj.github.io/argo-workflows/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [TKE Serverless Documentation](https://cloud.tencent.com/document/product/457)

### Tools
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Argo CLI](https://github.com/argoproj/argo-workflows/releases)
- [YAML Validator](https://codebeautify.org/yaml-validator)

## 🤝 Community

### Communication Channels
- GitHub Issues: Bug reports and feature requests
- GitHub Discussions: General questions and discussions
- Pull Requests: Code contributions

### Code of Conduct
- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow GitHub's community guidelines

## 🏆 Recognition

Contributors will be recognized in:
- README acknowledgments
- Release notes
- Contributor list

Thank you for contributing to make this project better! 🎉
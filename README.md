# 📦 Bkstar123.PSModuleScaffolding

**Bkstar123.PSModuleScaffolding** is a lightweight PowerShell module that helps you quickly scaffold a standard structure for a new PowerShell module project. It creates all the essential folders and files so you can start building your module following best practices right away.

---

## 🚀 Features

### Core Features
- Scaffold a clean and standard module structure: `Private`, `Public`, `Class`, and `Tests` folders
- Auto-generate `.psm1` and `.psd1` files
- Automatically exports public functions from the `Public` folder

### Template System
- Pre-built templates for different module types:
  - Azure module template with Azure SDK integration
  - AWS module template with AWS SDK integration
  - More templates coming soon
- Customizable templates with placeholders
- Easy to extend with your own templates

### Documentation
- Automatic documentation generation using PlatyPS
- Generates markdown help files for all functions
- Creates MAML help files for PowerShell help system
- Generates module landing page with installation instructions
- Creates external help files in multiple languages

### Testing Framework
- Integrated with Pester 5.0 testing framework
- Automatically generates test files for each public function
- Creates GitHub Actions workflow for continuous testing
- Supports cross-platform testing (Windows, Linux, macOS)
- Code coverage reporting

### Quality Control
- Built-in PSScriptAnalyzer integration
- Automated code quality checks
- HTML quality reports generation
- Automatic fixing of common issues
- Best practices enforcement

### Version Management
- Semantic versioning support
- Automatic CHANGELOG.md generation
- Git tag management
- Version history tracking

### Publishing
- PowerShell Gallery publishing support
- Version conflict detection
- Automated manifest validation
- GitHub release creation
- Publishing workflow automation

---

## 📥 Installation

You can install this module either from the PowerShell Gallery (if published) or directly from GitHub.

### From PowerShell Gallery

```powershell
Install-Module -Name Bkstar123.PSModuleScaffolding -Scope CurrentUser
Import-Module Bkstar123.PSModuleScaffolding
```

### From GitHub

```powershell
git clone https://github.com/bkstar123/Bkstar123.PSModuleScaffolding.git
Import-Module ./Bkstar123.PSModuleScaffolding/Bkstar123.PSModuleScaffolding.psd1
```

---

## 🛠️ Usage

### Basic Module Creation
```powershell
New-BksPSModule -ModuleName "YourModuleName"
```

### Create Module from Template
```powershell
New-BksPSModuleFromTemplate -ModuleName "MyAzureModule" -TemplateType "Azure"
```

### Generate Documentation
```powershell
New-BksPSModuleDocumentation -ModulePath ".\MyModule"
```

### Create and Run Tests
```powershell
New-BksPSModuleTest -ModulePath ".\MyModule" -RunTests -GenerateCodeCoverage
```

### Check Code Quality
```powershell
Test-BksPSModuleQuality -ModulePath ".\MyModule" -FixProblems
```

### Update Module Version
```powershell
Update-BksPSModuleVersion -ModulePath ".\MyModule" -VersionType "Minor" -GenerateChangelog
```

### Publish Module
```powershell
Publish-BksPSModule -ModulePath ".\MyModule" -NuGetApiKey "your-api-key"
```

---

## 📁 Project Structure

When you create a new module, it will generate the following structure:

```
YourModuleName/
├── Public/           # Public functions that will be exported
├── Private/          # Internal helper functions
├── Class/           # Class definitions
├── Tests/           # Pester test files
├── docs/            # Documentation
├── en-US/           # Localized help files
├── .github/         # GitHub workflows
├── analysis/        # Code analysis reports
├── CHANGELOG.md     # Version history
├── YourModuleName.psm1  # Module file
└── YourModuleName.psd1  # Module manifest
```

---

## 🤝 Contributing

We welcome contributions from the community!

1. Fork the repository
2. Create a new branch for your feature or fix
3. Write tests for your changes
4. Ensure code quality with PSScriptAnalyzer
5. Update documentation if needed
6. Submit a Pull Request

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

---

## 🌟 Thanks

Thanks for checking out **Bkstar123.PSModuleScaffolding**! If you find this project useful, please consider:

- Giving it a ⭐ on GitHub
- Contributing to the project
- Sharing it with others

---

## 📚 Documentation

Full documentation is available in the [docs](./docs) folder.

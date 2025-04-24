
# 📦 Bkstar123.PSModuleScaffolding

**Bkstar123.PSModuleScaffolding** is a lightweight PowerShell module that helps you quickly scaffold a standard structure for a new PowerShell module project. It creates all the essential folders and files so you can start building your module following best practices right away.

---

## 🚀 Features

- Scaffold a clean and standard module structure: `Private`, `Public`, `Class`, and `Tests` folders.
- Auto-generate `.psm1` and `.psd1` files.
- Automatically exports public functions from the `Public` folder.
- Lightweight, customizable, and easy to extend.

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

Once installed and imported, you can run the following command to scaffold a new module:

```powershell
New-BksPSModule -ModuleName "YourModuleName"
```

This will generate the following structure:

```
YourModuleName/
├── Private/
├── Public/
├── Class/
├── Tests/
├── YourModuleName.psm1
└── YourModuleName.psd1
```

- `Public/` contains public functions that will be exported automatically.
- `Private/` contains internal helper functions.
- `Class/` holds class definitions (if needed).
- `Tests/` contains tests (Pester recommended).

---

## 🤝 Contributing

We welcome contributions from the community!

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Commit and push your changes.
4. Open a Pull Request for review.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

---

## 🌟 Thanks

Thanks for checking out **Bkstar123.PSModuleScaffolding**! If you find this project useful, please consider giving it a ⭐ on GitHub.

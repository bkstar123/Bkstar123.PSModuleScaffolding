# Bkstar123.PSModuleScaffolding
Bkstar123.PSModuleScaffolding is a reusable PowerShell module. Its purpose is to help you to quickly scaffold a PS module structure.

---

## 📦 Usage

```powershell
Install-Module Bkstar123.PSModuleScaffolding  
Import-Module Bkstar123.PSModuleScaffolding  
New-BksPSModule -ModuleName "Your_module_name"  
```

This command will scaffold your module structure into 4 folders **Private**, **Public**, **Class**, **Tests**, a root module file **.psm1**, and a module manifest file **.psd1**.  

The **.psm1** file will do neccessary setup for your module, and export all public functions in **Public** folder for use. This is a basic setup, and you will still be required to update it for other types of exports such as variable, cmdlet and alias. 

+ Folder **Public** is for those components that you want to export for module users to use in their scripts.  

+ Folder **Private** is for those components that are internally used inside the module, and are not available for module users to use directly.  

+ Folder **Class** is for class definitions that your module will use.  

+ Folder **Tests** is for unit testing cases that you want to implement for your module.  

Additionally, it also generate skeleton *.gitignore*, *README.md*, *LICENSE* files
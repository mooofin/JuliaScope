# Debian Package Control File for JuliaScope

This document explains the `control` file used to package JuliaScope as a `.deb` package.

## **Control File Structure**
The `control` file defines metadata required for building and installing the Debian package.

### **📄 Example `control` File**
```plaintext
Package: juliascope
Version: 1.0
Section: utils
Priority: optional
Architecture: all
Depends: julia, curl
Description: JuliaScope - A subdomain enumeration tool written in Julia.
 This tool performs passive subdomain enumeration using crt.sh.
 It fetches subdomains for a given domain and prints the results.

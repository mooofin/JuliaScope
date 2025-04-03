# JuliaScope - Advanced Subdomain Enumeration with Julia

JuliaScope is a high-performance, multithreaded subdomain enumeration tool leveraging the power of Julia. It queries `crt.sh`, an open-source certificate transparency log database, to extract subdomains efficiently. Designed for penetration testers, bug bounty hunters, and cybersecurity researchers, JuliaScope provides an optimized solution for domain reconnaissance.

## 🚀 Features
- **Multithreading**: Parallelized HTTP requests for blazing-fast enumeration.
- **Optimized Parsing**: Uses `JSON3.jl` for high-performance JSON handling.
- **Colored CLI Output**: Enhanced terminal aesthetics with `Crayons.jl`.
- **Efficient Filtering**: Removes wildcard and duplicate subdomains.
- **Lightweight & Fast**: Built in Julia for superior speed and low overhead.

## 🛠 Prerequisites
- [Install Julia](https://julialang.org/downloads/)
- Ensure internet connectivity for API queries.

## 📌 Installation
1. Clone the repository:
   ```sh
   git clone https://github.com/yourusername/JuliaScope.git
   cd JuliaScope
   ```
2. Install required Julia packages:
   ```julia
   using Pkg
   Pkg.add(["HTTP", "JSON3", "Crayons", "ThreadsX"])
   ```

## 🔧 Usage
1. Launch the Julia REPL:
   ```sh
   julia
   ```
2. Navigate to the project directory in Julia:
   ```julia
   cd("path/to/JuliaScope")
   ```
3. Load the script:
   ```julia
   include("subdomain.jl")
   ```
4. Enter a domain when prompted, and retrieve subdomains instantly.

## 🔜 Upcoming Enhancements
- **Standalone CLI Tool**: Convert JuliaScope into a command-line binary for Linux & Windows.
- **Shodan Integration**: Cross-reference subdomains with Shodan for deeper reconnaissance.
- **Expanded Multithreading**: Further optimize performance via Julia’s `Threads.@spawn`.

## 🛡 Disclaimer
JuliaScope is intended for legal security research and educational purposes only. Unauthorized usage against domains you do not own is strictly prohibited.

---
🖥 **Author**: Muffin | 🌐 *Cybersecurity & AI Enthusiast*


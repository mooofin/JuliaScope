# JuliaScope

JuliaScope is a fast, parallelized subdomain enumeration and vulnerability scanning tool written in Julia. It combines passive and active techniques to discover subdomains and can scan them for common web vulnerabilities. Inspired by tools like subfinder, JuliaScope is designed for security researchers, bug bounty hunters, and network defenders.

---

## Features

- **Subdomain Enumeration**
  - Passive: Uses crt.sh (Certificate Transparency logs)
  - Active: DNS brute-forcing with a customizable wordlist
- **Vulnerability Scanning**
  - Scans discovered domains/subdomains for common web vulnerabilities (SQLi, XSS, RCE, etc.) using pattern matching
- **Parallel Processing**
  - Utilizes Julia's multithreading and multiprocessing for speed
- **Command-Line Interface**
  - Flexible options for different scanning modes
- **Colorful, User-Friendly Output**

---

## Installation

1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd JuliaScope
   ```
2. **Install Julia (if not already):**
   - [Download Julia](https://julialang.org/downloads/)
3. **Install dependencies:**
   JuliaScope will auto-install required packages on first run, but you can pre-install them for speed:
   ```julia
   import Pkg
   Pkg.add(["HTTP", "JSON3", "Crayons", "ThreadsX", "ArgParse"])
   ```

---

## Usage

Run JuliaScope from the command line:

```sh
julia src/juliascope.jl [option] <domain>
```

### Options

| Option         | Description                                                        |
| --------------|--------------------------------------------------------------------|
| `-s`          | Search for subdomains (crt.sh + brute-force)                       |
| `-dns`        | Only brute-force subdomains using wordlist                         |
| `-ss`         | Scan domain and subdomains for vulnerabilities                     |
| `-h`          | Show help menu                                                     |

### Examples

- **Find subdomains using all methods:**
  ```sh
  julia src/juliascope.jl -s example.com
  ```
- **Brute-force subdomains only:**
  ```sh
  julia src/juliascope.jl -dns example.com
  ```
- **Scan for vulnerabilities:**
  ```sh
  julia src/juliascope.jl -ss example.com
  ```
- **Show help:**
  ```sh
  julia src/juliascope.jl -h
  ```

---

## Wordlist

- The brute-force mode uses a file named `wordlist.txt` in the project root.
- You can customize this file with your own subdomain prefixes (one per line):
  ```
  www
  mail
  admin
  test
  dev
  api
  ...
  ```

---

## Vulnerability Scanning

- The `-ss` option scans each found (sub)domain for common web vulnerabilities using pattern matching.
- Vulnerabilities checked include:
  - SQL Injection
  - Cross-Site Scripting (XSS)
  - Directory Traversal
  - Exposed Admin Panels
  - Misconfigurations
  - Sensitive Files
  - Information Disclosure
  - SSRF
  - Remote Code Execution (RCE)
- Patterns are defined in the `VULNERABILITY_PATTERNS` dictionary in `src/juliascope.jl`.

---

## Dependencies

- Julia 1.6+
- [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl)
- [JSON3.jl](https://github.com/quinnj/JSON3.jl)
- [Crayons.jl](https://github.com/KristofferC/Crayons.jl)
- [ThreadsX.jl](https://github.com/tkf/ThreadsX.jl)
- [ArgParse.jl](https://github.com/carlobaldassi/ArgParse.jl)

All dependencies are open source and installable via Julia's package manager.

---

## Contribution

Contributions, bug reports, and feature requests are welcome!

1. Fork the repository
2. Create a new branch (`git checkout -b feature-xyz`)
3. Make your changes
4. Commit and push (`git commit -am 'Add new feature' && git push`)
5. Open a pull request

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Disclaimer

This tool is for educational and authorized security testing purposes only. Do not use against systems you do not own or have explicit permission to test.

---

## Running JuliaScope: Command Line vs. Julia REPL

JuliaScope is designed to be run as a command-line tool, not as an interactive REPL script.

### Recommended: Command Line Usage

Open a terminal (Command Prompt, PowerShell, or a Julia REPL in shell mode with `;`) and run:

```sh
julia src/juliascope.jl -s example.com
```

or, if you are in the `src` directory:

```sh
julia juliascope.jl -s example.com
```

### Running from the Julia REPL (Not Recommended)

If you run `include("juliascope.jl")` in the Julia REPL, the script will only print the help menu and exit unless you set `ARGS` manually. For example:

```julia
ARGS = ["-s", "example.com"]
include("juliascope.jl")
```

### Why You Might See No Output
- If you run `include("juliascope.jl")` with no arguments, the script sees an empty `ARGS` array, prints the help (which may not show in the REPL), and exits.
- The main logic is only triggered by command-line arguments.

**For best results, always run JuliaScope from your system's command line with the desired options.**

---

## Example Usage: Muffin Runs JuliaScope

Suppose Muffin has cloned JuliaScope to `C:\Users\Muffin\JuliaScope`. To enumerate subdomains for `example.com`, Muffin would:

```sh
cd C:\Users\Muffin\JuliaScope
julia src/juliascope.jl -s example.com
```

This will run JuliaScope using both crt.sh and DNS brute-forcing, and print all discovered subdomains for `example.com`.

---

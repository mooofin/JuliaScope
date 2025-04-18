# JuliaScope

```
⣿⣿⣿⣿⣿⣿⠿⣛⣿⣿⣿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⢿⣫⠖⠛⢁⠁⢠⣶⢆⣿⣿⣿⣿⣿⣶⣦⣭⡛⠿⣿⣿⣿⣿⣿
⣿⡟⣵⠋⢐⣯⠀⠌⢠⡿⠟⣸⣯⣽⣿⡭⢟⢿⣿⡿⣿⡷⣌⠪⡻⣿⣿
⢯⡾⠃⡆⠃⢀⠔⣐⡵⢞⣴⢿⣫⣵⣯⣾⣿⣳⢹⢻⣿⣿⡞⡧⡹⣞⣿
⣿⡅⡀⠁⢀⢐⣸⣭⢾⣫⣾⣿⣿⣿⣿⡿⣱⣳⣷⡁⣿⣿⣿⣱⢣⢹⣾
⣿⢃⣾⡏⢯⣾⢟⣵⣿⣿⣿⣿⣿⡿⢋⣜⣵⣿⣿⣿⢸⣿⣿⡏⡟⡈⣿
⡟⣸⡿⢱⡼⣳⣿⣿⣿⣿⣿⠿⢋⡴⣢⣾⣭⣻⣿⣿⣾⣿⣿⣷⣧⡇⣿
⠃⣋⣴⡇⣾⣿⣿⣿⠿⠛⢕⢕⣽⣾⡻⠛⠋⠛⠻⢿⡇⣿⣿⣿⣿⡇⣿
⡇⣿⣿⡇⡍⠩⢷⠠⣔⣎⢱⣿⣿⣿⣾⠤⣼⣬⢤⣌⣻⣿⣿⡿⡿⡇⣿
⣧⢹⡏⡇⢦⢶⣿⣖⣭⣥⣿⣿⣿⣿⣿⣧⣭⣥⣿⣿⢻⣏⣿⣇⡇⡇⢿
⣿⢸⡇⣧⡐⣨⡻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢟⣫⢸⢯⣿⢻⢳⣧⢸
⣿⡀⣷⢻⠣⢸⣿⣶⣭⣟⠛⢿⠿⠟⢛⡉⢁⣾⣿⣿⣾⣸⡟⣛⣾⣿⣿
⣿⣷⣀⣼⣠⡬⣿⡿⡩⠀⠀⣀⢄⣬⠀⠀⠒⣤⣭⠇⠏⣟⣳⢟⣿⣿⣿
⣿⣿⣿⣿⣟⠀⠀⠄⣡⡆⠆⠰⡤⢊⣧⡤⠈⠛⣛⠀⠀⣙⣽⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣶⣧⣿⣿⡉⠑⣾⣟⣻⡇⣈⣭⣭⣶⣿⣿⣿⣿⣿⣿⣿
```

JuliaScope is a cybersecurity tool written in Julia for subdomain enumeration and vulnerability scanning. It uses crt.sh to find subdomains and scans them for common vulnerabilities.

## Features

- Subdomain discovery using certificate transparency logs
- Scans for SQL injection, XSS, directory traversal, admin panels, misconfigurations, and possible data leaks
- Parallel scanning using Julia's Distributed module
- Interactive command-line interface
- Color-coded terminal output

## Requirements

- Julia 1.6 or later
- Internet connection

## Installation

Clone the repository:

```
git clone https://github.com/yourusername/juliascope.git
cd juliascope
```

Run the script:

```
julia juliascope.jl
```

The script installs required Julia packages automatically:
HTTP, JSON3, Crayons, and Distributed (built-in)

## How to Use

Run the script:

```
julia juliascope.jl
```

Follow the prompts:
- Enter a domain (e.g. example.com)
- View discovered subdomains
- Select which ones to scan
- View results

## Detected Vulnerabilities

- SQL Injection: looks for patterns like ' OR '1'='1 and UNION SELECT
- Cross-Site Scripting (XSS): checks for <script>, alert(), onerror, etc.
- Directory Traversal: detects ../ and access to hidden files
- Exposed Admin Interfaces: flags common paths like /admin or /wp-admin
- Misconfigurations: checks for headers like Server or X-Powered-By
- Data Leakage: warns on large response sizes over 100KB

## Example

```
Enter the domain to search subdomains for: example.com

Found 5 subdomains:
1. www.example.com
2. api.example.com

Select subdomains to scan (comma-separated or 'all'):
```

## Contributing

To contribute, open an issue or submit a pull request.

## License

MIT License

## Disclaimer

Use this tool only on domains you have permission to test. It is intended for educational and authorized use only.



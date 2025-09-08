import Pkg
# --- Ensure Required Packages Are Installed ---
function ensure_packages()
    required = ["HTTP", "JSON3", "Crayons", "ThreadsX", "ArgParse"]
    installed = keys(Pkg.installed())
    to_install = filter(pkg -> !(pkg in installed), required)
    if !isempty(to_install)
        println("Installing missing packages: ", join(to_install, ", "))
        Pkg.add(to_install)
    end
end
ensure_packages()

using HTTP, JSON3, Crayons
using Distributed
using Sockets
using ArgParse
using ThreadsX

# Ensure there are workers for parallelism
if nprocs() == 1
    addprocs(4)  # Add 4 workers for parallel processing ? test this !
end

@everywhere using HTTP, JSON3

# --- Configuration ---
const BOX_WIDTH = 38
const TEXT_LINES = [ 
    # ASCII Art
    "⣿⣿⣿⣿⣿⣿⠿⣛⣿⣿⣿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
    "⣿⣿⣿⢿⣫⠖⠛⢁⠁⢠⣶⢆⣿⣿⣿⣿⣿⣶⣦⣭⡛⠿⣿⣿⣿⣿⣿",
    "⣿⡟⣵⠋⢐⣯⠀⠌⢠⡿⠟⣸⣯⣽⣿⡭⢟⢿⣿⡿⣿⡷⣌⠪⡻⣿⣿",
    "⢯⡾⠃⡆⠃⢀⠔⣐⡵⢞⣴⢿⣫⣵⣯⣾⣿⣳⢹⢻⣿⣿⡞⡧⡹⣞⣿",
    "⣿⡅⡀⠁⢀⢐⣸⣭⢾⣫⣾⣿⣿⣿⣿⡿⣱⣳⣷⡁⣿⣿⣿⣱⢣⢹⣾",
    "⣿⢃⣾⡏⢯⣾⢟⣵⣿⣿⣿⣿⣿⡿⢋⣜⣵⣿⣿⣿⢸⣿⣿⡏⡟⡈⣿",
    "⡟⣸⡿⢱⡼⣳⣿⣿⣿⣿⣿⠿⢋⡴⣢⣾⣭⣻⣿⣿⣾⣿⣿⣷⣧⡇⣿",
    "⠃⣋⣴⡇⣾⣿⣿⣿⠿⠛⢕⢕⣽⣾⡻⠛⠋⠛⠻⢿⡇⣿⣿⣿⣿⡇⣿",
    "⡇⣿⣿⡇⡍⠩⢷⠠⣔⣎⢱⣿⣿⣿⣾⠤⣼⣬⢤⣌⣻⣿⣿⡿⡿⡇⣿",
    "⣧⢹⡏⡇⢦⢶⣿⣖⣭⣥⣿⣿⣿⣿⣿⣧⣭⣥⣿⣿⢻⣏⣿⣇⡇⡇⢿",
    "⣿⢸⡇⣧⡐⣨⡻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢟⣫⢸⢯⣿⢻⢳⣧⢸",
    "⣿⡀⣷⢻⠣⢸⣿⣶⣭⣟⠛⢿⠿⠟⢛⡉⢁⣾⣿⣿⣾⣸⡟⣛⣾⣿⣿",
    "⣿⣷⣀⣼⣠⡬⣿⡿⡩⠀⠀⣀⢄⣬⠀⠀⠒⣤⣭⠇⠏⣟⣳⢟⣿⣿⣿",
    "⣿⣿⣿⣿⣟⠀⠀⠄⣡⡆⠆⠰⡤⢊⣧⡤⠈⠛⣛⠀⠀⣙⣽⣿⣿⣿⣿",
    "⣿⣿⣿⣿⣿⣿⣶⣧⣿⣿⡉⠑⣾⣟⣻⡇⣈⣭⣭⣶⣿⣿⣿⣿⣿⣿⣿",

    # Meta text (better ascii need) 
    "Author: Muffin"
]

const BOX_CHARS = Dict(
    :topLeft => '╔', :topRight => '╗',
    :bottomLeft => '╚', :bottomRight => '╝',
    :horizontal => '═', :vertical => '║'
)
const SPINNER_CHARS = ['|', '/', '-', '\\']
const CRAYON_STYLE = Crayons.crayon"bold blue"

const VULNERABILITY_PATTERNS = Dict(
    :sql_injection => [
        "' OR '1'='1",
        "\" OR \"1\"=\"1",
        "' OR 1=1--",
        "' OR 1=1#",
        "' OR 'a'='a",
        "1' OR '1'='1' --",
        "'; DROP TABLE",
        "'; EXEC xp_cmdshell",
        "UNION SELECT",
        "SELECT * FROM",
        "sqlmap",
        "information_schema",
        "SLEEP(",
        "benchmark(",
        "LOAD_FILE(",
        "INTO OUTFILE",
        "OR TRUE--",
        "'--",
        "'#",
        "%27%20OR%201=1",
        "xp_"
    ],
    :xss => [
        "<script>",
        "</script>",
        "<img src=x onerror=",
        "javascript:",
        "onerror=",
        "onload=",
        "<svg onload=",
        "document.cookie",
        "alert(",
        "prompt(",
        "confirm(",
        "<iframe",
        "<body onload=",
        "<object data=",
        "<embed src=",
        "<link rel=",
        "<meta http-equiv=",
        "<base href=",
        "<video src=",
        "<audio src=",
        "<marquee"
    ],
    :directory_traversal => [
        "../",
        "..\\",
        "/etc/passwd",
        "/etc/shadow",
        "/proc/self/environ",
        "C:\\Windows\\System32",
        "../../boot.ini",
        "../../../../",
        "~/.ssh/",
        "/root/.bash_history",
        "/WEB-INF/web.xml",
        "/windows/win.ini"
    ],
    :exposed_admin => [
        "/admin",
        "/admin/",
        "/admin/login",
        "/administrator",
        "/wp-admin",
        "/wp-login.php",
        "/cpanel",
        "/login",
        "/dashboard",
        "/backend",
        "/manager",
        "/system",
        "/auth",
        "/root",
        "/admin.php",
        "/phpmyadmin"
    ],
    :misconfiguration => [
        "Server: Apache",
        "Server: nginx",
        "X-Powered-By: PHP",
        "X-Powered-By: ASP.NET",
        "X-AspNet-Version",
        "X-Drupal-Cache",
        "X-Jenkins",
        "X-Backend-Server",
        "Access-Control-Allow-Origin: *",
        "Public-Key-Pins",
        "index of /",
        "Directory listing for",
        "open directory",
        "Exposed directory"
    ],
    :sensitive_files => [
        ".env",
        ".git/config",
        ".htaccess",
        ".htpasswd",
        "config.php",
        "settings.py",
        "wp-config.php",
        "credentials.json",
        "id_rsa",
        "secrets.yml",
        "docker-compose.yml",
        "api_key",
        "auth_token",
        "access_token"
    ],
    :information_disclosure => [
        "Fatal error:",
        "Warning: include",
        "Notice: Undefined",
        "Error on line",
        "Stack trace:",
        "Traceback (most recent call last):",
        "java.lang.NullPointerException",
        "org.springframework",
        "at sun.reflect",
        "PHP Parse error",
        "system.NullReferenceException",
        "System.InvalidOperationException",
        "RuntimeException",
        "Unhandled Exception",
        "SQLException"
    ],
    :ssrf => [
        "127.0.0.1",
        "localhost",
        "::1",
        "0.0.0.0",
        "169.254.169.254",
        "metadata.google.internal",
        "internal.cloudapp.net",
        "awsinstance.amazonaws.com",
        "169.254.170.2",
        "azure.com"
    ],
    :rce => [
        "system(",
        "exec(",
        "shell_exec(",
        "passthru(",
        "popen(",
        "proc_open(",
        "`whoami`",
        "`uname -a`",
        "`id`",
        "eval(",
        "assert(",
        "base64_decode(",
        "import os",
        "os.system(",
        "subprocess.call(",
        "Runtime.getRuntime().exec("
    ]
)

function pad_center(text::String, width::Int)
    padding_total = max(0, width - length(text))
    padding_left = padding_total ÷ 2
    padding_right = padding_total - padding_left
    return ' '^padding_left * text * ' '^padding_right
end

function animate_loading_logo(box_delay::Float64 = 0.005, spin_delay::Float64 = 0.1, text_delay::Float64 = 0.015, spin_cycles::Int = 15)
    num_text_lines = length(TEXT_LINES)

    println(CRAYON_STYLE, BOX_CHARS[:topLeft], repeat(BOX_CHARS[:horizontal], BOX_WIDTH), BOX_CHARS[:topRight])
    for _ in 1:num_text_lines
        println(CRAYON_STYLE, BOX_CHARS[:vertical], ' '^BOX_WIDTH, BOX_CHARS[:vertical])
    end
    println(CRAYON_STYLE, BOX_CHARS[:bottomLeft], repeat(BOX_CHARS[:horizontal], BOX_WIDTH), BOX_CHARS[:bottomRight])

    sleep(box_delay)

    for i in 1:spin_cycles
        spinner_char = SPINNER_CHARS[(i-1) % length(SPINNER_CHARS) + 1]
        mid_line_index = ceil(Int, num_text_lines / 2)
        print("\e[$(num_text_lines+2)A")

        println(CRAYON_STYLE, BOX_CHARS[:topLeft], repeat(BOX_CHARS[:horizontal], BOX_WIDTH), BOX_CHARS[:topRight])
        for j in 1:num_text_lines
            line = (j == mid_line_index) ? pad_center(string(spinner_char), BOX_WIDTH) : ' '^BOX_WIDTH
            println(CRAYON_STYLE, BOX_CHARS[:vertical], line, BOX_CHARS[:vertical])
        end
        println(CRAYON_STYLE, BOX_CHARS[:bottomLeft], repeat(BOX_CHARS[:horizontal], BOX_WIDTH), BOX_CHARS[:bottomRight])
        sleep(spin_delay)
    end

    print("\e[$(num_text_lines+2)A")
    println(CRAYON_STYLE, BOX_CHARS[:topLeft], repeat(BOX_CHARS[:horizontal], BOX_WIDTH), BOX_CHARS[:topRight])
    for line in TEXT_LINES
        print(CRAYON_STYLE, BOX_CHARS[:vertical])
        current_text = pad_center(line, BOX_WIDTH)
        for char in current_text
            print(CRAYON_STYLE, char)
            flush(stdout)
            sleep(text_delay)
        end
        println(CRAYON_STYLE, BOX_CHARS[:vertical])
    end
    println(CRAYON_STYLE, BOX_CHARS[:bottomLeft], repeat(BOX_CHARS[:horizontal], BOX_WIDTH), BOX_CHARS[:bottomRight])
end

@everywhere function fetch_subdomains_chunk(domain_chunk::Vector{String})
    local_results = Set{String}()
    for domain in domain_chunk
        url = "https://crt.sh/?q=%25.$domain&output=json"
        try
            response = HTTP.get(url)
            if response.status == 200
                data = JSON3.read(response.body)
                for entry in data
                    if haskey(entry, "name_value")
                        for sub in split(entry["name_value"], '\n')
                            clean_sub = strip(sub)
                            if !startswith(clean_sub, "*") && !isempty(clean_sub)
                                push!(local_results, clean_sub)
                            end
                        end
                    end
                end
            end
        catch
            continue
        end
    end
    return local_results
end

function scan_subdomain(subdomain::String)
    println(Crayons.crayon"bold yellow"("\nScanning $subdomain..."))
    try
        response = HTTP.get("http://$subdomain"; status_exception=false)
        vulnerabilities = String[]

        headers_str = join(["$k: $v" for (k,v) in response.headers], "\n")
        response_body = String(response.body)

        for (vuln_type, patterns) in VULNERABILITY_PATTERNS
            for pattern in patterns
                if occursin(pattern, response_body) || occursin(pattern, headers_str)
                    push!(vulnerabilities, string(vuln_type))
                    break
                end
            end
        end

        if length(response_body) > 100_000
            push!(vulnerabilities, "potential_data_leakage")
        end

        if isempty(vulnerabilities)
            println(Crayons.crayon"bold green"("  ✓ No obvious vulnerabilities detected"))
        else
            println(Crayons.crayon"bold red"("  ! Potential vulnerabilities found:"))
            for vuln in unique(vulnerabilities)
                println(Crayons.crayon"red"("    - $vuln"))
            end
        end

        return vulnerabilities
    catch e
        println(Crayons.crayon"bold red"("  × Error: ", sprint(showerror, e)))
        return ["scan_failed"]
    end
end

function scan_all_subdomains(subdomains::Vector{String})
    results = Dict{String,Vector{String}}()
    for sub in subdomains
        vulns = scan_subdomain(sub)
        if !isempty(vulns)
            results[sub] = vulns
        end
    end
    return results
end

function get_subdomains(domain::String; max_workers::Int=4)
    domains_to_search = String[
        domain, "www.$domain", "mail.$domain", "api.$domain",
        "blog.$domain", "dev.$domain", "test.$domain", "staging.$domain"
    ]

    chunk_size = max(1, ceil(Int, length(domains_to_search) / max_workers))
    chunks = [domains_to_search[i:min(i+chunk_size-1, end)] for i in 1:chunk_size:length(domains_to_search)]

    results = pmap(fetch_subdomains_chunk, chunks)
    subdomains = Set{String}()
    for result in results
        union!(subdomains, result)
    end
    return sort(collect(subdomains))
end

function brute_force_subdomains(domain::String, wordlist_path::String="wordlist.txt"; max_workers::Int=8)
    words = String[]
    try
        open(wordlist_path, "r") do f
            for line in eachline(f)
                word = strip(line)
                if !isempty(word)
                    push!(words, word)
                end
            end
        end
    catch
        println(Crayons.crayon"bold red"("Could not read wordlist at $wordlist_path"))
        return String[]
    end
    candidates = ["$word.$domain" for word in words]
    function resolve_subdomain(sub)
        try
            ip = getipaddr(sub)
            return sub
        catch
            return nothing
        end
    end
    found = ThreadsX.map(resolve_subdomain, candidates)
    return sort(filter(!isnothing, found))
end

function show_help()
    println("""
JuliaScope - Subdomain and Vulnerability Scanner

Usage:
  julia juliascope.jl -s <domain>      # Search for subdomains (crt.sh + brute-force)
  julia juliascope.jl -dns <domain>    # Only brute-force subdomains using wordlist
  julia juliascope.jl -ss <domain>     # Scan domain and subdomains for vulnerabilities
  julia juliascope.jl -h               # Show this help menu
""")
end

function main()
    args = copy(ARGS)
    if isempty(args) || "-h" in args || "--help" in args
        show_help()
        return
    end
    if "-s" in args
        idx = findfirst(x -> x == "-s", args)
        if idx < length(args)
            domain = args[idx+1]
            println(Crayons.crayon"bold green"("\n[+] Scanning $domain for subdomains (crt.sh + brute-force)...\n"))
            subdomains = get_subdomains(domain)
            brute_subdomains = brute_force_subdomains(domain, "wordlist.txt")
            all_subdomains = sort(union(subdomains, brute_subdomains))
            if isempty(all_subdomains)
                println(Crayons.crayon"bold red"("\nNo subdomains found for $domain.\n"))
            else
                println(Crayons.crayon"bold green"("\n[+] Found $(length(all_subdomains)) subdomains for $domain:\n"))
                for sub in all_subdomains
                    println(Crayons.crayon"cyan"(" - $sub"))
                end
            end
        else
            println("Missing domain after -s")
            show_help()
        end
        return
    elseif "-dns" in args
        idx = findfirst(x -> x == "-dns", args)
        if idx < length(args)
            domain = args[idx+1]
            println(Crayons.crayon"bold green"("\n[+] Brute-forcing subdomains for $domain...\n"))
            brute_subdomains = brute_force_subdomains(domain, "wordlist.txt")
            if isempty(brute_subdomains)
                println(Crayons.crayon"bold red"("\nNo subdomains found for $domain.\n"))
            else
                println(Crayons.crayon"bold green"("\n[+] Found $(length(brute_subdomains)) subdomains for $domain:\n"))
                for sub in brute_subdomains
                    println(Crayons.crayon"cyan"(" - $sub"))
                end
            end
        else
            println("Missing domain after -dns")
            show_help()
        end
        return
    elseif "-ss" in args
        idx = findfirst(x -> x == "-ss", args)
        if idx < length(args)
            domain = args[idx+1]
            println(Crayons.crayon"bold green"("\n[+] Scanning $domain and subdomains for vulnerabilities...\n"))
            subdomains = get_subdomains(domain)
            brute_subdomains = brute_force_subdomains(domain, "wordlist.txt")
            all_subdomains = sort(union([domain], subdomains, brute_subdomains))
            for sub in all_subdomains
                scan_subdomain(sub)
            end
        else
            println("Missing domain after -ss")
            show_help()
        end
        return
    else
        println("Unknown or missing option.")
        show_help()
        return
    end
end

# --- Main Program ---
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end


using Pkg
Pkg.add(["HTTP", "JSON3", "Crayons", "ThreadsX"])

using HTTP, JSON3, Crayons
using Distributed


if nprocs() == 1
    addprocs(4)  
end

@everywhere using HTTP, JSON3

# --- Configuration ---
const BOX_WIDTH = 38
const TEXT_LINES = [ 


    # Meta text
    "Subdomain Finder",
    
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
    :sql_injection => ["' OR '1'='1", "UNION SELECT", "sqlmap"],
    :xss => ["<script>", "alert(", "onerror="],
    :directory_traversal => ["../", "~/.ssh/"],
    :exposed_admin => ["/admin", "/wp-admin", "/manager"],
    :misconfiguration => ["Server: Apache", "X-Powered-By: PHP"]
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

# --- Main Program ---
animate_loading_logo()

while true
    print(Crayons.crayon"bold yellow"("\nEnter the domain to search subdomains for: "))
    domain_input = strip(readline())
    domain = String(domain_input)

    if isempty(domain)
        println(Crayons.crayon"bold red"("\nError: Domain cannot be empty!"))
    else
        println(Crayons.crayon"bold green"("\n[+] Scanning $domain with multithreading...\n"))
        subdomains = get_subdomains(domain)

        if isempty(subdomains)
            println(Crayons.crayon"bold red"("\nNo subdomains found for $domain.\n"))
        else
            println(Crayons.crayon"bold green"("\n[+] Found $(length(subdomains)) subdomains for $domain:\n"))
            for sub in subdomains
                println(Crayons.crayon"cyan"(" - $sub"))
            end

            println(Crayons.crayon"bold magenta"("\nSelect subdomains to scan for vulnerabilities:"))
            println(Crayons.crayon"bold cyan"("Enter 'all' to scan all, or comma-separated numbers (e.g., 1,3,5):\n"))

            for (i, sub) in enumerate(subdomains)
                println(Crayons.crayon"cyan"("[$i] $sub"))
            end

            print(Crayons.crayon"bold magenta"("\nYour choice: "))
            selection_input = strip(lowercase(readline()))

            selected_subdomains = String[]
            if selection_input == "all"
                selected_subdomains = subdomains
            else
                try
                    indices = parse.(Int, split(selection_input, ',')) |> x -> filter(i -> i ≥ 1 && i ≤ length(subdomains), x)
                    selected_subdomains = [subdomains[i] for i in indices]
                catch
                    println(Crayons.crayon"bold red"("Invalid input! Defaulting to scan all subdomains."))
                    selected_subdomains = subdomains
                end
            end

            if !isempty(selected_subdomains)
                println("\n" * "="^50)
                println(Crayons.crayon"bold blue"("VULNERABILITY ASSESSMENT REPORT"))
                println("="^50)

                report = scan_all_subdomains(selected_subdomains)

                if isempty(report)
                    println(Crayons.crayon"bold green"("\nNo vulnerabilities detected across selected subdomains"))
                else
                    for (subdomain, vulns) in report
                        println("\n" * "-"^50)
                        println(Crayons.crayon"bold yellow"("Subdomain: $subdomain"))
                        println("-"^50)
                        for vuln in vulns
                            severity = if occursin("sql_injection", vuln) || occursin("xss", vuln)
                                Crayons.crayon"bold red"("[CRITICAL] ")
                            elseif occursin("admin", vuln) || occursin("traversal", vuln)
                                Crayons.crayon"red"("[HIGH] ")
                            else
                                Crayons.crayon"yellow"("[MEDIUM] ")
                            end
                            println(severity , vuln)
                        end
                    end
                end
            else
                println(Crayons.crayon"bold red"("\nNo valid subdomains selected. Skipping scan."))
            end
        end
    end

    print(Crayons.crayon"bold magenta"("\nDo you want to scan another domain? (y/n): "))
    choice = lowercase(strip(readline()))
    if choice != "y"
        println(Crayons.crayon"bold blue"("\nThank you for using the Subdomain Finder. Goodbye!\n"))
        break
    end
end

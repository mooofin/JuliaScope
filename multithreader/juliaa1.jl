using HTTP, JSON3, Crayons
using Distributed  # For parallel processing

# --- Configuration for Animation ---
const BOX_WIDTH = 38 # Width inside the box borders
const TEXT_LINES = [
    "      Subdomain Finder          ",
    "      Powered by crt.sh         ",
    "         Author: Muffin         "
]
const BOX_CHARS = Dict(
    :topLeft => '╔', :topRight => '╗',
    :bottomLeft => '╚', :bottomRight => '╝',
    :horizontal => '═', :vertical => '║'
)
const SPINNER_CHARS = ['|', '/', '-', '\\']
const CRAYON_STYLE = Crayons.crayon"bold blue"

# --- Vulnerability Patterns ---
const VULNERABILITY_PATTERNS = Dict(
    :sql_injection => ["' OR '1'='1", "UNION SELECT", "sqlmap"],
    :xss => ["<script>", "alert(", "onerror="],
    :directory_traversal => ["../", "~/.ssh/"],
    :exposed_admin => ["/admin", "/wp-admin", "/manager"],
    :misconfiguration => ["Server: Apache", "X-Powered-By: PHP"]
)

# --- Helper Function for Animation ---
"""Pads text to the specified width, centering it."""
function pad_center(text::String, width::Int)
    padding_total = max(0, width - length(text))
    padding_left = padding_total ÷ 2
    padding_right = padding_total - padding_left
    return ' '^padding_left * text * ' '^padding_right
end

# --- Main Animation Function ---
function animate_loading_logo(
    box_delay::Float64 = 0.005,
    spin_delay::Float64 = 0.1,
    text_delay::Float64 = 0.015,
    spin_cycles::Int = 15
)
    num_text_lines = length(TEXT_LINES)
    total_height = num_text_lines + 2

    # Draw box outline
    println(CRAYON_STYLE, BOX_CHARS[:topLeft] * repeat(BOX_CHARS[:horizontal], BOX_WIDTH) * BOX_CHARS[:topRight])
    flush(stdout)
    sleep(box_delay * BOX_WIDTH)

    empty_line_content = ' '^BOX_WIDTH
    empty_full_line = BOX_CHARS[:vertical] * empty_line_content * BOX_CHARS[:vertical]

    for _ in 1:num_text_lines
        println(CRAYON_STYLE, empty_full_line)
        flush(stdout)
        sleep(box_delay)
    end

    println(CRAYON_STYLE, BOX_CHARS[:bottomLeft] * repeat(BOX_CHARS[:horizontal], BOX_WIDTH) * BOX_CHARS[:bottomRight])
    flush(stdout)
    sleep(box_delay)

    # Spinner animation
    for i in 1:spin_cycles
        spinner_char = SPINNER_CHARS[(i-1) % length(SPINNER_CHARS) + 1]
        target_line_index = ceil(Int, num_text_lines / 2)

        for j in 1:num_text_lines
            print("\r")
            flush(stdout)
            line_content = if j == target_line_index
                pad_center(string(spinner_char), BOX_WIDTH)
            else
                ' '^BOX_WIDTH
            end
            println(CRAYON_STYLE, BOX_CHARS[:vertical] * line_content * BOX_CHARS[:vertical])
            flush(stdout)
        end
        sleep(spin_delay)
    end

    # Reveal text
    for j in 1:num_text_lines
        print("\r")
        print(CRAYON_STYLE, BOX_CHARS[:vertical])
        flush(stdout)
        sleep(text_delay)

        current_text = pad_center(TEXT_LINES[j], BOX_WIDTH)
        for char in current_text
            print(CRAYON_STYLE, char)
            flush(stdout)
            sleep(text_delay)
        end

        println(CRAYON_STYLE, BOX_CHARS[:vertical])
        flush(stdout)
        sleep(text_delay)
    end
    println()
end

# --- Worker function for parallel processing ---
function fetch_subdomains_chunk(domain_chunk::Vector{String})
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
        catch e
            continue
        end
    end
    return local_results
end

# --- Vulnerability Scanner Functions ---
function scan_subdomain(subdomain::String)
    println(Crayons.crayon"bold yellow"("\nScanning $subdomain..."))
    
    try
        response = HTTP.get("http://$subdomain"; status_exception=false)
        vulnerabilities = String[]
        
        # Convert headers to string for pattern matching
        headers_str = join(["$k: $v" for (k,v) in response.headers], "\n")
        response_body = String(response.body)
        
        # Pattern-based detection
        for (vuln_type, patterns) in VULNERABILITY_PATTERNS
            for pattern in patterns
                if occursin(pattern, response_body) || occursin(pattern, headers_str)
                    push!(vulnerabilities, string(vuln_type))
                    break
                end
            end
        end
        
        # Size-based anomaly detection
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
        if isa(e, HTTP.Exceptions.ConnectError)
            println(Crayons.crayon"bold yellow"("  × Domain not reachable: $subdomain"))
        else
            println(Crayons.crayon"bold red"("  × Error scanning $subdomain: $(sprint(showerror, e))"))
        end
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

# --- Enhanced Subdomain Fetching with Multithreading ---
function get_subdomains(domain::String; max_workers::Int=4)
    domains_to_search = String[
        domain,
        "www.$domain",
        "mail.$domain",
        "api.$domain",
        "blog.$domain",
        "dev.$domain",
        "test.$domain",
        "staging.$domain"
    ]
    
    chunk_size = max(1, ceil(Int, length(domains_to_search) / max_workers))
    chunks = [domains_to_search[i:min(i+chunk_size-1, end)] 
              for i in 1:chunk_size:length(domains_to_search)]
    
    results = pmap(fetch_subdomains_chunk, chunks)
    
    subdomains = Set{String}()
    for result in results
        union!(subdomains, result)
    end
    
    return sort(collect(subdomains))
end

# --- Logo Print Function ---
function print_logo()
    animate_loading_logo()
end

# --- Main Program ---
print_logo()

while true
    print(Crayons.crayon"bold yellow"("\nEnter the domain to search subdomains for: "))
    domain_input = strip(readline())
    domain = String(domain_input)  # Explicit conversion to String

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
            
            print(Crayons.crayon"bold magenta"("\nRun vulnerability scan? (y/n): "))
            scan_choice = lowercase(strip(readline()))
            
            if scan_choice == "y"
                println("\n" * "="^50)
                println(Crayons.crayon"bold blue"("VULNERABILITY ASSESSMENT REPORT"))
                println("="^50)
                
                vulnerability_report = scan_all_subdomains(subdomains)
                
                if isempty(vulnerability_report)
                    println(Crayons.crayon"bold green"("\nNo vulnerabilities detected across all subdomains"))
                else
                    for (subdomain, vulns) in vulnerability_report
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
                            
                            println(severity * vuln)
                        end
                    end
                end
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
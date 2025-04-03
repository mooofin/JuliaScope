using HTTP, JSON3, Crayons

function print_logo()
    println(Crayons.crayon"bold blue"("""
    ╔══════════════════════════════════╗
    ║        Subdomain Finder          ║
    ║       Powered by crt.sh          ║
    ║          Author: Muffin           ║
    ╚══════════════════════════════════╝
    """))
end

function get_subdomains(domain)
    url = "https://crt.sh/?q=%25.$domain&output=json"

    try
        response = HTTP.get(url)

        if response.status != 200
            println(Crayons.crayon"bold red"("Error: Failed to fetch data. HTTP Status: $(response.status)"))
            return []
        end

        data = JSON3.read(response.body)  # Parse JSON response

        # Extract and clean subdomains
        subdomains = Set()
        for entry in data
            if haskey(entry, "name_value")
                for sub in split(entry["name_value"], '\n')  # Handle multi-line entries
                    clean_sub = strip(sub)  
                    if !startswith(clean_sub, "*")  
                        push!(subdomains, clean_sub)
                    end
                end
            e1nd
        end1

        return sort(collect(subdomains))  # Return sorted unique subdomains

            catch
        println(Crayons.crayon"bold red"("Error occurred: $e"))
        return []
    end
end
# UI Heads
print_logo()

# User input
print(Crayons.crayon"bold yellow"("\nEnter the domain to search subdomains for: "))
domain = strip(readline())

if isempty(domain)
    println(Crayons.crayon"bold red"("\nError: Domain cannot be empty!"))
else
    subdomains = get_subdomains(domain)

    if isempty(subdomains)
        println(Crayons.crayon"bold red"("\nNo subdomains found for $domain.\n"))
    else
        println(Crayons.crayon"bold green"("\n[+] Found $(length(subdomains)) subdomains for $domain:\n"))
        for sub in subdomains
            println(Crayons.crayon"cyan"(" - $sub"))
        end
    end
end

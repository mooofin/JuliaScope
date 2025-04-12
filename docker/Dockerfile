FROM julia:latest
WORKDIR /app

# Copy project files first
COPY Project.toml Manifest.toml ./

# Install and precompile
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# Copy rest of code
COPY . .

CMD ["julia", "--project=.", "juliaa1.jl"]

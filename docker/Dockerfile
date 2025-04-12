FROM julia:latest
WORKDIR /app

COPY Project.toml Manifest.toml ./


RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

COPY . .

CMD ["julia", "--project=.", "juliaa1.jl"]

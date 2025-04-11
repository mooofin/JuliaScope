FROM julia:latest
WORKDIR /app
COPY . .
RUN julia --project=. -e 'using Pkg; Pkg.instantiate()'
CMD ["julia", "--project=.", "juliaa1.jl"]
# ---- Base image with Julia 1.9 (or later) ----
FROM julia:1.9

# optional: system packages you might need
RUN apt-get update && apt-get install -y git

WORKDIR /app
COPY Project.toml Manifest.toml /app/

# Install required Julia packages once, then precompile
COPY Project.toml Manifest.toml /app/
RUN julia -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
COPY . /app   
# second copy brings in your code
# -------- Render convention --------
# Render sets env PORT. Expose that, default to 8080 for local runs.
ENV PORT=8080
EXPOSE 8080

CMD ["julia", "webapp.jl"]
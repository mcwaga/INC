# ---- Base image with Julia 1.9 (or later) ----
FROM julia:1.9

# optional: system packages you might need
RUN apt-get update && apt-get install -y git

WORKDIR /app
COPY . /app

# Install required Julia packages once, then precompile
RUN julia -e 'using Pkg; Pkg.add.(["Dash","DashCoreComponents","DashHtmlComponents",\
    "DashTable","DataFrames","PlotlyJS","Plots"]); Pkg.precompile()'
# -------- Render convention --------
# Render sets env PORT. Expose that, default to 8080 for local runs.
ENV PORT=8080
EXPOSE 8080

CMD ["julia", "webapp.jl"]
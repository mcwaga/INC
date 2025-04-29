# -------------------------
# Input Assumptions
# -------------------------

using DataFrames, Plots, Printf

# Base Case Assumptions
management_fee_base = 0.003        # 0.3% of AUM
initial_aum_per_family = 300_000_000.0   # BRL 300 million per family
aum_growth_base = 0.06            # 6% annual growth in AUM per family


salary_vec_base    = [0.0, 0.5e6, 1.0e6, 1.25e6, 1.5e6]
rent_vec_base      = [0.0, 0.1e6, 0.20e6, 0.20e6, 0.24e6]
tech_vec_base      = [0.1e6, 0.105e6, 0.11e6, 0.116e6, 0.122e6]
legal_vec_base     = [0.012e6, 0.015e6, 0.016e6, 0.017e6, 0.018e6]
marketing_vec_base = [0.1e6, 0.11e6, 0.12e6, 0.13e6, 0.14e6]

# Families vectors (one entry per projection year)
families_vec_base = [1.5, 4, 8, 10, 12]          # Base Case
families_vec_opt  = [3.0, 8, 12, 15, 20]         # Optimistic
families_vec_pess = [1.5, 3, 4, 8, 10]           # Pessimistic

# Other financial assumptions
tax_rate       = 0.34   # 34% corporate tax rate on profits
discount_rate  = 0.10   # 10% discount rate for DCF
terminal_growth= 0.05   # 5% perpetuity growth for terminal value after year 5
projection_years = 5

# Optimistic Scenario Adjustments
management_fee_opt = 0.005         # 0.5% of AUM
aum_growth_opt = 0.08             # 8% AUM growth
initial_aum_per_family_opt = 400_000_000.0   # BRL 400 million per family

# Pessimistic Scenario Adjustments
management_fee_pess = 0.003       # 0.3% of AUM
aum_growth_pess = 0.04           # 4% AUM growth
initial_aum_per_family_pess = 250_000_000.0   # BRL 250 million per family

# -------------------------
# Projection Calculation Function
# -------------------------

# --------------------------------------------------------------
#  New helper: fetch the cost for a given year, even if the
#  user supplies a shorter vector (it repeats the last value).
# --------------------------------------------------------------
getcost(v::Vector{<:Real}, yr::Int) = yr ≤ length(v) ? v[yr] : v[end]

getfam(v::Vector{<:Real}, yr::Int) = yr ≤ length(v) ? v[yr] : v[end]

function project_mfo_with_vectors(
        scenario::String;
        # --- operating assumptions ---
        management_fee::Float64,
        families_vec::Vector{Float64},
        aum_growth::Float64,
        initial_aum_per_family::Float64,
        # --- cost vectors (one value per year) ---
        salary_vec::Vector{Float64},
        rent_vec::Vector{Float64},
        tech_vec::Vector{Float64},
        legal_vec::Vector{Float64},
        marketing_vec::Vector{Float64}
  )
    years = 1:projection_years
    prev_families = getfam(families_vec, 1)
    prev_total_aum  = prev_families * initial_aum_per_family

    # storage
    rows = DataFrame(Year      = Int[],
                     Families  = Float64[],
                     TotalAUM  = Float64[],
                     Revenue   = Float64[],
                     OpCosts   = Float64[],
                     EBITDA    = Float64[],
                     NetIncome = Float64[],
                     FCF       = Float64[])

    for yr in years
        families = getfam(families_vec, yr)
        new_families = families - prev_families
        # --- growth in families & AUM --------------------------
        new_aum   = new_families *
                    initial_aum_per_family * (1 + aum_growth)^(yr-1)
        start_aum = prev_total_aum + new_aum
        end_aum   = start_aum * (1 + aum_growth)
        avg_aum   = 0.5 * (start_aum + end_aum)

        # --- revenue & explicit cost lookup --------------------
        revenue = management_fee * avg_aum
        op_cost =  getcost(salary_vec, yr) +
                   getcost(rent_vec,   yr) +
                   getcost(tech_vec,   yr) +
                   getcost(legal_vec,  yr) +
                   getcost(marketing_vec, yr)

        ebitda     = revenue - op_cost
        taxes      = ebitda > 0 ? tax_rate * ebitda : 0.0
        net_income = ebitda - taxes
        fcf        = net_income     # (cap-light business)

        push!(rows,
              (yr, families, end_aum, revenue, op_cost,
               ebitda, net_income, fcf))

        prev_total_aum = end_aum      # loop carry-over
        prev_families = families
    end

    # -------- DCF valuation (same logic) -----------------------
    disc = [(1+discount_rate)^t for t in years]
    npv_fcfs = sum(rows.FCF ./ disc)
    tv       = rows.FCF[end] * (1+terminal_growth) /
               (discount_rate - terminal_growth)
    npv_tv   = tv / disc[end]
    dcf_val  = npv_fcfs + npv_tv

    println("\n", scenario,
            " Scenario – 5‑Year Table (values in millions of BRL)")
    println(in_millions(rows))
    println("DCF Valuation = BRL ", round(dcf_val/1e6; digits=2), " mi")

    return rows, dcf_val
end

function in_millions(df::DataFrame; skip = [:Year, :Families])
    pretty = deepcopy(df)
    # Build a lookup Set that contains both Symbol and String forms
    skip_set = Set{Any}()

    for s in skip
        push!(skip_set, s)           # keep as‑is
        push!(skip_set, Symbol(s))   # Symbol form
        push!(skip_set, String(s))   # String form
    end

    for col in names(df)
        if col ∉ skip_set && eltype(df[!, col]) <: Real
            pretty[!, col] = round.(df[!, col] ./ 1e6; digits = 2)
        end
    end
    return pretty
end


# -------------------------
# Run Scenarios
# -------------------------

# Base Case
base_df, base_val = project_mfo_with_vectors(
    "Base Case";
    management_fee = management_fee_base,
    families_vec   = families_vec_base,
    aum_growth     = aum_growth_base,
    salary_vec     = salary_vec_base,
    rent_vec       = rent_vec_base,
    tech_vec       = tech_vec_base,
    legal_vec      = legal_vec_base,
    marketing_vec  = marketing_vec_base,
    initial_aum_per_family = initial_aum_per_family
);

# Optimistic Case
opt_df, opt_val = project_mfo_with_vectors(
    "Optimistic";
    management_fee = management_fee_opt,
    families_vec   = families_vec_opt,
    aum_growth     = aum_growth_opt,
    salary_vec     = salary_vec_base,
    rent_vec       = rent_vec_base,
    tech_vec       = tech_vec_base,
    legal_vec      = legal_vec_base,
    marketing_vec  = marketing_vec_base,
    initial_aum_per_family = initial_aum_per_family_opt
);

# Pessimistic Case
pess_df, pess_val = project_mfo_with_vectors(
    "Pessimistic";
    management_fee = management_fee_pess,
    families_vec   = families_vec_pess,
    aum_growth     = aum_growth_pess,
    salary_vec     = salary_vec_base,
    rent_vec       = rent_vec_base,
    tech_vec       = tech_vec_base,
    legal_vec      = legal_vec_base,
    marketing_vec  = marketing_vec_base,
    initial_aum_per_family = initial_aum_per_family_pess
);

# -------------------------
# Plotting (Base Case)
# -------------------------

# Plot 1: Total AUM over time (Base Case)
years = 1:projection_years
plot(years, base_df.TotalAUM/1e6, marker=:circle, color=:orange, labels="Total AUM",
     title="Total AUM over 5 Years (Base Case)", xlabel="Year", ylabel="BRL Millions", legend=false)

# Plot 2: Revenue and Net Income over time (Base Case)
plot(years, base_df.Revenue/1e6, marker=:circle, color=:orange, label="Revenue",
     title="Revenue and Net Income (Base Case)", xlabel="Year", ylabel="BRL Millions")
plot!(years, base_df.NetIncome/1e6, marker=:square, color=:red, label="Net Income")

# Plot 3: Cumulative Free Cash Flow over time (Base Case)
cum_fcf = cumsum(base_df.FCF)
plot(years, cum_fcf/1e6, marker=:circle, color=:green, labels="Cumulative FCF",
     title="Cumulative Free Cash Flow (Base Case)", xlabel="Year", ylabel="BRL Millions", legend=false)
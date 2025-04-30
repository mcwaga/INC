###############################################################
#  webapp.jl  –  Lightweight Dash.jl interface for INC_valuation
###############################################################

using Dash, DashCoreComponents, DashHtmlComponents, DashTable
# bring the valuation function into scope
using PlotlyJS, DataFrames
import PlotlyJS: bar
# bring the valuation function into scope
include("INC_valuation.jl")   # assumes same folder

# ---------------- Form defaults ----------------
defaults = Dict(
    :fee          => 0.003,           # 0.3 %
    :aum0         => 300e6,           # R$ per family
    :aum_growth   => 0.06,            # 6 %
    :families     => "1.5,4,8,10,12", # CSV string → vector
    :salary_vec   => "0,0.5,1,1.25,1.5",   # in millions
    :rent_vec     => "0,0.1,0.2,0.2,0.24",
    :tech_vec     => "0.1,0.105,0.11,0.116,0.122",
    :legal_vec    => "0.012,0.015,0.016,0.017,0.018",
    :mkt_vec      => "0.1,0.11,0.12,0.13,0.14"
)

# -------------- Dash Layout --------------------
app = dash(external_stylesheets = [
    "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"
])

app.layout = html_div([
    html_h2("MFO 5-Year Valuation", style=Dict(:marginBottom=>"12px")),
    html_div(className="card shadow-sm", [
        html_h4("Input Assumptions"),

        # ----- single‑value inputs -----
        html_div([
            html_label("Management fee (%)"),
            dcc_input(id="fee", type="number", value=defaults[:fee]*100,
                      step=0.05, style=Dict(:width=>"100%")),

            html_label(["Initial AUM / family", html_br(), "(R&#36; mi)"]),
            dcc_input(id="aum0", type="number", value=defaults[:aum0]/1e6,
                      step=10, style=Dict(:width=>"100%")),

            html_label("AUM growth / year (%)"),
            dcc_input(id="aum_growth", type="number", value=defaults[:aum_growth]*100,
                      step=1, style=Dict(:width=>"100%")),
        ], style=Dict(
            :display=>"grid",
            :gridTemplateColumns=>"160px 1fr",
            :rowGap=>"10px",
            :columnGap=>"16px",
            :alignItems=>"center"
        )),

        html_hr(),

        html_h5("Year‑by‑Year Inputs (mi)"),

        html_p("Edit the yearly assumptions below. Values are in *millions* (except Families).",
               style=Dict(:fontStyle=>"italic", :marginBottom=>"6px")),

        dash_datatable(
            id="input_table",
            columns=[
                Dict("name"=>"Year","id"=>"Year","type"=>"numeric"),
                Dict("name"=>"Families","id"=>"Families","type"=>"numeric"),
                Dict("name"=>"Salary","id"=>"Salary","type"=>"numeric"),
                Dict("name"=>"Rent","id"=>"Rent","type"=>"numeric"),
                Dict("name"=>"Tech","id"=>"Tech","type"=>"numeric"),
                Dict("name"=>"Legal","id"=>"Legal","type"=>"numeric"),
                Dict("name"=>"Marketing","id"=>"Marketing","type"=>"numeric")
            ],
            data=[
                Dict("Year"=>1,"Families"=>1.5,"Salary"=>0.0,"Rent"=>0.0,"Tech"=>0.10,"Legal"=>0.012,"Marketing"=>0.10),
                Dict("Year"=>2,"Families"=>4.0,"Salary"=>0.5,"Rent"=>0.1,"Tech"=>0.105,"Legal"=>0.015,"Marketing"=>0.11),
                Dict("Year"=>3,"Families"=>8.0,"Salary"=>1.0,"Rent"=>0.2,"Tech"=>0.11,"Legal"=>0.016,"Marketing"=>0.12),
                Dict("Year"=>4,"Families"=>10.0,"Salary"=>1.25,"Rent"=>0.2,"Tech"=>0.116,"Legal"=>0.017,"Marketing"=>0.13),
                Dict("Year"=>5,"Families"=>12.0,"Salary"=>1.5,"Rent"=>0.24,"Tech"=>0.122,"Legal"=>0.018,"Marketing"=>0.14)
            ],
            editable=true,
            style_cell=Dict(
                :minWidth=>"80px",
                :textAlign=>"right",
                :padding=>"6px 4px",
                :fontFamily=>"monospace"
            ),
            style_header=Dict(
                :backgroundColor=>"#0066cc",
                :color=>"white",
                :fontWeight=>"bold",
                :textAlign=>"center"
            ),
        ),
        html_div(id="err_msg", style=Dict(:color=>"crimson")),

        html_br(),
        html_button("Run Valuation", id="run_btn", n_clicks=0,
                    className="btn btn-primary btn-lg",
                    style=Dict(:marginTop=>"14px", :width=>"100%"))
    ],
    style=Dict(
        :width => "560px",
        :maxWidth => "560px",
        :padding => "24px",
        :marginRight => "24px",
        :border => "0",
        :borderRadius => "12px",
        :backgroundColor => "#ffffff"
    )),

    html_div([
        html_h4("5-Year Table (BRL millions)"),
        dash_datatable(id="table",
                       style_cell=Dict(
                           :minWidth=>"80px",
                           :padding=>"4px",
                           :fontFamily=>"monospace",
                           :textAlign=>"right"),
                       style_header=Dict(
                           :backgroundColor=>"#f2f2f2",
                           :fontWeight=>"bold",
                           :textAlign=>"center")),
        html_br(),
        dcc_graph(id="aum_plot"),
        dcc_graph(id="rev_plot"),
        dcc_graph(id="fcf_plot")
    ], style=Dict(:width=>"calc(100% - 600px)",
                  :display=>"inline-block",
                  :paddingLeft=>"32px",
                  :paddingTop=>"4px",
                  :verticalAlign=>"top"))
])


# ------------- Helper to parse CSV -> Vector ---------------
csvvec(txt, factor=1.0) = [parse(Float64, x)*factor for x in split(strip(txt), ',')]

# robust conversion: accepts Real, String, or Missing
to_float(x) = x === missing ? throw(ArgumentError("missing")) :
              x isa Real    ? float(x) :
              parse(Float64, String(x))

# ------------- Callback: run valuation + update UI ---------
callback!(
    app, Output("table","data"), Output("table","columns"),
    Output("aum_plot","figure"), Output("rev_plot","figure"),
    Output("fcf_plot","figure"), Output("err_msg","children"),
    Input("run_btn","n_clicks"),
    State("fee","value"), State("aum0","value"), State("aum_growth","value"),
    State("input_table","data")
) do _, fee_pct, aum0_mi, grow_pct, table_data

    fee  = fee_pct/100
    aum0 = aum0_mi*1e6
    grow = grow_pct/100

    local df = nothing   # make df visible outside try
    try
        fam   = [to_float(row["Families"])               for row in table_data]
        sal   = [to_float(row["Salary"]   ) * 1e6        for row in table_data]
        rent  = [to_float(row["Rent"]     ) * 1e6        for row in table_data]
        tech  = [to_float(row["Tech"]     ) * 1e6        for row in table_data]
        legal = [to_float(row["Legal"]    ) * 1e6        for row in table_data]
        mkt   = [to_float(row["Marketing"]) * 1e6        for row in table_data]

        # run projection
        df, _ = project_mfo_with_vectors("WebRun";
            management_fee = fee,
            families_vec   = fam,
            aum_growth     = grow,
            initial_aum_per_family = aum0,
            salary_vec = sal, rent_vec = rent, tech_vec = tech,
            legal_vec = legal, marketing_vec = mkt
        )
    catch
        empty_tbl  = Vector{Dict{String,Any}}()  # []
        empty_cols = Vector{Dict{String,Any}}()  # []

        empty_fig_json = Dict("data"=>[], "layout"=>Dict())  # valid Plotly fig

        return empty_tbl, empty_cols,
               empty_fig_json, empty_fig_json, empty_fig_json,
               "Non‑numeric or missing cell."
    end

    if df === nothing
        empty_tbl  = Vector{Dict{String,Any}}()
        empty_cols = Vector{Dict{String,Any}}()
        empty_fig_json = Dict("data"=>[], "layout"=>Dict())
        return empty_tbl, empty_cols, empty_fig_json, empty_fig_json, empty_fig_json,
               "Unexpected error in valuation."
    end

    # create Dash‑compatible table (millions except Year/Families)
    df_pretty = in_millions(df)
    tbl_cols  = [Dict("name"=>string(c), "id"=>string(c)) for c in names(df_pretty)]
    tbl_data  = [Dict(string(k)=>v for (k,v) in pairs(row)) for row in eachrow(df_pretty)]

    # build figures (values in millions)
    yrs          = df.Year
    aum_mi       = df.TotalAUM ./ 1e6
    revenue_mi   = df.Revenue   ./ 1e6
    netinc_mi    = df.NetIncome ./ 1e6
    cum_fcf_mi   = cumsum(df.FCF) ./ 1e6

    fig_aum = Plot(yrs, aum_mi, kind="bar",
                   Layout(title="Total AUM (BRL mi)",
                          xaxis_title="Year",
                          yaxis_title="Millions"))

    fig_rev = Plot(
        [bar(x=yrs, y=revenue_mi, name="Revenue"),
         bar(x=yrs, y=netinc_mi,  name="Net Income")],
        Layout(title="Revenue vs. Net Income (BRL mi)",
               barmode="group",
               xaxis_title="Year",
               yaxis_title="Millions"))

    fig_fcf = Plot(yrs, cum_fcf_mi, kind="scatter", mode="lines+markers",
                   Layout(title="Cumulative FCF (BRL mi)",
                          xaxis_title="Year",
                          yaxis_title="Millions"))

    return tbl_data, tbl_cols, fig_aum, fig_rev, fig_fcf, ""
end

# ------------- Run server --------------
run_server(app, "0.0.0.0", parse(Int, get(ENV, "PORT", "8080")); debug=false)

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
app = dash()

app.layout = html_div([
    html_h2("MFO 5-Year Valuation"),
    html_div([
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
        ], style=Dict(:display=>"grid",
                      :gridTemplateColumns=>"140px 140px",
                      :gap=>"6px 10px",
                      :alignItems=>"center")),

        html_hr(),

        # ----- vector inputs -----
        html_label("Families vector (CSV)"),
        dcc_textarea(id="families", value=defaults[:families],
                     placeholder="e.g. 1.5,4,8,10,12",
                     style=Dict(:width=>"100%", :height=>"55px")),

        html_label("Salary vector (CSV, BRL mi/yr)"),
        dcc_textarea(id="salary_vec", value=defaults[:salary_vec],
                     style=Dict(:width=>"100%", :height=>"45px")),

        html_label("Rent vector (CSV, BRL mi/yr)"),
        dcc_textarea(id="rent_vec", value=defaults[:rent_vec],
                     style=Dict(:width=>"100%", :height=>"45px")),

        html_label("Tech vector (CSV, BRL mi/yr)"),
        dcc_textarea(id="tech_vec", value=defaults[:tech_vec],
                     style=Dict(:width=>"100%", :height=>"45px")),

        html_label("Legal vector (CSV, BRL mi/yr)"),
        dcc_textarea(id="legal_vec", value=defaults[:legal_vec],
                     style=Dict(:width=>"100%", :height=>"45px")),

        html_label("Marketing vector (CSV, BRL mi/yr)"),
        dcc_textarea(id="mkt_vec", value=defaults[:mkt_vec],
                     style=Dict(:width=>"100%", :height=>"45px")),

        html_br(),
        html_button("Run Valuation", id="run_btn", n_clicks=0,
                    style=Dict(:marginTop=>"8px", :width=>"100%"))
    ],
    style=Dict(:width=>"320px",
               :display=>"inline-block",
               :verticalAlign=>"top",
               :padding=>"12px",
               :border=>"1px solid #ccc",
               :backgroundColor=>"#f8f8f8",
               :fontSize=>"14px")),

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
    ], style=Dict(:width=>"70%", :display=>"inline-block",
                  :paddingLeft=>"20px", :verticalAlign=>"top"))
])

# ------------- Helper to parse CSV -> Vector ---------------
csvvec(txt, factor=1.0) = [parse(Float64, x)*factor for x in split(strip(txt), ',')]

# ------------- Callback: run valuation + update UI ---------
callback!(
    app, Output("table", "data"), Output("table", "columns"),
    Output("aum_plot", "figure"), Output("rev_plot", "figure"),
    Output("fcf_plot", "figure"),
    Input("run_btn", "n_clicks"),
    State("fee", "value"), State("aum0", "value"), State("aum_growth", "value"),
    State("families", "value"), State("salary_vec", "value"),
    State("rent_vec", "value"), State("tech_vec", "value"),
    State("legal_vec", "value"), State("mkt_vec", "value")
) do _,
     fee_pct, aum0_mi, grow_pct, fam_txt, sal_txt, rent_txt, tech_txt, legal_txt, mkt_txt

    # convert form inputs
    fee   = fee_pct / 100
    aum0  = aum0_mi * 1e6
    grow  = grow_pct / 100
    fam   = csvvec(fam_txt)
    sal   = csvvec(sal_txt, 1e6)
    rent  = csvvec(rent_txt, 1e6)
    tech  = csvvec(tech_txt, 1e6)
    legal = csvvec(legal_txt, 1e6)
    mkt   = csvvec(mkt_txt, 1e6)

    # run projection
    df, _ = project_mfo_with_vectors("WebRun";
        management_fee = fee,
        families_vec   = fam,
        aum_growth     = grow,
        initial_aum_per_family = aum0,
        salary_vec = sal, rent_vec = rent, tech_vec = tech,
        legal_vec = legal, marketing_vec = mkt
    )

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

    return tbl_data, tbl_cols, fig_aum, fig_rev, fig_fcf
end

# ------------- Run server --------------
run_server(app; debug=false)
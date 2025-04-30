###############################################################
#  webapp.jl  –   Dash.jl interface for INC_valuation
###############################################################

# Using the main Dash package instead of individual component packages
using Dash
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

# Custom color scheme - Premium finance look
COLOR_SCHEME = Dict(
    :primary => "#1e3a8a",        # Dark blue
    :secondary => "#475569",      # Slate
    :accent => "#047857",         # Emerald
    :highlight => "#fbbf24",      # Amber
    :danger => "#dc2626",         # Red
    :background => "#f8fafc",     # Light background
    :card => "#ffffff",           # White
    :header_gradient1 => "#1e3a8a", # Dark blue
    :header_gradient2 => "#3b82f6", # Bright blue
    :text => "#0f172a",           # Dark slate
    :text_light => "#64748b",     # Light slate
    :border => "#e2e8f0",         # Slate border
    :chart1 => "#3b82f6",         # Blue
    :chart2 => "#10b981",         # Emerald
    :chart3 => "#f59e0b"          # Amber
)

# -------------- Dash Layout --------------------
app = dash(
    external_stylesheets = [
        "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
        "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css",
        "https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;500;600;700&family=Open+Sans:wght@300;400;500;600;700&display=swap"
    ]
)

# Custom styles for application header
header_style = """
    .app-header {
        background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
        color: white;
        padding: 2rem 3rem;
        margin-bottom: 2rem;
        border-radius: 0 0 2rem 2rem;
        box-shadow: 0 10px 25px rgba(30, 58, 138, 0.2);
    }
    .card {
        border-radius: 1rem;
        border: none;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
        overflow: hidden;
    }
    .card-header {
        padding: 1.25rem 1.5rem;
        background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
        color: white;
        font-weight: 600;
        border: none;
    }
    .card-header-accent {
        background: linear-gradient(135deg, #047857 0%, #10b981 100%);
    }
    .btn-primary {
        background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
        border: none;
        padding: 0.75rem 1.5rem;
        font-weight: 600;
        transition: all 0.3s ease;
        box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
    }
    .btn-primary:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 15px rgba(59, 130, 246, 0.4);
    }
    .form-control, .form-select {
        border-radius: 0.75rem;
        padding: 0.75rem 1rem;
        border: 1px solid #e2e8f0;
        box-shadow: 0 2px 5px rgba(0, 0, 0, 0.02);
    }
    .form-control:focus, .form-select:focus {
        border-color: #3b82f6;
        box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.25);
    }
    .dash-table-container .dash-spreadsheet-container .dash-spreadsheet-inner table {
        border-collapse: separate;
        border-spacing: 0;
        border-radius: 0.5rem;
        overflow: hidden;
    }
    .dash-table-container .dash-spreadsheet-container .dash-spreadsheet-inner th {
        background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
        color: white !important;
        font-weight: 600 !important;
        text-align: center !important;
        padding: 1rem 0.75rem !important;
    }
    .stats-card {
        border-radius: 1rem;
        padding: 1.5rem;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
        transition: all 0.3s ease;
        height: 100%;
    }
    .stats-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
    }
    .stats-value {
        font-size: 2.5rem;
        font-weight: 700;
        margin: 0.5rem 0;
        color: #1e3a8a;
    }
    .stats-blue {
        background: linear-gradient(135deg, #dbeafe 0%, #eff6ff 100%);
        border-left: 5px solid #3b82f6;
    }
    .stats-green {
        background: linear-gradient(135deg, #d1fae5 0%, #ecfdf5 100%);
        border-left: 5px solid #10b981;
    }
    .stats-amber {
        background: linear-gradient(135deg, #fef3c7 0%, #fffbeb 100%);
        border-left: 5px solid #f59e0b;
    }
    .stats-purple {
        background: linear-gradient(135deg, #ede9fe 0%, #f5f3ff 100%);
        border-left: 5px solid #8b5cf6;
    }
    .stats-label {
        font-size: 1rem;
        font-weight: 500;
        color: #475569;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }
    .stats-icon {
        font-size: 2rem;
        color: #64748b;
        opacity: 0.8;
    }
"""

# -------------- Dash Layout --------------------
app.layout = html_div(style=Dict(
    :fontFamily => "'Montserrat', 'Open Sans', sans-serif",
    :backgroundColor => COLOR_SCHEME[:background],
    :minHeight => "100vh",
    :color => COLOR_SCHEME[:text]
), children=[
    # Premium Application Header
    html_div(className="app-header", children=[
        html_div(className="container-fluid", children=[
            html_div(className="row align-items-center", children=[
                html_div(className="col-auto", children=[
                    html_i(className="bi bi-bar-chart-fill", 
                           style=Dict(:fontSize => "2.5rem", :marginRight => "1rem"))
                ]),
                html_div(className="col", children=[
                    html_h1("MFO Valuation", 
                        style=Dict(
                            :fontWeight => "700",
                            :fontSize => "2.2rem",
                            :marginBottom => "0.25rem"
                        )
                    ),
                    html_p("Multi-Family Office Financial Projection & Enterprise Valuation", 
                        style=Dict(
                            :opacity => "0.9",
                            :fontSize => "1.1rem",
                            :fontWeight => "300",
                            :marginBottom => "0"
                        )
                    )
                ]),
                html_div(className="col-auto d-none d-lg-block", children=[
                    html_div(className="d-flex", children=[
                        html_div(className="px-4", children=[
                            html_div("INC", style=Dict(:fontSize => "0.875rem", :opacity => "0.8")),
                            html_div("Analysis", style=Dict(:fontWeight => "600", :fontSize => "1.1rem"))
                        ]),
                        html_div(className="px-4", style=Dict(:borderLeft => "1px solid rgba(255,255,255,0.2)"), children=[
                            html_div("Financial", style=Dict(:fontSize => "0.875rem", :opacity => "0.8")),
                            html_div("Dashboard", style=Dict(:fontWeight => "600", :fontSize => "1.1rem"))
                        ])
                    ])
                ])
            ])
        ])
    ]),
    
    # Main Content
    html_div(className="container-fluid pb-5", children=[
        # Key Statistics Row
        html_div(className="row mb-4 gy-4", children=[
            # Valuation Stat (was Family Offices)
            html_div(className="col-12 col-md-6 col-xl-3", children=[
                html_div(className="stats-card stats-blue", children=[
                    html_div(className="d-flex justify-content-between", children=[
                        html_div(children=[
                            html_div(className="stats-label", "Valuation"),
                            html_div(className="stats-value", id="stat_families", "—"),
                            html_div("DCF (today)", style=Dict(:fontSize => "0.875rem", :color => COLOR_SCHEME[:text_light]))
                        ]),
                        html_i(className="bi bi-people-fill stats-icon mt-2")
                    ])
                ])
            ]),
            
            # AUM Stat
            html_div(className="col-12 col-md-6 col-xl-3", children=[
                html_div(className="stats-card stats-green", children=[
                    html_div(className="d-flex justify-content-between", children=[
                        html_div(children=[
                            html_div(className="stats-label", "Total AUM"),
                            html_div(className="stats-value", id="stat_aum", "3.6B"),
                            html_div("Year 5 Projection", style=Dict(:fontSize => "0.875rem", :color => COLOR_SCHEME[:text_light]))
                        ]),
                        html_i(className="bi bi-currency-dollar stats-icon mt-2")
                    ])
                ])
            ]),
            
            # Revenue Stat
            html_div(className="col-12 col-md-6 col-xl-3", children=[
                html_div(className="stats-card stats-amber", children=[
                    html_div(className="d-flex justify-content-between", children=[
                        html_div(children=[
                            html_div(className="stats-label", "Annual Revenue"),
                            html_div(className="stats-value", id="stat_revenue", "10.8M"),
                            html_div("Year 5 Projection", style=Dict(:fontSize => "0.875rem", :color => COLOR_SCHEME[:text_light]))
                        ]),
                        html_i(className="bi bi-graph-up-arrow stats-icon mt-2")
                    ])
                ])
            ]),
            
            # FCF Stat
            html_div(className="col-12 col-md-6 col-xl-3", children=[
                html_div(className="stats-card stats-purple", children=[
                    html_div(className="d-flex justify-content-between", children=[
                        html_div(children=[
                            html_div(className="stats-label", "Total FCF"),
                            html_div(className="stats-value", id="stat_fcf", "15.3M"),
                            html_div("Cumulative 5-Year", style=Dict(:fontSize => "0.875rem", :color => COLOR_SCHEME[:text_light]))
                        ]),
                        html_i(className="bi bi-cash-stack stats-icon mt-2")
                    ])
                ])
            ])
        ]),
        
        # Main Content Row
        html_div(className="row", children=[
            # Left Column - Input Parameters
            html_div(className="col-12 col-lg-5 col-xl-4 mb-4", children=[
                # Inputs Card
                html_div(className="card shadow mb-4", children=[
                    html_div(className="card-header d-flex align-items-center", children=[
                        html_i(className="bi bi-sliders me-2"),
                        html_h4("Input Parameters", style=Dict(:margin => "0", :fontWeight => "600", :fontSize => "1.25rem"))
                    ]),
                    
                    # Card Body
                    html_div(className="card-body p-4", children=[
                        # Section: Key Parameters
                        html_div(children=[
                            html_h5(className="d-flex align-items-center mb-3", children=[
                                html_i(className="bi bi-gear-fill me-2", style=Dict(:color => COLOR_SCHEME[:primary])),
                                html_span("Key Financial Parameters", style=Dict(
                                    :fontWeight => "600", 
                                    :color => COLOR_SCHEME[:primary],
                                    :fontSize => "1.1rem"
                                ))
                            ]),
                            
                            # ----- Single Value Inputs -----
                            html_div(className="row g-3 mb-4", children=[
                                # Management Fee
                                html_div(className="col-12 col-md-4", children=[
                                    html_div(className="form-floating", children=[
                                        dcc_input(
                                            id="fee", 
                                            type="number", 
                                            value=defaults[:fee]*100,
                                            step=0.05, 
                                            min=0,
                                            className="form-control",
                                            style=Dict(
                                                :height => "calc(3.5rem + 2px)",
                                                :paddingTop => "1.625rem",
                                                :paddingBottom => "0.625rem",
                                                :fontSize => "1.1rem",
                                                :fontWeight => "500"
                                            )
                                        ),
                                        html_label("Mgmt Fee (%)", 
                                            style=Dict(:paddingLeft => "0.75rem")
                                        )
                                    ])
                                ]),
                                # Initial AUM
                                html_div(className="col-12 col-md-4", children=[
                                    html_div(className="form-floating", children=[
                                        dcc_input(
                                            id="aum0", 
                                            type="number", 
                                            value=defaults[:aum0]/1e6,
                                            step=10, 
                                            min=0,
                                            className="form-control",
                                            style=Dict(
                                                :height => "calc(3.5rem + 2px)",
                                                :paddingTop => "1.625rem",
                                                :paddingBottom => "0.625rem",
                                                :fontSize => "1.1rem",
                                                :fontWeight => "500"
                                            )
                                        ),
                                        html_label("AUM/family (mi)", 
                                            style=Dict(:paddingLeft => "0.75rem")
                                        )
                                    ])
                                ]),
                                # AUM Growth
                                html_div(className="col-12 col-md-4", children=[
                                    html_div(className="form-floating", children=[
                                        dcc_input(
                                            id="aum_growth", 
                                            type="number", 
                                            value=defaults[:aum_growth]*100,
                                            step=1, 
                                            min=0,
                                            className="form-control",
                                            style=Dict(
                                                :height => "calc(3.5rem + 2px)",
                                                :paddingTop => "1.625rem",
                                                :paddingBottom => "0.625rem",
                                                :fontSize => "1.1rem",
                                                :fontWeight => "500"
                                            )
                                        ),
                                        html_label("Growth/Year (%)", 
                                            style=Dict(:paddingLeft => "0.75rem")
                                        )
                                    ])
                                ]),
                                # Partner A %
                                html_div(className="col-6 col-md-3", children=[
                                    html_div(className="form-floating", children=[
                                        dcc_input(
                                            id="shareA",
                                            type="number",
                                            value=90,      # Partner A default
                                            step=1,
                                            min=0, max=100,
                                            className="form-control",
                                            style=Dict(
                                                :height => "calc(3.5rem + 2px)",
                                                :paddingTop => "1.625rem",
                                                :paddingBottom => "0.625rem",
                                                :fontSize => "1.1rem",
                                                :fontWeight => "500"
                                            )
                                        ),
                                        html_label("Partner A (%)", style=Dict(:paddingLeft=>"0.75rem"))
                                    ])
                                ]),
                                # Partner B %
                                html_div(className="col-6 col-md-3", children=[
                                    html_div(className="form-floating", children=[
                                        dcc_input(
                                            id="shareB",
                                            type="number",
                                            value=10,      # Partner B default
                                            step=1,
                                            min=0, max=100,
                                            className="form-control",
                                            style=Dict(
                                                :height => "calc(3.5rem + 2px)",
                                                :paddingTop => "1.625rem",
                                                :paddingBottom => "0.625rem",
                                                :fontSize => "1.1rem",
                                                :fontWeight => "500"
                                            )
                                        ),
                                        html_label("Partner B (%)", style=Dict(:paddingLeft=>"0.75rem"))
                                    ])
                                ])
                            ])
                        ]),
                        
                        html_hr(style=Dict(:margin => "1.5rem 0", :opacity => "0.1")),
                        
                        # Section: Year-by-Year Inputs
                        html_div(children=[
                            html_h5(className="d-flex align-items-center mb-3", children=[
                                html_i(className="bi bi-table me-2", style=Dict(:color => COLOR_SCHEME[:primary])),
                                html_span("Year-by-Year Projections", style=Dict(
                                    :fontWeight => "600", 
                                    :color => COLOR_SCHEME[:primary],
                                    :fontSize => "1.1rem"
                                ))
                            ]),
                            
                            html_div(className="bg-light p-3 rounded-3 mb-3", style=Dict(:fontSize => "0.875rem"), children=[
                                html_div(className="d-flex align-items-center", children=[
                                    html_i(className="bi bi-info-circle-fill me-2", style=Dict(:color => COLOR_SCHEME[:primary])),
                                    html_span("Values below are in millions (except Families).")
                                ])
                            ]),
                            
                            # Data Table
                            dash_datatable(
                                id="input_table",
                                columns=[
                                    Dict("name"=>"Year", "id"=>"Year", "type"=>"numeric"),
                                    Dict("name"=>"Families", "id"=>"Families", "type"=>"numeric"),
                                    Dict("name"=>"Salary", "id"=>"Salary", "type"=>"numeric", "format"=>Dict("specifier"=>".2f")),
                                    Dict("name"=>"Rent", "id"=>"Rent", "type"=>"numeric", "format"=>Dict("specifier"=>".2f")),
                                    Dict("name"=>"Tech", "id"=>"Tech", "type"=>"numeric", "format"=>Dict("specifier"=>".3f")),
                                    Dict("name"=>"Legal", "id"=>"Legal", "type"=>"numeric", "format"=>Dict("specifier"=>".3f")),
                                    Dict("name"=>"Marketing", "id"=>"Marketing", "type"=>"numeric", "format"=>Dict("specifier"=>".2f"))
                                ],
                                data=[
                                    Dict("Year"=>1, "Families"=>1.5, "Salary"=>0.0, "Rent"=>0.0, "Tech"=>0.10, "Legal"=>0.012, "Marketing"=>0.10),
                                    Dict("Year"=>2, "Families"=>4.0, "Salary"=>0.5, "Rent"=>0.1, "Tech"=>0.105, "Legal"=>0.015, "Marketing"=>0.11),
                                    Dict("Year"=>3, "Families"=>8.0, "Salary"=>1.0, "Rent"=>0.2, "Tech"=>0.11, "Legal"=>0.016, "Marketing"=>0.12),
                                    Dict("Year"=>4, "Families"=>10.0, "Salary"=>1.25, "Rent"=>0.2, "Tech"=>0.116, "Legal"=>0.017, "Marketing"=>0.13),
                                    Dict("Year"=>5, "Families"=>12.0, "Salary"=>1.5, "Rent"=>0.24, "Tech"=>0.122, "Legal"=>0.018, "Marketing"=>0.14)
                                ],
                                editable=true,
                                style_cell=Dict(
                                    :minWidth => "80px",
                                    :textAlign => "right",
                                    :padding => "12px 8px",
                                    :fontFamily => "'Montserrat', sans-serif",
                                    :fontSize => "0.9rem"
                                ),
                                style_header=Dict(
                                    :backgroundColor => COLOR_SCHEME[:primary],
                                    :color => "white",
                                    :fontWeight => "600",
                                    :textAlign => "center",
                                    :padding => "16px 8px"
                                ),
                                style_data_conditional=[
                                    Dict(
                                        "if" => Dict("column_id" => "Year"),
                                        "fontWeight" => "600",
                                        "backgroundColor" => "#f8f9fa",
                                        "textAlign" => "center"
                                    ),
                                    Dict(
                                        "if" => Dict("row_index" => 4),  # Year 5
                                        "backgroundColor" => "rgba(219, 234, 254, 0.3)" # Light blue highlight
                                    )
                                ],
                                style_table=Dict(
                                    :overflowX => "auto",
                                    :borderRadius => "0.5rem",
                                    :boxShadow => "0 0 15px rgba(0,0,0,0.05)"
                                )
                            ),
                            
                            # Error Message
                            html_div(id="err_msg", style=Dict(
                                :color => COLOR_SCHEME[:danger], 
                                :fontSize => "0.875rem",
                                :marginTop => "0.75rem",
                                :fontWeight => "500",
                                :display => "flex",
                                :alignItems => "center",
                                :gap => "0.5rem"
                            ))
                        ]),
                        
                        # Run Button
                        html_div(className="mt-4", children=[
                            html_button(className="btn btn-primary btn-lg w-100", children=[
                                html_i(className="bi bi-calculator me-2"),
                                "Calculate Valuation"
                            ], 
                            id="run_btn", 
                            n_clicks=0,
                            style=Dict(
                                :padding => "1rem 1.5rem",
                                :fontSize => "1.1rem"
                            ))
                        ])
                    ])
                ]),
                
                # Methodology Card
                html_div(className="card shadow", children=[
                    html_div(className="card-header card-header-accent d-flex align-items-center", children=[
                        html_i(className="bi bi-info-circle me-2"),
                        html_h4("Methodology", style=Dict(:margin => "0", :fontWeight => "600", :fontSize => "1.25rem"))
                    ]),
                    
                    html_div(className="card-body p-4", children=[
                        html_p([
                            "This model projects financial performance based on ",
                            html_strong("user-defined growth assumptions"),
                            " across a 5-year period."
                        ], style=Dict(:fontSize => "0.95rem")),
                        html_p([
                            "The valuation uses a discounted cash flow (DCF) methodology with revenue driven by ",
                            html_strong("AUM × fee rate"),
                            " and comprehensive expense modeling."
                        ], style=Dict(:fontSize => "0.95rem")),
                        html_div(className="bg-light p-3 rounded-3 mt-3", style=Dict(:fontSize => "0.875rem"), children=[
                            html_div(className="d-flex", children=[
                                html_i(className="bi bi-lightbulb-fill me-2 mt-1", style=Dict(:color => COLOR_SCHEME[:highlight])),
                                html_span("Adjust the input parameters to run different scenarios and compare results.")
                            ])
                        ])
                    ])
                ])
            ]),
            
            # Right Column - Results
            html_div(className="col-12 col-lg-7 col-xl-8", children=[
                # Results Tables Card
                html_div(className="card shadow mb-4", children=[
                    html_div(className="card-header d-flex align-items-center", children=[
                        html_i(className="bi bi-table me-2"),
                        html_h4("Financial Projections", style=Dict(:margin => "0", :fontWeight => "600", :fontSize => "1.25rem"))
                    ]),
                    
                    html_div(className="card-body p-4", children=[
                        # Results Table
                        html_h5("5-Year Detailed Financial Projection (BRL Millions)", 
                            style=Dict(
                                :fontWeight => "600", 
                                :marginBottom => "1rem",
                                :color => COLOR_SCHEME[:primary],
                                :fontSize => "1.1rem",
                                :display => "flex",
                                :alignItems => "center"
                            ), children=[
                                html_i(className="bi bi-currency-dollar me-2")
                            ]
                        ),
                        
                        dash_datatable(
                            id="table",
                            style_cell=Dict(
                                :minWidth => "80px",
                                :padding => "12px 8px",
                                :fontFamily => "'Montserrat', sans-serif",
                                :fontSize => "0.95rem",
                                :textAlign => "right"
                            ),
                            style_header=Dict(
                                :backgroundColor => "#f1f5f9",
                                :fontWeight => "600",
                                :textAlign => "center",
                                :padding => "16px 8px",
                                :borderTop => "1px solid $(COLOR_SCHEME[:border])",
                                :borderBottom => "2px solid $(COLOR_SCHEME[:border])"
                            ),
                            style_data_conditional=[
                                Dict(
                                    "if" => Dict("column_id" => "Year"),
                                    "fontWeight" => "600",
                                    "backgroundColor" => "#f8f9fa",
                                    "textAlign" => "center"
                                ),
                                Dict(
                                    "if" => Dict("column_id" => "NetIncome"),
                                    "fontWeight" => "600",
                                    "color" => COLOR_SCHEME[:accent]
                                ),
                                Dict(
                                    "if" => Dict("column_id" => "FCF"),
                                    "fontWeight" => "600",
                                    "color" => COLOR_SCHEME[:primary]
                                ),
                                Dict(
                                    "if" => Dict("row_index" => 4),  # Year 5
                                    "backgroundColor" => "rgba(219, 234, 254, 0.3)" # Light blue highlight
                                )
                            ],
                            style_table=Dict(
                                :overflowX => "auto",
                                :boxShadow => "0 0 15px rgba(0,0,0,0.05)"
                            )
                        )
                    ])
                ]),
                # Partner Share Card
                html_div(className="card shadow mb-4", children=[
                    html_div(className="card-header d-flex align-items-center", children=[
                        html_i(className="bi bi-people me-2"),
                        html_h4("Partner Cash‑Flow Share (BRL Thousands)", style=Dict(:margin=>"0", :fontWeight=>"600", :fontSize=>"1.25rem"))
                    ]),
                    html_div(className="card-body p-4", children=[
                        dash_datatable(
                            id="partner_table",
                            data = Vector{Dict}(),           # start empty
                            columns = Vector{Dict}(),        # start empty
                            style_cell=Dict(
                                :minWidth=>"80px",
                                :padding=>"12px 8px",
                                :fontFamily=>"'Montserrat', sans-serif",
                                :fontSize=>"0.95rem",
                                :textAlign=>"right"
                            ),
                            style_header=Dict(
                                :backgroundColor=>"#f1f5f9",
                                :fontWeight=>"600",
                                :textAlign=>"center",
                                :padding=>"16px 8px"
                            ),
                            style_table=Dict(:overflowX=>"auto")
                        )
                    ])
                ]),
                # Charts Row
                html_div(className="row", children=[
                    # AUM Chart Card
                    html_div(className="col-12 col-xl-6 mb-4", children=[
                        html_div(className="card shadow h-100", children=[
                            html_div(className="card-header d-flex align-items-center", children=[
                                html_i(className="bi bi-bar-chart-line-fill me-2"),
                                html_h5("Assets Under Management", style=Dict(:margin => "0", :fontWeight => "600", :fontSize => "1.1rem"))
                            ]),
                            html_div(className="card-body p-3", children=[
                                dcc_graph(id="aum_plot")
                            ])
                        ])
                    ]),
                    
                    # Revenue Chart Card
                    html_div(className="col-12 col-xl-6 mb-4", children=[
                        html_div(className="card shadow h-100", children=[
                            html_div(className="card-header d-flex align-items-center", children=[
                                html_i(className="bi bi-graph-up me-2"),
                                html_h5("Revenue & Net Income", style=Dict(:margin => "0", :fontWeight => "600", :fontSize => "1.1rem"))
                            ]),
                            html_div(className="card-body p-3", children=[
                                dcc_graph(id="rev_plot")
                            ])
                        ])
                    ]),
                    
                    # FCF Chart Card 
                    html_div(className="col-12 mb-4", children=[
                        html_div(className="card shadow", children=[
                            html_div(className="card-header d-flex align-items-center", children=[
                                html_i(className="bi bi-cash-coin me-2"),
                                html_h5("Cumulative Free Cash Flow", style=Dict(:margin => "0", :fontWeight => "600", :fontSize => "1.1rem"))
                            ]),
                            html_div(className="card-body p-3", children=[
                                dcc_graph(id="fcf_plot")
                            ])
                        ])
                    ])
                ])
            ])
        ]),
        
        # Footer
        html_div(className="mt-4 text-center", style=Dict(:color => COLOR_SCHEME[:text_light], :fontSize => "0.9rem"), children=[
            html_p(["MFO Valuation • ", html_i(className="bi bi-shield-check"), " Financial Analysis Dashboard"])
        ])
    ])
])

# ------------- Helper to parse CSV -> Vector ---------------
csvvec(txt, factor=1.0) = [parse(Float64, x)*factor for x in split(strip(txt), ',')]

# robust conversion: accepts Real, String, or Missing
to_float(x) = x === missing ? throw(ArgumentError("missing")) : 
              x isa Real    ? float(x) :
              parse(Float64, String(x))

#
# --- Synchronise partner share inputs so they always add to 100 ---
callback!(
    app,
    Output("shareA", "value"), Output("shareB", "value"),
    Input("shareA", "value"), Input("shareB", "value")
) do a, b
    ctx = Dash.callback_context()           # which input changed?
    if length(ctx.triggered) == 0
        return Dash.no_update(), Dash.no_update()
    end
    trig = split(ctx.triggered[1][:prop_id], ".")[1]
    if trig == "shareA" && a !== nothing
        return a, max(0, 100 - a)
    elseif trig == "shareB" && b !== nothing
        return max(0, 100 - b), b
    else
        return Dash.no_update(), Dash.no_update()
    end
end

# ------------- Callback: run valuation + update UI ---------
callback!(
    app, 
    Output("table","data"), Output("table","columns"),
    Output("aum_plot","figure"), Output("rev_plot","figure"),
    Output("fcf_plot","figure"),
    Output("partner_table","data"), Output("partner_table","columns"),
    Output("err_msg","children"),
    Output("stat_families","children"), Output("stat_aum","children"),
    Output("stat_revenue","children"), Output("stat_fcf","children"),
    Input("run_btn","n_clicks"),
    State("fee","value"), State("aum0","value"), State("aum_growth","value"),
    State("input_table","data"),
    State("shareA","value"), State("shareB","value")
) do _, fee_pct, aum0_mi, grow_pct, table_data, shareA, shareB

    fee  = fee_pct/100
    aum0 = aum0_mi*1e6
    grow = grow_pct/100

    # Initialize these variables outside the try block
    local df = nothing
    local fam = nothing
    local aum_mi = nothing
    local revenue_mi = nothing
    local netinc_mi = nothing
    local cum_fcf_mi = nothing
    local yrs = nothing
    local empty_fig_json = Dict("data"=>[], "layout"=>Dict())  # reusable blank fig
    local dcf_val = nothing

    try
        fam   = [to_float(row["Families"])               for row in table_data]
        sal   = [to_float(row["Salary"]   ) * 1e6        for row in table_data]
        rent  = [to_float(row["Rent"]     ) * 1e6        for row in table_data]
        tech  = [to_float(row["Tech"]     ) * 1e6        for row in table_data]
        legal = [to_float(row["Legal"]    ) * 1e6        for row in table_data]
        mkt   = [to_float(row["Marketing"]) * 1e6        for row in table_data]

        # run projection
        df, dcf_val = project_mfo_with_vectors("WebRun";
            management_fee = fee,
            families_vec   = fam,
            aum_growth     = grow,
            initial_aum_per_family = aum0,
            salary_vec = sal, rent_vec = rent, tech_vec = tech,
            legal_vec = legal, marketing_vec = mkt
        )

        # ----- Add Taxes and Total Expenses columns --------------------------
        # Taxes = EBITDA - NetIncome = Revenue - OpCosts - NetIncome
        df[:, :Taxes] = df.Revenue .- df.OpCosts .- df.NetIncome
        df[:, :TotalExp] = df.OpCosts

        # Only calculate these if we have a valid dataframe
        if df !== nothing
            # build figures (values in millions)
            yrs          = df.Year
            aum_mi       = df.TotalAUM ./ 1e6
            revenue_mi   = df.Revenue   ./ 1e6
            netinc_mi    = df.NetIncome ./ 1e6
            cum_fcf_mi   = cumsum(df.FCF) ./ 1e6
        end
    catch e
        empty_tbl  = Vector{Dict{String,Any}}()  # []
        empty_cols = Vector{Dict{String,Any}}()  # []

        # Return all outputs with empty content and error message (12 items)
        return empty_tbl, empty_cols,
               empty_fig_json, empty_fig_json, empty_fig_json,
               empty_tbl, empty_cols,
               html_div([html_i(className="bi bi-exclamation-triangle-fill me-2"),
                         "Error: Non-numeric or missing data in table."]),
               "—", "—", "—", "—"
    end

    if df === nothing
        empty_tbl  = Vector{Dict{String,Any}}()
        empty_cols = Vector{Dict{String,Any}}()
        # Return all outputs with empty content and error message (12 items)
        return empty_tbl, empty_cols,
               empty_fig_json, empty_fig_json, empty_fig_json,
               empty_tbl, empty_cols,
               html_div([html_i(className="bi bi-exclamation-triangle-fill me-2"),
                         "Unexpected error in calculation."]),
               "—", "—", "—", "—"
    end

    # create Dash‑compatible table (millions except Year/Families)
    df_pretty = in_millions(df)
    tbl_cols  = [
        Dict("name"=>"Year", "id"=>"Year", "type"=>"numeric"),
        Dict("name"=>"Families", "id"=>"Families", "type"=>"numeric", "format"=>Dict("specifier"=>".1f")),
        Dict("name"=>"AUM", "id"=>"TotalAUM", "type"=>"numeric", "format"=>Dict("specifier"=>",.2f")),
        Dict("name"=>"Revenue", "id"=>"Revenue", "type"=>"numeric", "format"=>Dict("specifier"=>",.2f")),
        Dict("name"=>"Taxes", "id"=>"Taxes", "type"=>"numeric", "format"=>Dict("specifier"=>",.2f")),
        Dict("name"=>"Expenses", "id"=>"TotalExp", "type"=>"numeric", "format"=>Dict("specifier"=>",.2f")),
        Dict("name"=>"Net Income", "id"=>"NetIncome", "type"=>"numeric", "format"=>Dict("specifier"=>",.2f")),
        Dict("name"=>"FCF", "id"=>"FCF", "type"=>"numeric", "format"=>Dict("specifier"=>",.2f"))
    ]
    tbl_data  = [Dict(string(k)=>v for (k,v) in pairs(row)) for row in eachrow(df_pretty)]

    # ---- Summary stats ----
    # Valuation (DCF today)
    if dcf_val >= 1e9
        stat_families = string(round(dcf_val/1e9; digits=1), "B")
    else
        stat_families = string(round(dcf_val/1e6; digits=0), "M")
    end
    # Fix for the AUM formatting to avoid integer conversion errors
    if aum_mi[end] >= 1000
        # For values over 1000 million, show as billions with one decimal place
        aum_value = round(aum_mi[end] / 1000, digits=1)
        stat_aum = string(aum_value, "B")
    else
        # For smaller values, round to nearest million without decimal places
        aum_value = round(aum_mi[end], digits=0)
        stat_aum = string(Int(aum_value), "M")
    end
    stat_revenue = string(round(revenue_mi[end], digits=1), "M")
    stat_fcf = string(round(cum_fcf_mi[end], digits=1), "M")

    # --- Partner split -----------------------
    if abs(shareA + shareB - 100) > 1e-6
        return tbl_data, tbl_cols,
               empty_fig_json, empty_fig_json, empty_fig_json,
               Vector{Dict}(), Vector{Dict}(),   # empty partner table
               html_div([html_i(className="bi bi-exclamation-triangle-fill me-2"),
                         "Partner shares must sum to 100%."]),
               stat_families, stat_aum, stat_revenue, stat_fcf
    end

    partA = shareA / 100
    partB = shareB / 100
    part_tbl_cols = [
        Dict("name"=>"Year","id"=>"Year"),
        Dict("name"=>"P. A (Yearly)","id"=>"A",  "format"=>Dict("specifier"=>",.0f")),
        Dict("name"=>"P. B (Yearly)","id"=>"B",  "format"=>Dict("specifier"=>",.0f")),
        Dict("name"=>"P. A (Monthly)","id"=>"Am",     "format"=>Dict("specifier"=>",.0f")),
        Dict("name"=>"P. B (Monthly)","id"=>"Bm",     "format"=>Dict("specifier"=>",.0f"))
    ]
    part_tbl_data = [
        Dict("Year"=>y,
             "A"=>round(fcf*partA/1e3; digits=0),
             "B"=>round(fcf*partB/1e3; digits=0),
             "Am"=>round(fcf*partA/12/1e3; digits=0),
             "Bm"=>round(fcf*partB/12/1e3; digits=0)
        ) for (y,fcf) in zip(yrs, df.FCF)
    ]

    # Ensure partner table columns/data are new JSON-serialisable copies
    partner_cols = [Dict("name"=>c["name"], "id"=>c["id"]) for c in part_tbl_cols]
    partner_data = [Dict(string(k)=>v for (k,v) in pairs(r)) for r in part_tbl_data]

    # Chart templates and formatting
    chart_template = Dict(
        :paper_bgcolor => "white",
        :plot_bgcolor => "white",
        :font => Dict(:family => "Montserrat, sans-serif", :size => 12),
        :margin => Dict(:t => 20, :b => 40, :l => 40, :r => 20),
        :xaxis => Dict(
            :showgrid => true,
            :gridcolor => "#f0f0f0",
            :tickmode => "array",
            :tickvals => yrs,
            :tickfont => Dict(:size => 12, :family => "Montserrat, sans-serif"),
            :title => Dict(:font => Dict(:size => 14, :family => "Montserrat, sans-serif"))
        ),
        :yaxis => Dict(
            :showgrid => true,
            :gridcolor => "#f0f0f0",
            :tickfont => Dict(:size => 12, :family => "Montserrat, sans-serif"),
            :title => Dict(:font => Dict(:size => 14, :family => "Montserrat, sans-serif"))
        ),
        :hoverlabel => Dict(:font => Dict(:family => "Montserrat, sans-serif"))
    )

    # helper to merge common layout traits with chart‑specific ones
    make_layout(additions::Dict) = Layout(merge(chart_template, additions))

    # AUM Chart with gradient bars - Fix dict keys to use Symbols instead of Strings
    fig_aum = Plot(
        bar(
            x=yrs,
            y=aum_mi,
            marker=Dict(
                :color => COLOR_SCHEME[:chart1],
                :line => Dict(:width => 1, :color => COLOR_SCHEME[:chart1])
            ),
            # Fixed text formatting to avoid integer conversion issues
            text=[string(round(x, digits=0)) * "M" for x in aum_mi],
            textposition="auto",
            hovertemplate="<b>Year %{x}</b><br>AUM: %{y:.1f}M<extra></extra>"
        ),
        make_layout(Dict(
            :xaxis => Dict(:title => "Year", :tickmode => "array", :tickvals => yrs),
            :yaxis => Dict(:title => "AUM (Millions)", :showgrid => true, :gridcolor => "#f0f0f0"),
            :height => 350
        ))
    )

    # Revenue vs Net Income Chart - Fix dict keys to use Symbols
    fig_rev = Plot(
        [
            bar(
                x=yrs,
                y=revenue_mi,
                name="Revenue",
                marker=Dict(:color => COLOR_SCHEME[:chart1]),
                hovertemplate="<b>Year %{x}</b><br>Revenue: %{y:.2f}M<extra></extra>"
            ),
            bar(
                x=yrs,
                y=netinc_mi,
                name="Net Income",
                marker=Dict(:color => COLOR_SCHEME[:chart2]),
                hovertemplate="<b>Year %{x}</b><br>Net Income: %{y:.2f}M<extra></extra>"
            )
        ],
        make_layout(Dict(
            :barmode => "group",
            :xaxis => Dict(:title => "Year", :tickmode => "array", :tickvals => yrs),
            :yaxis => Dict(:title => "Amount (Millions)"),
            :legend => Dict(
                :orientation => "h",
                :yanchor => "bottom", :y => 1.02,
                :xanchor => "right", :x => 1
            ),
            :height => 350
        ))
    )

    # Cumulative FCF Chart - Fix dict keys to use Symbols
    fig_fcf = Plot(
        [
            scatter(
                x=yrs,
                y=cum_fcf_mi,
                mode="lines+markers",
                marker=Dict(
                    :color => COLOR_SCHEME[:chart3],
                    :size => 10,
                    :line => Dict(:width => 2, :color => "white")
                ),
                line=Dict(:width => 3, :color => COLOR_SCHEME[:chart3], :shape => "spline"),
                fill="tozeroy",
                fillcolor="rgba(245, 158, 11, 0.1)",
                name="Cumulative FCF",
                hovertemplate="<b>Year %{x}</b><br>Cumulative FCF: %{y:.2f}M<extra></extra>"
            ),
            scatter(
                x=yrs,
                y=df.FCF ./ 1e6,
                mode="markers",
                marker=Dict(
                    :color => "rgba(245, 158, 11, 0.7)",
                    :size => 8,
                    :symbol => "circle"
                ),
                name="Annual FCF",
                hovertemplate="<b>Year %{x}</b><br>Annual FCF: %{y:.2f}M<extra></extra>"
            )
        ],
        make_layout(Dict(
            :xaxis => Dict(:title => "Year", :tickmode => "array", :tickvals => yrs),
            :yaxis => Dict(:title => "Free Cash Flow (Millions)", :zeroline => true, :zerolinecolor => "#e2e8f0"),
            :legend => Dict(
                :orientation => "h",
                :yanchor => "bottom", :y => 1.02,
                :xanchor => "right", :x => 1
            ),
            :height => 350
        ))
    )

    return tbl_data, tbl_cols, fig_aum, fig_rev, fig_fcf,
           partner_data, partner_cols, "",
           stat_families, stat_aum, stat_revenue, stat_fcf
end


# ------------- Run server --------------
run_server(app, "0.0.0.0", parse(Int, get(ENV, "PORT", "8080")); debug=false)

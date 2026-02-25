box::use(
  bslib[ bs_theme ],
  echarts4r[ e_common ],
  shiny[ bootstrapPage, div, h1, moduleServer, NS, reactive, renderUI, tags, uiOutput ],
)

e_common(
  font_family = "Google Sans",
  theme = "london"
  # theme = "forest"
)

box::use(
  app/logic/bar_plot,
  app/logic/data,
  app/logic/line_plot,

  app/view/chart,
  app/view/footer,
  app/view/plotSelector,
  app/view/projSelector,
  app/view/table,
  app/view/typeSelector,
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  bootstrapPage(
    theme = bs_theme(primary = "firebrick"),

    title = "Cloudflare R2 data tracking dashboard",
    h1("Cloudflare R2 data tracking dashboard"),

    div(
      class = "selector-container",
      projSelector$ui(ns("name")),
      typeSelector$ui(ns("type")),
      # plotSelector$ui(ns("plot")),
    ),

    div(
      class = "components-container",
      table$ui(ns("table")),
      chart$ui(ns("chart"))
    ),

    footer$ui(ns("footer"))
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {

    project <- projSelector$server("name")
    type <- typeSelector$server("type")
    # plot <- plotSelector$server("plot")
    fetched <- reactive(data$data_pull(project(), type()))

    table$server("table", data = fetched)
    chart$server(
      "chart", 
      data = fetched, 
      project = project, # "NASCAR" or "NHANES"
      type = type        # counted or raw
      # plot = plot        # bar or line
    )

    footer$server(
      "footer", 
      data = fetched,
      project = project, 
      type = type,
      start_day = "2020-01-01"
    )
  })
}

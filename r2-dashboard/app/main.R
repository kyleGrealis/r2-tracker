box::use(
  shiny[bootstrapPage, div, h1, moduleServer, NS, reactive, renderUI, tags, uiOutput],
)

box::use(
  app/logic/data,
  app/logic/bar_plot,
  app/logic/line_plot,

  app/view/chart,
  app/view/projSelector,
  app/view/plotSelector,
  app/view/table,
  app/view/typeSelector,
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  bootstrapPage(
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
    )
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
      "chart", data = fetched, 
      project = project, # "NASCAR" or "NHANES"
      type = type       # counted or raw
      # plot = plot        # bar or line
    )
  })
}

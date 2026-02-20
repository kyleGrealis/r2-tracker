# app/view/plotSelector.R

box::use(
  shiny[ div, moduleServer, NS, reactive, selectInput, tagList ],
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(
      selectInput(
        ns("plot"), "Plot type",
        choices = c("bar", "line"),
        selected = "bar"
      )
    )
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    reactive(input$plot)
  })
}

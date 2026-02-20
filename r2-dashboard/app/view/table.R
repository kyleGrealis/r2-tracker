# app/view/table.R

box::use(
  reactable[ reactable, reactableOutput, renderReactable ],
  shiny[ div, h3, moduleServer, NS, tagList ],
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  div(
    class = "component-box",
    reactableOutput(ns("table"))
  )
}

#' @param data Fetched data tibble of either raw or counted
#' @export
server <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    output$table <- renderReactable(
      # call the reactive "data()" inside the render function
      # to unwrap the reactive object
      reactable(data(), searchable = TRUE)
    )
  })
}

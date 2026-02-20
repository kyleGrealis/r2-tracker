# app/view/plot.R

box::use(
  echarts4r[ echarts4rOutput, renderEcharts4r ],
  shiny[ div, h3, moduleServer, NS, tagList ],
)

box::use(
  app/logic/bar_plot,
  app/logic/line_plot,
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  div(
    class = "component-box",
    echarts4rOutput(ns("plot"))
  )
}

#' @param data Fetched data tibble of either raw or counted
#' @param project Reactive object of either "NASCAR" or "NHANES"
#' @param type Reactive object of either "stats" or "raw"
#' @param plot Reactive object of either "bar" or "line"
#' @export
server <- function(id, data, project, type, plot) {
  moduleServer(id, function(input, output, session) {

    # call the reactives for data(), project(), and type()
    # inside the render function to unwrap the reactive object

    output$plot <- renderEcharts4r(
      if (type() == "stats") {
        bar_plot$bar_plot(data(), project())
      } else if (type() == "raw") {
        line_plot$line_plot(data(), project())
      }
    )
  })
}

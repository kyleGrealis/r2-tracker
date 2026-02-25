# app/view/footer.R

box::use(
  cranlogs[ cran_downloads ],
  dplyr[ pull, summarize ],
  scales[ comma ],
  shiny[ div, moduleServer, NS, observe, reactive, reactiveVal, renderText, selectInput, tagList, tags, textOutput ],
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  tagList(
    tags$footer(
      class = "footer",
      textOutput(ns("package")),
      tags$ul(
        tags$li(textOutput(ns("footer_text_1"))),
        tags$li(textOutput(ns("footer_text_2")))
      )
    )
  )
}

#' @param project Either NASCAR or NHANES
#' @param start_day String. Start of download period
#' @export
server <- function(id, data, project, type, start_day) {
  moduleServer(id, function(input, output, session) {

    name <- reactiveVal("nascaR.data")

    observe({
      if (project() == "nascar") {
        name("nascaR.data")
      } else {
        name("nhanesdata")
      }
    })

    pkg_downloads <- reactive({
      cran_downloads(name(), from = start_day) |> 
        summarize(total = sum(count, na.rm = TRUE)) |> 
        pull(total) |> 
        comma()
    })

    date <- format(strptime(start_day, "%Y-%m-%d"), "%B%e, %Y")

    output$package <- renderText({ sprintf("%s: ", name()) })

    output$footer_text_1 <- renderText({
      sprintf(
        "Total CRAN package downloads since %s: %s", 
        date, pkg_downloads()
      )
    })

    file_downloads <- reactive({
      if (type() == "stats") {
        data() |> 
          summarize(total = sum(unlist(count), na.rm = TRUE)) |> 
          pull(total) |> 
          comma()
      } else if (type() == "raw") {
        nrow(data()) |> comma()
      }
    })

    output$footer_text_2 <- renderText({
      sprintf("Total data file downloads: %s", file_downloads())
    })
  })
}

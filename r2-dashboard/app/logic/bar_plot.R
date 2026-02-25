# app/logic/bar_plot.R

box::use(
  echarts4r[ 
    e_charts, e_bar, e_legend, 
    e_x_axis, e_y_axis, e_title, e_tooltip
  ],
  dplyr[ mutate ],
  htmlwidgets[ JS ],
  stringr[ str_remove ],
)

#' Create a bar chart of counted data
#' @param data Dataset object
#' @param project Either NASCAR or NHANES
bar_plot <- function(data, project) {

  if (project == "nascar") {
    name <- "nascaR.data"
  } else {
    name <- "nhanesdata"
  }

  chart <- data |> 
    mutate(file = str_remove(file, "_series")) |> 
    mutate(file = toupper(file)) |> 
    e_charts(x = file) |> 
    e_bar(
      count,
      color = "firebrick",
      itemStyle = list(
        borderWidth = 1.5,
        borderColor = "black",
        borderRadius = list(2,2,0,0)
      )
    ) |> 
    e_legend(show = FALSE) |> 
    e_y_axis(
      name = "Downloads",
      nameLocation = "middle",
      nameGap = 35,
      nameTextStyle = list(
        fontWeight = "bold",
        color = "black"
      )
    ) |>
    e_title(
      text = sprintf("Total %s File Type Downloads", name),
      subtext = "Since February 15, 2026"
    ) |> 
    e_tooltip(
      backgroundColor = "#e0e0e0",
      formatter = JS("
        function(params) {
          // using the index of 1 for mapping to y-axis
          // mapping: x: 0, y: 1
          return params.name + ': ' + params.value[1] + '<br> Downloads'
        }
      ")
    )

  # if (project == "nascar") chart |> e_x_axis(axisLabel = list(show = FALSE)) else chart
  chart
}


# test
# project <- "nascaR.data"
# dat_stats |> 
#   mutate(file = str_remove(file, "_series")) |> 
#   mutate(file = toupper(file)) |> 
#   e_charts(x = file) |> 
#   e_bar(count) |> 
#   e_legend(show = FALSE) |> 
#   # e_axis_labels(y = "Downloads") |> 
#   e_y_axis(
#     name = "Downloads",
#     nameLocation = "middle",
#     nameGap = 35,
#     nameTextStyle = list(
#       fontWeight = "bold",
#       color = "black"
#     )
#   ) |>
#   e_y_axis(axisLabel = list(position = "bottom")) |> 
#   e_title(
#     text = sprintf("Total %s File Type Downloads", project),
#     subtext = "Since February 15, 2026"
#   )

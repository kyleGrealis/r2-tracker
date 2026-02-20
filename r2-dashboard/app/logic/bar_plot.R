# app/logic/bar_plot.R

box::use(
  echarts4r[ e_charts, e_bar, e_legend, e_x_axis, e_y_axis, e_theme, e_title, e_tooltip ],
  dplyr[ mutate ],
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
    e_bar(count) |> 
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
    e_theme("london") |> 
    e_tooltip()

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

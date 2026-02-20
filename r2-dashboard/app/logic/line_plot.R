# app/logic/line_plot.R

box::use(
  echarts4r[ e_charts, e_line, e_legend, e_x_axis, e_y_axis, e_theme, e_title, e_tooltip ],
  dplyr[ arrange, group_by, mutate, row_number ],
  stringr[ str_remove ],
)

#' Create a line chart of raw data over time
#' @param data Dataset object
#' @param project Either NASCAR or NHANES
line_plot <- function(data, project) {

  if (project == "nascar") {
    name <- "nascaR.data"
  } else {
    name <- "nhanesdata"
  }

  chart <- data |> 
    mutate(file = toupper(file)) |> 
    mutate(time = as.Date(unlist(time), format = "%Y-%m-%d")) |> 
    arrange(time) |> 
    mutate(
      count = row_number(file),
      .by = file
    ) |> 
    group_by(file) |> 
    e_charts(time) |> 
    e_line(serie = count) |> 
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
      text = sprintf("%s File Type Downloads", name),
      subtext = "Since February 15, 2026"
    ) |> 
    e_theme("london") |> 
    e_tooltip()

  # if (project == "nascar") chart |> e_x_axis(axisLabel = list(show = FALSE)) else chart
  chart
}


# test
# project <- "nhanes"
# name <- "nhanesdata"
# dat_raw |> 
#   mutate(file = toupper(file)) |> 
#   mutate(time = as.Date(unlist(time), format = "%Y-%m-%d")) |> 
#   arrange(time) |> 
#   mutate(
#     count = row_number(file),
#     .by = file
#   ) |> 
#   group_by(file) |> 
#   e_charts(time) |> 
#   e_line(serie = count) |> 
#   e_y_axis(
#     name = "Downloads",
#     nameLocation = "middle",
#     nameGap = 35,
#     nameTextStyle = list(
#       fontWeight = "bold",
#       color = "black"
#     )
#   ) |>
#   e_title(
#     text = sprintf("%s File Type Downloads", name),
#     subtext = "Since February 15, 2026"
#   ) |> 
#   e_theme("london") |> 
#   e_tooltip()



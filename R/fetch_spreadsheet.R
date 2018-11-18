#' @title Cook spreadsheet
#' @description FUNCTION_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @examples 
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @rdname fetch_spreadsheet
#' @export 
#' @importFrom httr GET content
#' @importFrom rvest html_table
fetch_spreadsheet <- function(){
  cook_html <- httr::GET('https://docs.google.com/spreadsheets/d/1WxDaxD5az6kdOjJncmGph37z0BPNhV1fNAH_g7IkpC0/htmlview?sle=true#gid=326900537')
  cook_content <- httr::content(cook_html)
  cook_table <- rvest::html_table(cook_content)[[1]]
  cook_data <- cook_table[-c(1:4),]
  names(cook_data) <- cook_table[1,]
  names(cook_data)[3] <- 'district'
  cook_data$state_district <- sprintf('%s_%s',cook_data$State,cook_data$district)
  cook_data
}

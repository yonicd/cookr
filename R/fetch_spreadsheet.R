#' @title Cook spreadsheet
#' @description FUNCTION_DESCRIPTION
#' @param cook_html response, object returned from GET call of the cook google spreadsheet.
#' @return OUTPUT_DESCRIPTION
#' @details Tinyurl address of cook google spreadsheet http://tinyurl.com/y9jxsgmt
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
fetch_spreadsheet <- function(cook_html){
  cook_content <- httr::content(cook_html)
  cook_table <- rvest::html_table(cook_content)[[1]]
  cook_data <- cook_table[-c(1:4),]
  names(cook_data) <- cook_table[1,]
  names(cook_data)[3] <- 'district'
  cook_data$state_district <- sprintf('%s_%s',cook_data$State,cook_data$district)
  cook_data
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param State PARAM_DESCRIPTION
#' @param district PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @examples 
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @seealso 
#'  \code{\link[httr]{GET}},\code{\link[httr]{content}}
#'  \code{\link[rvest]{html_table}}
#' @rdname fetch_history
#' @export 
#' @importFrom httr GET content
#' @importFrom rvest html_table
fetch_history <- function(State,district){
  
  d <- as.numeric(substr(district,nchar(district),nchar(district)))
  
  suffix <-'th'
  
  if(d%in%c(1))
    suffix <-'st'
  
  if(d%in%c(2))
    suffix <-'nd'
  
  if(d%in%c(3))
    suffix <-'rd'
  
  dat <- httr::GET(sprintf('https://ballotpedia.org/%s%%27s_%s%s_Congressional_District',State,district,suffix))
  dat_1 <- httr::content(dat)
  rvest::html_table(dat_1,fill=TRUE)
}

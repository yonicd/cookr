#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param raw_data PARAM_DESCRIPTION
#' @param idx PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @examples 
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @rdname fetch_districts
#' @export 
#' @importFrom tibble as_tibble
fetch_districts <- function(raw_data,idx){
  dat <- raw_data[idx,c(2,3,7,8,13,18)]
  dat[,3] <- as.numeric(gsub('\\,','',dat[,3]))
  dat[,4] <- as.numeric(gsub('\\,','',dat[,4]))
  dat$total <- apply(dat[,3:4],1,sum)
  dat$`Dem Margin` <- dat[,3]-dat[,4]
  dat$`Dem Margin (%)` <- 100*(dat[,3]-dat[,4])/dat$total
  dat <- dat[,c(1,2,6,3,4,5,7)]
  tibble::as_tibble(dat)
}

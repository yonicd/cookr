#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param dat PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @examples 
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @rdname parse_history
#' @export 
parse_history <- function(dat){
  tbls <- sapply(dat,function(x) grepl('General Election',names(x)[1]))
  dat <- dat[tbls]
  names(dat) <- sapply(dat,function(x) gsub('^(.*?)General Election, ','',names(x)[1]))
  sapply(dat,function(x) as.numeric(gsub('\\,','',x[grep('Total Votes',x[,1]),ncol(x)])))
}

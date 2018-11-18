#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param cook_clean PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @examples 
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @rdname cook_ballotpedia
#' @export 
#' @import dplyr
#' @import purrr
#' @importFrom stats quantile
#' @importFrom tidyr unnest
cook_ballotpedia <- function(cook_clean){
  
  cook_ballotopedia <- cook_clean%>%
    dplyr::mutate(
      history = purrr::map2(State,district,fetch_history)
    )
  
  cook_ballotopedia_parsed <- cook_ballotopedia%>%
    dplyr::filter(
      purrr::map_lgl(history,.f=function(x) length(x)>0)
    )%>%
    dplyr::mutate(
      results = purrr::map(history,parse_history)
    )
  
  cook_ballotopedia_parsed%>%
    dplyr::mutate(
      slack = purrr::map2(total,results,.f=function(o,e){
        x <- data.frame(t(stats::quantile(e-o,probs = c(0.05,0.5,0.95))))
        names(x) <- sprintf('slack_q%02d',c(5,50,95))
        x
      })
    )%>%
    tidyr::unnest(slack)
}

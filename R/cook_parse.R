#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param cook_data PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @examples 
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @rdname cook_open
#' @export 
#' @import dplyr
cook_open <- function(cook_data){
  
  cook_data%>%
    fetch_districts(which(!nzchar(cook_data[,5])))%>%
    dplyr::mutate(type = 'open')%>%
    dplyr::mutate(
      home_district = state_district
    )
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param cook_open_data PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @examples 
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @seealso 
#'  \code{\link[purrr]{map2}}
#'  \code{\link[tidyr]{unnest}}
#' @rdname cook_adjacent
#' @export 
#' @import dplyr
#' @importFrom purrr map2
#' @importFrom tidyr unnest
cook_adjacent <- function(cook_open_data){
  cook_adj  <- cook_open_data%>%
    dplyr::select(-home_district)%>%
    dplyr::mutate(
      state_id = state_names$id[match(State,state_names$name)],
      json_id = sprintf('%s%02d',state_id,as.numeric(district)),
      adj_districts = purrr::map2(json_id,state_id,.f=function(x,y){
        ret <- names(which(touching[which(row.names(touching)==x),]))
        ret <- gsub(sprintf('^%s',y),'',ret)
        as.character(as.numeric(ret))
      })
    )%>%
    dplyr::select(State,state_district,adj_districts)%>%
    tidyr::unnest()%>%
    dplyr::mutate(adjacent = sprintf('%s_%s',State,adj_districts))
  
  cook_adj_idx <- which(cook_data$state_district%in%cook_adj$adjacent)
  
  cook_data%>%
    fetch_districts(cook_adj_idx)%>%
    dplyr::mutate(type = 'adjacent')%>%
    dplyr::left_join(
      cook_adj%>%
        dplyr::select(home_district=state_district,state_district = adjacent),
      by = 'state_district'
    )
}

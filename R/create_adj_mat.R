#' @title FUNCTION_TITLE
#' @description District shp file to adj mat
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @examples 
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @seealso 
#'  \code{\link[geojsonio]{geojson_read}},\code{\link[geojsonio]{geojson_sp}}
#'  \code{\link[rgeos]{gTouches}}
#' @rdname create_adj_mat
#' @export 
#' @importFrom geojsonio geojson_read geojson_sp
#' @importFrom rgeos gTouches
create_adj_mat <- function(){
  json_url <- 'https://gist.githubusercontent.com/mbostock/4090846/raw/d534aba169207548a8a3d670c9c2cc719ff05c47/us-congress-113.json'
  cd_json <- geojsonio::geojson_read(json_url)
  class(cd_json) <- 'geo_list'
  cd_sp <- geojsonio::geojson_sp(cd_json)
  touching <- rgeos::gTouches(cd_sp, byid=TRUE)
  colnames(touching) <- rownames(touching) <- cd_sp$id
  touching
}

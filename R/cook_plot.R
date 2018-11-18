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
#' @rdname cook_plot
#' @export 
#' @import dplyr
#' @importFrom purrr map_dbl map
#' @importFrom tibble enframe
#' @importFrom tidyr unnest gather
#' @import ggplot2
#' @importFrom ggrepel geom_label_repel
#' @importFrom scales comma
cook_plot <- function(dat){
  
  plot_dat <- dat%>%
    dplyr::select(home_district,state_district,type,total,results)%>%
    dplyr::mutate(last_results = purrr::map_dbl(results,head,n=1),
                  results = purrr::map(results,tibble::enframe)
    )%>%
    tidyr::unnest(results)%>%
    dplyr::mutate(
      yr = substr(name,3,4),
      year = as.numeric(name),
      type_alpha = dplyr::if_else(type=='adjacent',0.8,1)
    )%>%
    dplyr::select(-last_results)%>%
    dplyr::filter(year>1990)
  
  new_dat <- plot_dat%>%
    dplyr::filter(year==2016)%>%
    dplyr::select(type,type_alpha,home_district,state_district,total,value)%>%
    tidyr::gather('year_f','value',-c(type,type_alpha,home_district,state_district))%>%
    dplyr::mutate(
      year=dplyr::if_else(year_f=='total',2018,2016),
      yr=substr(as.character(year),3,4),
      d = gsub('^(.*?)_','',state_district)
    )
  
  p <- plot_dat%>%
    ggplot2::ggplot(ggplot2::aes(
      x=year,
      y=value,
      group=state_district,
      colour=type,
      alpha=type,
      size=type)) + 
    ggplot2::geom_line() + 
    ggplot2::scale_colour_manual(values=c('black','blue')) +
    ggplot2::scale_alpha_discrete(range = c(0.5,1)) +
    ggplot2::scale_size_discrete(range = c(0.5,1)) +
    ggplot2::geom_line(data=new_dat,ggplot2::aes(linetype=type))+
    ggplot2::geom_point(data=new_dat%>%dplyr::filter(year==2018)) +
    ggplot2::geom_vline(xintercept=c(seq(1992,2018,4)),linetype=3,alpha=.3)+
    ggrepel::geom_label_repel(ggplot2::aes(label=d),
                              direction='y',
                              nudge_x = 2,
                              segment.size = 0.1,
                              segment.alpha = 0.5,
                              size=2,
                              alpha=1,
                              data=new_dat%>%
                                dplyr::filter(year==2018),
                              show.legend = FALSE)
  
  p <- p + 
    ggplot2::expand_limits(x = c(1990, 2022))+
    ggplot2::scale_x_continuous(
      breaks = c(2018,unique(plot_dat$year)),
      labels = c('18',unique(plot_dat$yr))
    ) +
    ggplot2::facet_wrap(~home_district,ncol=2) +
    ggplot2::scale_y_continuous(labels = scales::comma) +
    ggplot2::labs(
      title = 'Real Time Results Of Open Congressional District with History of Total Reported Votes',
      subtitle = sprintf('Date: %s\nBlue: Open Districts, Black: Adjacent Districts, Districts labelled at 2018\nVertical Lines Presidential Election Year',Sys.Date()),
      x='Year',
      y='Reported Total Votes',
      caption = sprintf('Sources:\nCook Political Report Spreadsheet %s (http://tinyurl.com/y9jxsgmt)\nBallotpedia (https://ballotpedia.org)',Sys.Date()),
      colour = 'District Type',
      size = 'District Type',
      alpha = 'District Type',
      linetype = 'District Type'
    )
  
  p +
    ggplot2::theme_bw() + 
    ggplot2::theme(
      legend.position = 'bottom',
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor.x = ggplot2::element_blank()
    )
}

library(purrr)
library(ggplot2)
library(spdep)
library(sp)

# District shp file to adj mat
  json_url <- 'https://gist.githubusercontent.com/mbostock/4090846/raw/d534aba169207548a8a3d670c9c2cc719ff05c47/us-congress-113.json'
  cd_json <- geojsonio::geojson_read(json_url)
  cd_sp <- geojsonio::geojson_sp(cd_json)
  touching <- rgeos::gTouches(cd_sp, byid=TRUE)
  colnames(touching) <- rownames(touching) <- cd_sp$id

  state_names <- readr::read_tsv('https://gist.githubusercontent.com/mbostock/4090846/raw/07e73f3c2d21558489604a0bc434b3a5cf41a867/us-state-names.tsv')

# Functions
  
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

parse_history <- function(dat){
  tbls <- sapply(dat,function(x) grepl('General Election',names(x)[1]))
  dat <- dat[tbls]
  names(dat) <- sapply(dat,function(x) gsub('^(.*?)General Election, ','',names(x)[1]))
  sapply(dat,function(x) as.numeric(gsub('\\,','',x[grep('Total Votes',x[,1]),ncol(x)])))
}

# Cook spreadsheet

cook_html <- httr::GET('https://docs.google.com/spreadsheets/d/1WxDaxD5az6kdOjJncmGph37z0BPNhV1fNAH_g7IkpC0/htmlview?sle=true#gid=326900537')
cook_content <- httr::content(cook_html)
cook_table <- rvest::html_table(cook_content)[[1]]
cook_data <- cook_table[-c(1:4),]
names(cook_data) <- cook_table[1,]
names(cook_data)[3] <- 'district'
cook_data$state_district <- sprintf('%s_%s',cook_data$State,cook_data$district)

# Filter open districts
open_districts_idx <- which(!nzchar(cook_data[,5]))

cook_open <- cook_data%>%
  fetch_districts(open_districts_idx)%>%
  dplyr::mutate(type = 'open')

cook_adj  <- cook_open%>%
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

cook_adjacent <- cook_data%>%
  fetch_districts(cook_adj_idx)%>%
  dplyr::mutate(type = 'adjacent')%>%
  dplyr::left_join(
    cook_adj%>%
      dplyr::select(home_district=state_district,state_district = adjacent),
    by = 'state_district'
  )

cook_clean <- dplyr::bind_rows(cook_open%>%
                                 dplyr::mutate(
                                   home_district = state_district
                                 ),cook_adjacent)

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

cook_ballotopedia_slack <- cook_ballotopedia_parsed%>%
  dplyr::mutate(
    slack = purrr::map2(total,results,.f=function(o,e){
      x <- data.frame(t(quantile(e-o,probs = c(0.05,0.5,0.95))))
      names(x) <- sprintf('slack_q%02d',c(5,50,95))
      x
    })
  )%>%
  tidyr::unnest(slack)

plot_dat <- cook_ballotopedia_slack%>%
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
  ggplot(aes(
    x=year,
    y=value,
    group=state_district,
    colour=type,
    alpha=type,
    size=type)) + 
  geom_line() + 
  scale_colour_manual(values=c('black','blue')) +
  scale_alpha_discrete(range = c(0.5,1)) +
  scale_size_discrete(range = c(0.5,1)) +
  geom_line(data=new_dat,aes(linetype=type))+
  geom_point(data=new_dat%>%dplyr::filter(year==2018)) +
  geom_vline(xintercept=c(seq(1992,2018,4)),linetype=3,alpha=.3)+
  ggrepel::geom_label_repel(aes(label=d),
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
    expand_limits(x = c(1990, 2022))+
    scale_x_continuous(
      breaks = c(2018,unique(plot_dat$year)),
      labels = c('18',unique(plot_dat$yr))
    ) +
    facet_wrap(~home_district,ncol=2) +
    scale_y_continuous(labels = scales::comma) +
    labs(
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

p <- p +
  theme_bw() + 
  theme(
    legend.position = 'bottom',
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank()
    )

ggsave(p,filename = sprintf('plots/cook_%s.png',strftime(Sys.Date(),format = '%Y_%m_%d')))

saveRDS(cook_html,file = sprintf('src_data/cook_spreadsheet_%s.rds',strftime(Sys.Date(),format = '%Y_%m_%d')))

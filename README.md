
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cookr

The goal of cookr is to track in real time the results of the 2018 US
congressional election by district using a live [google
spreatsheet](https://docs.google.com/spreadsheets/d/1WxDaxD5az6kdOjJncmGph37z0BPNhV1fNAH_g7IkpC0/htmlview?sle=true#gid=326900537)
populated by [Cook political report](https://www.cookpolitical.com/),
and add historical context of reported results using
[Ballotpedia](https://ballotpedia.org/).

The package locates which districts are still active and searches for
adjacent districts to get their restults too, using this [geojson
file](https://gist.githubusercontent.com/mbostock/4090846/raw/d534aba169207548a8a3d670c9c2cc719ff05c47/us-congress-113.json).

In the package there is a plotting function to vizualize the time
depedent results.

Sticking a pin in this is to have data to model in the future expected
voter turnout with higher frequency data.

## Installation

You can install cookr from github with:

``` r
# install.packages("remotes")
remotes::install_github("yonicd/cookr")
```

## Usage

### Load Library

``` r
library(cookr)
```

### Fetching The Spreadsheet

``` r
cook_data <- cookr::fetch_spreadsheet()
```

Peek at Data

``` r
cook_data%>%
  dplyr::glimpse()
#> Observations: 435
#> Variables: 18
#> $ `1`                   <int> 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15...
#> $ State                 <chr> "Alabama", "Alabama", "Alabama", "Alabam...
#> $ district              <chr> "1", "2", "3", "4", "5", "6", "7", "AL",...
#> $ `2018 Cook PVI Score` <chr> "R+15", "R+16", "R+16", "R+30", "R+18", ...
#> $ `2018 Winner`         <chr> "Bradley Byrne", "Martha Roby", "Mike Ro...
#> $ Party                 <chr> "R", "R", "R", "R", "R", "R", "D", "R", ...
#> $ `Dem Votes`           <chr> "88,365", "86,581", "83,748", "46,370", ...
#> $ `GOP Votes`           <chr> "152,308", "138,582", "147,481", "183,95...
#> $ `Other Votes`         <chr> "157", "419", "149", "222", "221", "137"...
#> $ `Dem %`               <chr> "36.7%", "38.4%", "36.2%", "20.1%", "38....
#> $ `GOP %`               <chr> "63.2%", "61.4%", "63.7%", "79.8%", "61....
#> $ `Other %`             <chr> "0.1%", "0.2%", "0.1%", "0.1%", "0.1%", ...
#> $ `Dem Margin`          <chr> "-26.6%", "-23.1%", "-27.5%", "-59.7%", ...
#> $ `2016 Clinton Margin` <chr> "-29.2%", "-31.7%", "-33.0%", "-62.5%", ...
#> $ `Swing vs. 2016 Prez` <chr> "2.6%", "8.6%", "5.5%", "2.8%", "10.7%",...
#> $ `Raw Votes vs. 2016`  <chr> "78.8%", "78.4%", "79.4%", "78.7%", "82....
#> $ `Final?`              <chr> "", "", "", "", "", "", "", "", "", "", ...
#> $ state_district        <chr> "Alabama_1", "Alabama_2", "Alabama_3", "...
```

Filter to open districts

``` r
open_districts <- cook_data%>%
  cookr::cook_open()
```

Find the adjacent districts

``` r
adjacent_districts <- open_districts%>%
  cookr::cook_adjacent()
```

Combine Data

``` r
districts <- dplyr::bind_rows(open_districts,adjacent_districts)
```

``` r
districts%>%
  dplyr::glimpse()
#> Observations: 15
#> Variables: 9
#> $ State          <chr> "California", "Georgia", "Utah", "California", ...
#> $ district       <chr> "21", "7", "4", "16", "20", "22", "23", "24", "...
#> $ state_district <chr> "California_21", "Georgia_7", "Utah_4", "Califo...
#> $ `Dem Votes`    <dbl> 48997, 140011, 128587, 73352, 156467, 92462, 65...
#> $ `GOP Votes`    <dbl> 51175, 140430, 129006, 56543, 0, 106240, 120687...
#> $ `Dem Margin`   <dbl> -2178, -419, -419, 16809, 156467, -13778, -5497...
#> $ total          <dbl> 100172, 280441, 257593, 129895, 156467, 198702,...
#> $ type           <chr> "open", "open", "open", "adjacent", "adjacent",...
#> $ home_district  <chr> "California_21", "Georgia_7", "Utah_4", "Califo...
```

Fetch Historical Results of the Districts From Ballotpedia

``` r
cook_history <- districts%>%
  cook_ballotpedia()
```

``` r
cook_history%>%
  dplyr::glimpse()
#> Observations: 14
#> Variables: 14
#> $ State          <chr> "California", "Georgia", "Utah", "California", ...
#> $ district       <chr> "21", "7", "4", "16", "20", "22", "23", "24", "...
#> $ state_district <chr> "California_21", "Georgia_7", "Utah_4", "Califo...
#> $ `Dem Votes`    <dbl> 48997, 140011, 128587, 73352, 156467, 92462, 65...
#> $ `GOP Votes`    <dbl> 51175, 140430, 129006, 56543, 0, 106240, 120687...
#> $ `Dem Margin`   <dbl> -2178, -419, -419, 16809, 156467, -13778, -5497...
#> $ total          <dbl> 100172, 280441, 257593, 129895, 156467, 198702,...
#> $ type           <chr> "open", "open", "open", "adjacent", "adjacent",...
#> $ home_district  <chr> "California_21", "Georgia_7", "Utah_4", "Califo...
#> $ history        <list> [[c("", "Current incumbentDavid Valadao Cook P...
#> $ results        <list> [<132408, 79377, 116283, 135979, 209815, 14266...
#> $ slack_q05      <dbl> 3193.90, -105913.80, -100614.10, -27777.10, -86...
#> $ slack_q50      <dbl> 59134.0, -46202.0, -12316.0, 21771.5, -41496.5,...
#> $ slack_q95      <dbl> 104960.40, 39847.80, 14046.80, 60452.10, 84875....
```

### Plotting

``` r
p <- cook_history%>%
  cook_plot()
#> Warning: Using alpha for a discrete variable is not advised.
#> Warning: Using size for a discrete variable is not advised.

p
```

![](README-unnamed-chunk-11-1.png)<!-- -->

### Saving

``` r
ggsave(p,filename = sprintf('plots/cook_%s.png',strftime(Sys.Date(),format = '%Y_%m_%d')))

saveRDS(cook_html,file = sprintf('src_data/cook_spreadsheet_%s.rds',strftime(Sys.Date(),format = '%Y_%m_%d')))
```

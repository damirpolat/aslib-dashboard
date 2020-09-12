FROM rocker/tidyverse:4.0.2

# system libraries of general use
RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \ 
		tzdata \
		gdebi-core \
		subversion \
		default-jdk \
		default-jre \
	&& R CMD javareconf		

# Download and install shiny server
RUN wget --no-verbose https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
		gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    . /etc/environment && \ 
    R -e "install.packages(c('shiny', 'rmarkdown'))"



# install R packages
RUN R -e "install.packages('shinyFiles')"
RUN R -e "install.packages('shinythemes')"
RUN R -e "install.packages('shinydashboard')"
RUN R -e "install.packages('rJava')"
RUN R -e "install.packages('devtools')"
RUN R -e "devtools::install_github('https://github.com/juba/scatterD3')"
RUN R -e "install.packages('plotly')"
RUN R -e "install.packages('htmlwidgets')"
RUN R -e "install.packages('plyr')"
RUN R -e "install.packages('dplyr')"
RUN R -e "install.packages('reshape2')"
RUN R -e "install.packages('Rcpp')"
RUN R -e "install.packages('mlr', dependencies = TRUE)"

# get aslib-r package from GitHub
RUN git clone --single-branch --branch farff https://github.com/coseal/aslib-r.git home/aslib-r
RUN R -e "devtools::install_local('./home/aslib-r/aslib')"

# copy app files to image
COPY shiny-server.sh /usr/bin/shiny-server.sh
RUN chmod +x /usr/bin/shiny-server.sh
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf
COPY project /srv/shiny-server/project
COPY app.R /srv/shiny-server/
COPY data /home/data

# select port
EXPOSE 3838

# allow permission
RUN sudo chown -R shiny:shiny /srv/shiny-server

CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/app.R', host='0.0.0.0', port=3838)"]

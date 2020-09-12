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
RUN R -e "install.packages('ada')"
RUN R -e "install.packages('adabag')"
RUN R -e "install.packages('bartMachines')"
RUN R -e "install.packages('brnn')"
RUN R -e "install.packages('bst')"
RUN R -e "install.packages('C50')"
RUN R -e "install.packages('care')"
RUN R -e "install.packages('class')"
RUN R -e "install.packages('cmaes')"
RUN R -e "install.packages('CoxBoost')"
RUN R -e "install.packages('crs')"
RUN R -e "install.packages('Cubist')"
RUN R -e "install.packages('deepnet')"
RUN R -e "install.packages('DiscriMiner')"
RUN R -e "install.packages('earth')"
RUN R -e "install.packages('fda.usc')"
RUN R -e "install.packages('FDboost')"
RUN R -e "install.packages('FNN')"
RUN R -e "install.packages('frbs')"
RUN R -e "install.packages('FSelector')"
RUN R -e "install.packages('gbm')"
RUN R -e "install.packages('glmnet')"
RUN R -e "install.packages('GPfit')"
RUN R -e "install.packages('irace')"
RUN R -e "install.packages('kernlab')"
RUN R -e "install.packages('kknn')"
RUN R -e "install.packages('klar')"
RUN R -e "install.packages('laGP')"
RUN R -e "install.packages('LiblineaR')"
RUN R -e "install.packages('MASS')"
RUN R -e "install.packages('mboost')"
RUN R -e "install.packages('mda')"
RUN R -e "install.packages('nnet')"
RUN R -e "install.packages('neuralnet')"
RUN R -e "install.packages('randomForest')"
RUN R -e "install.packages('ranger')"
RUN R -e "install.packages('rpart')"
RUN R -e "install.packages('RRF')"
RUN R -e "install.packages('rrlda')"
RUN R -e "install.packages('rsm')"
RUN R -e "install.packages('RWeka')"
RUN R -e "install.packages('sda')"
RUN R -e "install.packages('sf')"
RUN R -e "install.packages('sparseLDA')"
RUN R -e "install.packages('xgboost')"



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

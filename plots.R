
d <- read.csv('logResultRanks.csv')
d$taskType <- unlist(lapply(strsplit(d$task, split=' '), function(x)x[2]))
d$taskType <- factor(d$taskType, levels=c('Textual','Visual'), labels=c("Textual tasks", "Visual tasks"))
d$system <- 'SOMHunter'
d[2520:4721,'system'] <- 'vitrivr' #correct this if data changes :D
d$system <- factor(d$system)

library(ggplot2)

library("scales")
reverselog_trans <- function(base = exp(10)) {
    trans <- function(x) -log(x, base)
    inv <- function(x) base^(-x)
    trans_new(paste0("reverselog-", format(base)), trans, inv, 
              log_breaks(base = base), 
              domain = c(1e-100, Inf))
}

#frame ranks
ggsave("plot-ranks.pdf", width=4.5, height=2, scale=1.5, units='in', 
  ggplot() +
  geom_violin(data=d[d$rank>=0,], trim=T, aes(x=system, y=rank, fill=system), size=0, color=rgb(0,0,0,0), bw=0.1, scale='count') +
  geom_violin(data=d[d$video_rank>=0,], trim=T, aes(x=system, y=video_rank, color=system), fill=rgb(0,0,0,0),size=1.2,bw=0.1, scale='count') +
  facet_grid(.~taskType) +
  scale_fill_manual('Best frame rank', values=c('#ffb0a0','#a0b0ff')) +
  scale_color_manual('Best video rank', values=c('#c02000','#0020c0')) +
  xlab("Retrieval system") +
  scale_y_continuous('Rank', trans=reverselog_trans(10), breaks=c(1,10,100,1000,10000,100000), labels=function(x)sitools::f2si(x)) +
  theme_minimal()
)

#time
d <- read.csv('submissions.csv')
d$taskType <- unlist(lapply(strsplit(d$task, split=' '), function(x)x[2]))
d$taskType <- factor(d$taskType, levels=c('Textual','Visual'), labels=c("Textual tasks", "Visual tasks"))
d$system <- unlist(lapply(strsplit(d$team, split=' '), function(x)x[1]))
d$system <- factor(d$system, levels=c('siret','vitrivr'), labels=c('SOMHunter','vitrivr'))
d$time <- d$submissionTime/1000


ggplot() +
  geom_violin(data=d[d$correctItem=='true',], trim=T, aes(x=system, y=time, fill=system, color=system), adjust=0.2, scale='count') +
  facet_grid(.~taskType) +
  scale_fill_manual('System', values=c('#ffb0a0','#a0b0ff'), guide=F) +
  scale_color_manual('System', values=c('#c02000','#0020c0'), guide=F) +
  xlab("Retrieval system") +
  scale_y_continuous('Correct submission time', labels=function(x)sitools::f2si(x, unit='s')) +
  theme_minimal()


d <- read.csv('logResultRanks.csv')
d$system <- 'SOMHunter'
d[2520:4721,'system'] <- 'vitrivr' #correct this if data changes :D
d$system <- factor(d$system)
d$rank <- d$rank+1
d$video_rank <- d$video_rank+1

d1 <- d[,c('system','task','team','rank')]
d1 <- d1[d1$rank>0,]# & d1$rank<10000,]
d1 <- reshape2::melt(reshape2::acast(d1, system~task~team, fun.aggregate=min))
colnames(d1) <- c('system', 'task', 'team', 'rank')
d1 <- d1[is.finite(d1$rank),]
d1$taskType <- unlist(lapply(strsplit(as.character(d1$task), split=' '), function(x)x[2]))
d1$taskType <- factor(d1$taskType, levels=c('Textual','Visual'), labels=c("Textual tasks", "Visual tasks"))

d2 <- d[,c('system','task','team','video_rank')]
d2 <- d2[d2$video_rank>0,]# & d2$rank<10000,]
d2 <- reshape2::melt(reshape2::acast(d2, system~task~team, fun.aggregate=min))
colnames(d2) <- c('system', 'task', 'team', 'rank')
d2 <- d2[is.finite(d2$rank),]
d2$taskType <- unlist(lapply(strsplit(as.character(d2$task), split=' '), function(x)x[2]))
d2$taskType <- factor(d2$taskType, levels=c('Textual','Visual'), labels=c("Textual tasks", "Visual tasks"))

library(ggplot2)

#frame ranks
ggsave("plot-ranks.pdf", width=4.5, height=2, scale=1.5, units='in', 
  ggplot() +
  geom_violin(data=d1, trim=T, aes(x=system, y=rank, fill=system), size=0, color=rgb(0,0,0,0), adjust=0.3, scale='none', scale.factor=.59) +
  geom_violin(data=d2, trim=T, aes(x=system, y=rank, color=system), fill=rgb(0,0,0,0),size=.8, adjust=0.3, scale='none', scale.factor=.59) +
  facet_grid(.~taskType) +
  scale_fill_manual('Best frame rank', values=c('#ffb0a0','#a0b0ff')) +
  scale_color_manual('Best video rank', values=c('#c02000','#0020c0')) +
  xlab("Retrieval system") +
  scale_y_log10('Rank', breaks=c(1,10,100,1000,10000), labels=function(x)sitools::f2si(x)) +
  theme_minimal()
)

xs <- seq(0,4.6, length.out=1000)
dd <- data.frame()
for(tt in 



#time
d <- read.csv('submissions.csv')
d$taskType <- unlist(lapply(strsplit(d$task, split=' '), function(x)x[2]))
d$taskType <- factor(d$taskType, levels=c('Textual','Visual'), labels=c("Textual tasks", "Visual tasks"))
d$system <- unlist(lapply(strsplit(d$team, split=' '), function(x)x[1]))
d$system <- factor(d$system, levels=c('siret','vitrivr'), labels=c('SOMHunter','vitrivr'))
d$time <- d$submissionTime/1000


ggsave("plot-times.pdf", width=2, height=2, scale=1.5, units='in', 
  ggplot() +
  geom_violin(data=d[d$correctItem=='true',], trim=T, aes(x=system, y=time, fill=system, color=system), adjust=0.3, scale='width', size=0) +
  facet_grid(.~taskType) +
  scale_fill_manual('System', values=c('#ffb0a0','#a0b0ff'), guide=F) +
  scale_color_manual('System', values=c('#ffb0a0','#a0b0ff'), guide=F) +
  xlab("Retrieval system") +
  scale_y_continuous('Correct submission time', labels=function(x)sitools::f2si(x, unit='s')) +
  theme_minimal()
)

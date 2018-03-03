

da1 <- "1	2	3	4	5	6	7	8	9	10	11	12
	0.049	3.03	1.943	2.597	2.419	1.201	0.98	2.32	3.063	2.268	2.087	2.863
	0.049	2.97	2.936	2.751	1.048	2.874	2.727	2.48	1.865	2.688	2.96	2.275
	0.049	2.383	2.441	0.05	1.735	0.516	0.049	0.049	0.049	0.053	0.05	0.049
	0.05	0.863	2.71	0.05	1.716	0.505	0.049	0.05	0.05	0.049	0.049	0.049
	0.05	1.106	1.942	1.899	1.598	1.471	1.928	1.818	1.773	2.254	1.941	2.509
	0.049	1.128	1.945	1.765	2.064	2.002	1.989	1.976	2.099	1.997	2.209	2.402
	0.055	2.239	2.157	0.05	1.387	0.566	0.053	0.049	0.049	0.052	0.049	0.05
	0.049	1.778	2.623	0.05	1.378	0.568	0.049	0.049	0.049	0.049	0.05	0.049"


da2 <- "1	2	3	4	5	6	7	8	9	10	11	12
	0.046	1.195	0.946	1.15	1.138	0.613	0.507	1.094	1.22	1.095	1.011	1.159
	0.046	1.189	1.179	1.158	0.545	1.156	1.146	1.13	0.933	1.17	1.205	1.087
	0.046	1.184	1.217	0.047	0.879	0.285	0.046	0.046	0.046	0.051	0.047	0.046
	0.047	0.462	1.244	0.047	0.868	0.28	0.046	0.047	0.046	0.047	0.046	0.046
	0.046	0.636	1.255	1.234	1.01	0.905	1.239	1.159	1.114	1.438	1.237	1.494
	0.046	0.656	1.249	1.129	1.358	1.308	1.296	1.275	1.345	1.279	1.408	1.479
	0.052	1.434	1.379	0.047	0.824	0.297	0.05	0.046	0.046	0.05	0.046	0.047
	0.046	1.107	1.47	0.047	0.814	0.299	0.046	0.046	0.046	0.046	0.048	0.046"

da3 <- "1	2	3	4	5	6	7	8	9	10	11	12
	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA
	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA
	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA
	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA	NA
	NA	mir146a_2	mir146a_3	mir146a_4	mir146a_5	mir146a_6	mir146a_7	mir146a_8	PBS_9	PBS_10	PBS_11	PBS_12
	NA	mir146a_2	mir146a_3	mir146a_4	mir146a_5	mir146a_6	mir146a_7	mir146a_8	PBS_9	PBS_10	PBS_11	PBS_12
	NA	PBS_14	PBS_15	NA	standard_std	blank_blk	NA	NA	NA	NA	NA	NA
	NA	PBS_14	PBS_15	NA	standard_std	blank_blk	NA	NA	NA	NA	NA	NA"

library
## @knitr import_summary
	library(plyr)
	library(dplyr)
	library(xtable)
	x430 <- read.table(text = da1, header = TRUE)
	x520 <- read.table(text = da2, header = TRUE)
	template <- read.table(text = da3, header = TRUE)

	source("/Users/DL/Documents/R project/myCode/myFunction/myFunction.R")

	d.430 <- getData_96well(template = template, data = x430)
	d.520 <- getData_96well(template = template, data = x520)

	d.430 <- ddply(d.430, c("V6"), transform, mean.430 = mean(x430))
	d.520 <- ddply(d.520, c("V6"), transform, mean.520 = mean(x520))


# get dataframe
	d <- cbind(d.430, mean.520 = d.520$mean.520)[-c(1,2)]
	d <- d[c(seq(1,nrow(d), by = 2)),]
  d <- tbl_df(d) 
  blank_430 <- filter(d, V5 == "blank")[,4]
  blank_520 <- filter(d, V5 == "blank")[,5]
	d$mean.430_blk <- d$mean.430 - blank_430
	d$mean.520_blk <- d$mean.520 - blank_520

  str_430_blk <- filter(d, V5 == "standard")[,6]
  str_520_blk <- filter(d, V5 == "standard")[,7]

	d$BUN.430 <- 50*50*d$mean.430_blk/str_430_blk/2.14
	d$BUN.520 <- 50*50*d$mean.520_blk/str_520_blk/2.14

	print(xtable(d[order(d$V5),], caption = "BUN concentration"), scalebox=0.8) # , floating.environment='sidewaystable' ,rotate.colnames=TRUE

## @knitr t-test
	# source("/Users/DL/Documents/R project/myCode/myFunction/myFunction.R")
	# dd430 <- getTtestTable(df = d, value = bun.430, group = V5, com1 = "PBS", com2 = "mir146a" )
	# dd520 <- getTtestTable(df = d, value = bun.520, group = V5, com1 = "PBS", com2 = "mir146a" )

	# d[order(d$well),]
  t520 <- getTtest3(df = d, value = BUN.520, group = V5, com1 = "PBS", com2 = "mir146a" )
  print(xtable(t520,caption = "T-test, 520"), floating=FALSE)
  t430 <- getTtest3(df = d, value = BUN.430, group = V5, com1 = "PBS", com2 = "mir146a" )
  print(xtable(t430,caption = "T-test, 430"), floating=FALSE)

# plot
	# par(mfrow = c(1,2))
	# par(mar= c(2,2,3,3))
	# boxplot(data = dd430, bun.430 ~ V5, col =rainbow(4))
	# title("BUN concentration (430)", outer =FALSE)
	# boxplot(data = dd520, bun.520 ~ V5, col =rainbow(4))
	# mtext("BUN concentration (520)", outer =FALSE)
	# # mtext("BUN concentration (miR-146a vs PBS)", side = 1, outer =TRUE. line =1)


## @knitr plot
  dd430 <- getTtestTable(df = d, value = BUN.430, group = V5, com1 = "PBS", com2 = "mir146a" )
	dd520 <- getTtestTable(df = d, value = BUN.520, group = V5, com1 = "PBS", com2 = "mir146a" )
  # knit_hooks$set(crop = hook_pdfcrop)
	par(mfrow = c(1,2))
	par(mar= c(2,2,3,3))
	boxplot(data = dd430, BUN.430 ~ V5, col =rainbow(4))
	mtext("BUN concentration (430)", outer =FALSE)
	boxplot(data = dd520, BUN.520 ~ V5, col =rainbow(4))
	mtext("BUN concentration (520)", outer =FALSE)
	# mtext("BUN concentration (miR-146a vs PBS)", side = 1, outer =TRUE. line =1)
	# hist(rnorm(100))


## @knitr end
# get dataframe
# d <- data.frame(rbind(a,b,pc,bl))
# d[,1:2] <- sapply(d[,1:2], as.numeric)
# d$treatment <- c(rep("miR-146a",7),rep("PBS",6),"PC","BLK")
# d$x520_conc <- 50*50*(d$x520 - d[15,2])/(d[14,2]-d[15,2])/2.14
# d$x430_conc <- 50*50*(d$x430 - d[15,1])/(d[14,1]-d[15,1])/2.14










# d <- data.frame(year = rep(2000:2002, each = 3),count = round(runif(9, 0, 20)))

# ddply(d, "year", function(x) {mean.count <- mean(x$count)
# 	sd.count <- sd(x$count)
# 	cv <- sd.count/mean.count
# 	data.frame( cv.counts = cv)
# 	})

# par(mfrow = c(1, 3), mar = c(2, 2, 1, 1), oma = c(3, 3, 0, 0))
# d_ply(d, "year", transform, plot(count, main = unique(year), type = "o"))
# mtext("count", side = 1, outer = TRUE, line = 1)
# mtext("frequency", side = 2, outer = FALSE, line = 1)
#nstall.packages("XLConnect")
library (XLConnect)

################# Master ISO3 and country names sheet
get.ISO3 <- function(){
  
  ISO3<-loadWorkbook(paste("data/", "Country List with ISO3.xlsx", sep=""))
  ISO3<-readWorksheet(ISO3, sheet="Country Code", region="B3:C450", header=T)
  ISO3[,1] <- tolower(ISO3[,1])
  
  return(ISO3)
}

################# Political stability
## Data format : WGI
get.Political.Stability <- function(){
  print("########")
  print("Running get.Political.Stability function to get the data from [R] [WGI] Political stability.xlsx")
  
  ISO3 <- get.ISO3()
  
  Political.Stability <- loadWorkbook(paste("data/", "[R] [WGI] Political stability.xlsx", sep=""))
  
  ## get the data only without the column names and the country names
  Political.Stability.Data <- readWorksheet(Political.Stability, sheet="Political StabilityNoViolence", region="C16:CH230", header=F)
  
  ## get the column names without the country names
  Political.Stability.Data.Header <- readWorksheet(Political.Stability, sheet="Political StabilityNoViolence", region="C14:CH15", header=F)
  Political.Stability.Data.Header[3,] <- paste(Political.Stability.Data.Header[1,], Political.Stability.Data.Header[2,], sep=" ")
  
  ## assign the column names into Data object
  colnames(Political.Stability.Data) <- Political.Stability.Data.Header[3,]
  
  ## get the country names
  Political.Stability.Country <- readWorksheet(Political.Stability, sheet="Political StabilityNoViolence", region="A16:A230", header=F)
  colnames(Political.Stability.Country) <- c("Country.Name")
  Political.Stability.Country[,1] <- tolower(Political.Stability.Country[,1])
  
  ## get the ISO3 for country names
  Political.Stability.Country <- merge(Political.Stability.Country, ISO3, by="Country.Name", all.x=T)
  
  ## check if there is any country without ISO3
  subset(Political.Stability.Country, is.na(Political.Stability.Country[,2]))
  
  ## merging
  Political.Stability.Complete <- cbind(Political.Stability.Country, Political.Stability.Data)
  
  ## get only the latest data
  Political.Stability.Latest <- Political.Stability.Complete[,c("Country.Name", "ISO3", "2012 Estimate")]
  
  final.countries <- unique(Political.Stability.Latest[,1])
  print(paste("Total number of unique countries after cleaning ",length(final.countries), sep=""))
  print("###### end #######")
  
  return(Political.Stability.Latest)
}


################# Technicians and associate professionals from 88
## the source data structure must be the same as [R] [ILO] [ISCO-68] Technicians and associate professionals.xls
## Data format : ILO
get.tech.asso.latest <- function(source.file, source.sheet, source.region, 
                                       source.gender, source.colnames, result.colnames, result.cut.year){
  
  print("########")
  print(paste("Running get.tech.asso.88.MF.latest function to get the data from ", source.file, sep=""))
  
  ISO3 <- get.ISO3()
  
  Technicians.Associates.WS <- loadWorkbook(paste("data/", source.file, sep=""))
  
  ## Get the data 
  ## This is in Panel data
  Technicians.Associates <- readWorksheet(Technicians.Associates.WS, sheet=source.sheet, region=source.region, header=T)
  
  ## Remove the CountryCode and get the country lowercase
  Technicians.Associates <- Technicians.Associates[,-1]
  Technicians.Associates[,1] <- tolower(Technicians.Associates[,1])
  
  original.countries <- unique(Technicians.Associates[,1])
  print(paste("Total number of rows in original datasheet : ", nrow(Technicians.Associates), sep=""))
  print(paste("Total number of unique countries before cleaning : ", length(original.countries), sep=""))
  
  ## Get the ISO3 for country names
  Technicians.Associates <- merge(ISO3, Technicians.Associates, by.x="Country.Name", by.y="Country", all.y=T)
  
  ## Since the country without ISO3 is Germany, federal republic of western and year is from 1982 to 1989, we can just remove them.
  Technicians.Associates.ISO3 <- subset(Technicians.Associates, !is.na(Technicians.Associates[,2]))
  
  ## Get the name of unique Countries
  cleaned.countries <- unique(Technicians.Associates.ISO3[,1])
  print(paste("Total number of unique countries after cleaning : ",length(cleaned.countries), sep=""))
  
  if(length(cleaned.countries) != length(original.countries)){
    print("Countries removed are :")
    print(setdiff(original.countries, cleaned.countries))
  }
  
  ## Get the gender total total
  Technicians.Associates.ISO3.MF <- Technicians.Associates.ISO3[Technicians.Associates.ISO3$Sex..code. == source.gender,]
  
  ## Sort by the name and year. Then get the maximum
  Technicians.Associates.ISO3.MF.sorted <- Technicians.Associates.ISO3.MF[order(Technicians.Associates.ISO3.MF$Country.Name, Technicians.Associates.ISO3.MF$Year, decreasing=T),]
  Technicians.Associates.ISO3.MF.latest <- Technicians.Associates.ISO3.MF.sorted[!duplicated(Technicians.Associates.ISO3.MF.sorted$Country.Name),]
  
  ## Get the columns
  Technicians.Associates.ISO3.MF.latest <- Technicians.Associates.ISO3.MF.latest[, source.colnames]
  
  ## Change the column names
  colnames(Technicians.Associates.ISO3.MF.latest) <- result.colnames
  
  ## Order by the ISO3
  Technicians.Associates.ISO3.MF.latest <- Technicians.Associates.ISO3.MF.latest[order(Technicians.Associates.ISO3.MF.latest$ISO3, decreasing=F),]
  
  ## Remove the data which is lower than 2003
  Technicians.Associates.ISO3.MF.latest.cut <- Technicians.Associates.ISO3.MF.latest[Technicians.Associates.ISO3.MF.latest$Year >= result.cut.year,]
  
  ## Get the name of unique Countries
  final.countries <- unique(Technicians.Associates.ISO3.MF.latest.cut[,1])
  print(paste("Total number of unique countries after cutting at ", result.cut.year, " : ", length(final.countries), sep=""))
  
  if(length(final.countries) != length(cleaned.countries)){
    print("Countries removed are :")
    print(setdiff(cleaned.countries, final.countries))
  }
  
  print("###### end #######")
  
  ## return the final result
  return(Technicians.Associates.ISO3.MF.latest.cut)
}

################# Gross expenditure on R&D
## Data format : UNESCO
get.UNESCO.format <- function(source.file, source.sheet, source.data.region,
                                source.colnames, result.colnames, result.cut.year){
  print("########")
  print(paste("Running get.UNESCO.format function to get the data from ", source.file, sep=""))
  
  ISO3 <- get.ISO3()
  
  data.ws <- loadWorkbook(paste("data/", source.file, sep=""))
  
  ## get the column names without the country names
  data.Header <- readWorksheet(data.ws, sheet=source.sheet, region=source.colnames, header=F)
  
  data.Header[1, 1] <- "Country.Name"
  
  ## get the data only without the column names and the country names
  UNESCO.data <- readWorksheet(data.ws, sheet=source.sheet, region=source.data.region, header=F, 
                                        colTypes = rep(c(XLC$DATA_TYPE.STRING, XLC$DATA_TYPE.NUMERIC), times=c(1,ncol(data.Header)-1)), 
                                        forceConversion=T)
  
  ## Change the names into lower case for merging
  UNESCO.data[, 1] <- tolower(UNESCO.data[, 1])
  
  original.countries <- unique(UNESCO.data[,1])
  print(paste("Total number of rows in original datasheet : ", nrow(UNESCO.data), sep=""))
  print(paste("Total number of unique countries before cleaning : ", length(original.countries), sep=""))
  
  ## assign the column names into Data object
  colnames(UNESCO.data) <- data.Header
  
  ## reshaping to long data
  UNESCO.long.data <- reshape(UNESCO.data, idvar="Country.Name", varying=list(2:ncol(data.Header)), v.names=result.colnames, direction="long", times=c(min(as.numeric(data.Header[,-1])):max(as.numeric(data.Header[,-1]))))
  
  UNESCO.long.c.data <- UNESCO.long.data[complete.cases(UNESCO.long.data),]
  
  ## Sort by the name and year. Then get the maximum
  UNESCO.long.c.data <- UNESCO.long.c.data[order(UNESCO.long.c.data$Country.Name, UNESCO.long.c.data$time, decreasing=T), ]
  UNESCO.long.c.data <- UNESCO.long.c.data[!duplicated(UNESCO.long.c.data$Country.Name), ]
  
  ## rename the colnames
  colnames(UNESCO.long.c.data) <- c("Country.Name", "Year", result.colnames)
  
  ## Order the data by Name, then time
  UNESCO.long.c.data <- UNESCO.long.c.data[order(UNESCO.long.c.data$Country.Name, UNESCO.long.c.data$Year, decreasing=F),]
  
  ## Remove the data which is lower than 2003
  UNESCO.long.c.data <- UNESCO.long.c.data[UNESCO.long.c.data$Year >= result.cut.year, ]  
  
  ## Get the ISO3 for country names
  UNESCO.long.c.data <- merge(UNESCO.long.c.data, ISO3, by="Country.Name", all.x=T)
  
  final.countries <- unique(UNESCO.long.c.data[,1])
  print(paste("Total number of unique countries after cutting and cleaning at ", result.cut.year, " : ",length(final.countries), sep=""))
  
  if(length(final.countries) != length(original.countries)){
    print("Countries removed are :")
    print(setdiff(original.countries, final.countries))
  }
  
  print("###### end #######")
  
  return(UNESCO.long.c.data)
}

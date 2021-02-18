library(corrplot)
load("final_project_data.RData")
str = function(x){
  a1 = regexpr("_",x)[1]+1
  a2 = substr(x ,start = a1,stop = nchar(x))
  return(a2)
}

data_category = data.frame(data$Gender,data$Race,data$DRG.Class,data$DRG.Complication)
data$Gender = NULL
data$Race = NULL
data$DRG.Class = NULL
data$DRG.Complication = NULL

for(i in 1:ncol(data_category)){
  data_category[,i]=as.factor(data_category[,i])
}

encode = one_hot(as.data.table(data_category))
col = colnames(encode)
newcol =c()
for(i in col){
  newcol = c(newcol,str(i))
}
colnames(encode) = newcol
data = cbind(data,encode)



cor = round(cor(data),2)

corrplot(cor)




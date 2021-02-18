library("randomForest")
library("ROCR")
library("ggplot2")
library("plotROC")
#user control : kfold ====

kfold = 5

#data====

load("final_project_data.RData")

data$Readmission.Status = as.factor(data$Readmission.Status)


#fold======
index=sample(cut(x=1:nrow(data),breaks=kfold,labels=FALSE))
FOLD=list()

index=sample(cut(x=1:nrow(data),breaks=kfold,labels=FALSE))
FOLD=list()
for(i in 1:kfold){
  
  foldlsit=list()
  
  if(i < kfold){
    foldlsit[[1]]=subset(data,index==i)  #test
    foldlsit[[2]]=subset(data,index==i+1)#validation
    foldlsit[[3]]=subset(data,index!=i&index!=i+1)#train
  }
  else{
    foldlsit[[1]]=subset(data,index==i)  #test
    foldlsit[[2]]=subset(data,index==1)#validation
    foldlsit[[3]]=subset(data,index!=i&index!=1)#train
  }
  names(foldlsit)=c("test","validation","train")
  FOLD[[i]]=foldlsit
}
names(FOLD)=paste("fold",1:kfold)






#k-fold CV====


#執行
performance=matrix(NA,kfold+1,4)
colnames(performance)=c("set","train","validation","test")
performance[,1]=c(names(FOLD),"ave.")

plotdata = matrix(NA,nrow(data),3)
colnames(plotdata) = c("true","score","fold")

true = c()
for(i in 1:kfold){
  true = c(true,FOLD[[i]][["test"]]$Readmission.Status)
}
name = c()
for(i in 1:kfold){
  name = c(name,rep(paste("fold",i),nrow(FOLD[[i]][["test"]])))
}
plotdata[,1] = true
plotdata[,3] = name


score = c() 

for(f in 1:kfold){
  
  # data
  Test = FOLD[[f]][[1]]
  validation = FOLD[[f]][[2]]
  Train = FOLD[[f]][[3]]
  mix = rbind(validation,Train) ; mix = as.data.frame(mix)
  
  # model
  
  bestmodel = randomForest(Readmission.Status~.,data = mix,ntree=50)
  
  
  #3.performance
  
  prob_Train = predict(bestmodel,Train,type="prob")[,2]
  list_Train = list(predictions = prob_Train, labels = Train$Readmission.Status)
  pred_Train = prediction(list_Train$predictions, list_Train$labels)
  auc1 = performance(pred_Train,'auc')
  p1 = auc1@y.values[[1]];p1=round(p1,2)
  
  prob_validation = predict(bestmodel,validation,type="prob")[,2]
  list_validation = list(predictions = prob_validation, labels = validation$Readmission.Status)
  pred_validation = prediction(list_validation$predictions, list_validation$labels)
  auc2 = performance(pred_validation,'auc')
  p2 = auc2@y.values[[1]];p2=round(p2,2)
  
  prob_Test = predict(bestmodel,Test,type="prob")[,2]
  list_Test = list(predictions = prob_Test, labels = Test$Readmission.Status)
  pred_Test = prediction(list_Test$predictions, list_Test$labels)
  auc3 = performance(pred_Test,'auc')
  p3 = auc3@y.values[[1]];p3=round(p3,2)
  
  performance[f,2:4]=c(p1,p2,p3)
  FOLD[[f]][[1]]$score = prob_Test
  score = c(score,prob_Test)
}
plotdata[,2] = score  

perf=performance[1:kfold,2:4]
perf=apply(perf,2,as.numeric)
performance[kfold+1,2:4]=round(apply(perf,2,mean),2)
performance


# ROC curve ====
plotdata = as.data.frame(plotdata)
plotdata$true = as.integer(plotdata$true)
plotdata$score = as.numeric(plotdata$score)

ggplot(plotdata, aes(d = true, m = score, color = fold)) + geom_roc(n.cuts = 0) +
  geom_abline(slope = 1,intercept = 0 ,lty=2,lwd=0.8) + 
  labs(x="FPR",y="TPR",title="ROC curve") +
  theme(plot.title=element_text(hjust = 0.5)) +
  annotate("text",x=0.65,y=0.1,label=paste("average AUC =",performance[kfold+1,4]))


# ROC curve ====
plotdata = as.data.frame(plotdata)
plotdata$true = as.integer(plotdata$true)
plotdata$score = as.numeric(plotdata$score)

ggplot(plotdata, aes(d = true, m = score, color = fold)) + geom_roc(n.cuts = 0) +
  geom_abline(slope = 1,intercept = 0 ,lty=2,lwd=0.8) + 
  labs(x="FPR",y="TPR",title="ROC curve") +
  theme(plot.title=element_text(hjust = 0.5)) +
  annotate("text",x=0.65,y=0.1,label=paste("average AUC =",performance[kfold+1,4]))









#匯出====
write.csv(performance,file="result_rf.csv",quote=F,row.names=F)


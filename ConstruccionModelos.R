
#install.packages("faraway")
library(faraway)

cheddar
head(cheddar)
summary(cheddar)
plot(cheddar)
model1.lm<-lm(taste~Acetic+H2S+Lactic, data=cheddar)
plot(model1.lm)

typeof(cheddar$taste)
typeof(cheddar$Acetic)
typeof(cheddar$H2S)
typeof(cheddar$Lactic)
#Todas numericas se procede como siempre



#### Regresión de método backwards ####
#metodo backwards alpha es 0.2, en realidad sirve un alpha como poco 0.02
model.all<-lm(taste~.,data=cheddar)
drop1(model.all,test="F")
#actualizamos el modelo sin Ac porque es la de mayor pvalue
model.update1<-update(model.all, .~. -Acetic)
drop1(model.update1,test="F")

#ahora si' es el modelo final, en realidad vale con alpha 0,05 tambien hasta 0,02
model.final<-lm(taste~H2S+Lactic, data=cheddar)
summary(model.final)


#### Regresión de metodo fordward ####

#metodo fordward alpha es 0,2, en realidad sirve un alpha como poco 0.02
SCOPE<-(~.+Acetic + H2S + Lactic)
model.inicial <- lm(taste~1,data=cheddar)
add1(model.inicial,scope=SCOPE,test="F")
#actualizamos aÃ±adiendo el de menor pvalue
model.updatei1<-update(model.inicial, .~. +H2S)
add1(model.updatei1,scope=SCOPE,test="F")

model.updatei2<-update(model.updatei1, .~. +Lactic)
add1(model.updatei2,scope=SCOPE,test="F")

#ahora si' es el modelo final, igual vale con alpha de minimo 0.02
model.final2<-lm(taste~H2S+Lactic, data=cheddar)
summary(model.final)#es igual al model.final1


#### ahora cosas de criterios ####
#install.packages("leaps")
library(leaps)

models<-regsubsets(taste~., data=cheddar)
summary(models)
MR2adj<-summary(models)$adjr2
MR2adj
which.max(MR2adj)
summary(models)$which[2, ]
model.final3<-lm(taste~H2S+Lactic, data=cheddar)
plot(models,scale="adjr2")#se busca el máximo y se ve como crece

MCp <-summary(models)$cp
which.min(MCp)
summary(models)$which[2, ]
model.final4<-lm(taste~H2S+Lactic, data=cheddar)
plot(models,scale="Cp")##se busca el minimo y se ve como decrece

MBIC <-summary(models)$bic
which.min(MBIC)
summary(models)$which[2, ]
model.final5<-lm(taste~H2S+Lactic, data=cheddar)
plot(models,scale="bic")


#install.packages("MASS")
library(MASS)
model.all <- lm(taste~., data=cheddar)
SCOPE <-(~.)
stepAIC(model.all, scope=SCOPE, k=2)
stepAIC(model.all, scope=SCOPE, k=log(30))# es el BIC a traves de esta funcion


#######  Hasta aqui estaba antes  ######


########Ahora he hecho cosas de outliers/leverages
install.packages("PASWR")
library(PASWR)
#lo de matrizhat2 es calculada explicitamente 
modelf.lm <- lm(taste~H2S + Lactic, data=cheddar)
hat(model.matrix(modelf.lm))[1:5]
matrizhat <- hat(model.matrix(modelf.lm))
X<-cbind(rep(1,length(x2)),x2,x3)
matrizhat2<-X%*%solve(t(X)%*%X)%*%t(X)
matrizhat
matrizhat2
hii <- diag(matrizhat)
hii2<- diag(matrizhat2)
sum(hii)
sum(hii2)
plot(modelf.lm)
hii
hii2

#ver normalidad 
install.packages("car")
library(car)

durbinWatsonTest(modelf.lm)
shapiro.test(resid(modelf.lm))


###residuos estandarizados y bonferroni

alph<- 0.20
BCV <- qt(1-alph/(2*30),26) #el valor crítico de Bonferroni t_{1-alpha/2n;n-p-1}, n=30,p=3 
BCV
sum(abs(rstudent(modelf.lm))>BCV)
which.max(abs(rstudent(modelf.lm)))

install.packages("ggplot2")
library(ggplot2)

fmodel <-fortify(modelf.lm)
head(fmodel)

X <- fmodel$.fitted
Y <- fmodel$.stdresid
plot(X,Y, ylab="Residuos estandarizados", xlab="valores ajustados") 
segments(5,0,40,0)
sort(abs(rstandard(modelf.lm)),decreasing = TRUE)[1:3]

###outliers y high leverage

outlierTest(modelf.lm)# no hay 

influenceIndexPlot(modelf.lm)
#Criterio 1: valores leverage (hii) son mayores que 2p/n

#hii <- hatvalues(modelf.lm)
hCV <- 2*3/30 
sum(hii2>hCV)
which(hii2>hCV)#6

#Criterio 2: valores |DFFITS| son mayores que 2sqrt(p/n)
dffitsCV <- 2*sqrt(3/30)
dffitsmodel <- dffits(modelf.lm)
sum(dffitsmodel>dffitsCV)

which(dffitsmodel>dffitsCV)

#Criterio 3: valores |DFBETAS| mayores que 2/sqrt(n)
dfbetaCV <- 2/sqrt(30)
dfbetamodel <- dfbeta(modelf.lm)
dfbetamodel
sum(dfbetamodel[,1]>dfbetaCV)
sum(dfbetamodel[,2]>dfbetaCV)
sum(dfbetamodel[,3]>dfbetaCV)

which(dfbetamodel[,1]>dfbetaCV)
which(dfbetamodel[,3]>dfbetaCV)  

#Grafica con su distancia de cook
install.packages("car")
library(car)
influencePlot(modelf.lm)
pos_influyentes <- c(6,7,8,12,15)



# las eliminamos y vemos que tal la cosa
obs.out <- c(6,7,8,12,15)
chesse<-cheddar[-obs.out,1:4]
set.seed(1)#semilla
#tomo un 90 - 10
train <-sample(c(TRUE,FALSE),size=nrow(chesse),replace=TRUE, prob=c(0.90,0.10))
#conjunto de entrenamiento
test<- (!train)
test
model.exh <-regsubsets(taste ~., data=cheddar[train,1:4], method ="exhaustive")
summary(model.exh)

# la funcion esa que ella siempre copia y pega
predict.regsubsets <- function(object, newdata, id,...){
  form <- as.formula(object$call[[2]])
  mat <- model.matrix(form, newdata)
  coefi <-coef(object, id=id)
  xvar <-names(coefi)
  mat[,xvar]%*%coefi
}
#analisis del error con los train
val.errors <-rep(NA,3)
Y <- cheddar[test,]$taste
for (i in 1:3){
  Yhat <-predict.regsubsets(model.exh, newdata=cheddar[test,],id=i)
  val.errors[i]<- mean((Y-Yhat)^2)
}

val.errors
coef(model.exh,which.min(val.errors))

regfit.best <-regsubsets(taste~., cheddar[-obs.out,1:4])
coef(regfit.best,which.min(val.errors))



#### validacion cruzada de 1

n <- nrow(chesse)
k <- n #número de grupos, como es de elemento a elemento hay n
set.seed(1)
folds <- sample (x=1:k, size=nrow(chesse), replace=FALSE)
cv.errors <- matrix(NA, k,3, dimnames = list(NULL,paste(1:3)))
for (j in 1:k){
  best.fit <-regsubsets(taste~., data=chesse[folds!=j,])#cojemos datos del train
  for (i in 1:3){
    pred <-predict.regsubsets(best.fit, newdata=chesse[folds==j,],id=i)#datos test
    cv.errors[j,i] <- mean((chesse$taste[folds==j]-pred)^2)
  }
}
mean.cv.errors <- apply(cv.errors, 2, mean)
mean.cv.errors
coef(best.fit,which.min(mean.cv.errors))

##### validacion en 4 grupos, cambiar la linea de k para otro numero

n <- nrow(chesse)
k <- 4 #número de grupos 
set.seed(1)

folds <- sample (x=1:k, size=nrow(chesse), replace=TRUE)
cv.errors <- matrix(NA, k,3, dimnames = list(NULL,paste(1:3)))
for (j in 1:k){
  best.fit <-regsubsets(taste~., data=chesse[folds!=j,])#cojemos datos del train
  for (i in 1:3){
    pred <-predict.regsubsets(best.fit, newdata=chesse[folds==j,],id=i)#datos test
    cv.errors[j,i] <- mean((chesse$taste[folds==j]-pred)^2)
  }
}
mean.cv.errors <- apply(cv.errors, 2, mean)
mean.cv.errors
coef(best.fit,which.min(mean.cv.errors))

######comprobación
model.cv <- lm(taste~H2S+Lactic, data=chesse)
summary(model.cv)
plot(lm(taste~H2S+Lactic, data=chesse), which=1)
plot(lm(taste~H2S+Lactic, data=chesse), which=2)
residualPlot(model.cv)
influenceIndexPlot(model.cv)


#### con ese modelo final t~h+l ver lios  
#suponiendo los errores se distribuyen con media 0 y varianza v^2 

#calculo de intervalo de conf de beta1(H2S) y 2(Lactic)
#[seria beta 2 y 3 si lo interpreto del modelo original]
#metodo Bonferroni
model.y<-lm(taste~H2S+Lactic, data=cheddar)
alpha <- 0.10
summary(model.y)$coef
b <- summary(model.y)$coef[2:3,1]
s.b <- summary(model.y)$coef[2:3,2]
g <- 2
n <-nrow(cheddar)
p <-ncol(summary(model.y)$coef)
t_teo <- qt(1-alpha/(2*g),n-p)
BomSimCI <- matrix (c(b-t_teo*s.b,b+t_teo*s.b),ncol=2)
conf <-c("5%", "95%")
bnam <-c("H2S", "Lactic")
dimnames(BomSimCI)<-list(bnam,conf)
BomSimCI
#Intervalo de confianza simultáneo por el método de Scheffé
Q <-p-1
f_teo <- qf(0.9,Q,n-p)
SchSimCI <- matrix (c(b-sqrt(Q*f_teo)*s.b,b+sqrt(Q*f_teo)*s.b),ncol=2)
conf <-c("5%", "95%")
bnam <-c("H2S", "Lactic")
dimnames(SchSimCI)<-list(bnam,conf)
SchSimCI

#Ahora la cosa esa de la elipse  para beta1 y 2


confidenceEllipse(model.y, level=0.90, which.coef = c(2,3),
                  Scheffe = FALSE, main="")
title(main="Elipsoide de confianza Bonferroni")
abline(v=BomSimCI[1,])
abline(h=BomSimCI[2,])

confidenceEllipse(model.y, level=0.90, which.coef = c(2,3),
                  Scheffe = TRUE, main="")
title(main="Elipsoide de confianza Scheffé")
abline(v=SchSimCI[1,])
abline(h=SchSimCI[2,])


######### cosas haciendo boxcox y depsues de hacerlo ...######

#training con boxcox y despues lo comparo
install.packages("car")
library(car)
bc <- boxCox(modelf.lm, lambda = seq(-2, 2, 1 / 10), plotit = TRUE)
lambda <- bc$x[which.max(bc$y)]
Y_bc <- (cheddar$taste^lambda - 1) / lambda
modelf2.lm<- lm(Y_bc~ H2S+Lactic,data=cheddar)

influencePlot(modelf2.lm)
influencePlot(modelf.lm)
#antes era pos_influyentes <- c(6,7,8,12,15)
pos_influyentes <- c(1,6,7,15,28)

cheddar2<-cheddar
cheddar2$taste<- (cheddar$taste^lambda - 1) / lambda
cheddar
cheddar2
# las eliminamos y vemos que tal la cosa
obs.out <- c(1,6,7,15,28)
chesse2<-cheddar2[-obs.out,1:4]
set.seed(1)
train <-sample(c(TRUE,FALSE),size=nrow(chesse2),replace=TRUE, prob=c(0.90,0.10))
#conjunto de entrenamiento
test<- (!train)
test
model.exh2 <-regsubsets(taste ~., data=cheddar2[train,1:4], method ="exhaustive")
summary(model.exh)

# la funcion esa que ella siempre copia y pega
predict.regsubsets <- function(object, newdata, id,...){
  form <- as.formula(object$call[[2]])
  mat <- model.matrix(form, newdata)
  coefi <-coef(object, id=id)
  xvar <-names(coefi)
  mat[,xvar]%*%coefi
}

val.errors2 <-rep(NA,3)
Y <- cheddar2[test,]$taste
for (i in 1:3){
  Yhat <-predict.regsubsets(model.exh2, newdata=cheddar2[test,],id=i)
  val.errors2[i]<- mean((Y-Yhat)^2)
}

val.errors2
coef(model.exh2,which.min(val.errors2))

regfit.best <-regsubsets(taste~., cheddar2[-obs.out,1:4])
coef(regfit.best,which.min(val.errors2))

#esto era antes de boxcox
val.errors
coef(model.exh,which.min(val.errors))

regfit.best <-regsubsets(taste~., cheddar[-obs.out,1:4])
coef(regfit.best,which.min(val.errors))

#para verlo más visual

val.errors
val.errors2

coef(model.exh2,which.min(val.errors2))
coef(model.exh,which.min(val.errors))

coef(regfit.best,which.min(val.errors2))
coef(regfit.best,which.min(val.errors))
#Observese todos los metodos por criterios y por pasos nos llevan al mismo modelo

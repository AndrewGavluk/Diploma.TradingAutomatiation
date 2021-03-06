//+------------------------------------------------------------------+
//|                                                 FormatString.mqh |
//|                                   Copyright 2018, Andrey Gavluck |
//|                                            gavl.andr96@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Andrey Gavluck"
#property link      "gavl.andr96@gmail.com"

string ValueFormat(double y,void *cbdata)
  {
   return(NumToString(y,0," "));
  }
//+------------------------------------------------------------------+
//| Разделитель групп разрядов                                       |
//+------------------------------------------------------------------+
string NumToString(ulong Num,const string Delimeter=" ")
  {
   string Res=ModToString(Num);
   while(Num)
      Res=ModToString(Num)+Delimeter+Res;
//---
   return(Res);
  }
//+------------------------------------------------------------------+
//| Разделитель групп разрядов                                       |
//+------------------------------------------------------------------+
string NumToString(double Num,const int digits=8,const string Delimeter=NULL)
  {
   const string PostFix=(Num<0) ? "-" : NULL;
   Num=MathAbs(Num);
   return(PostFix + NumToString((ulong)Num, Delimeter) + StringSubstr(DoubleToString(Num - (long)Num, digits), 1));
  }
//+------------------------------------------------------------------+
//| Модуль в строку                                                  |
//+------------------------------------------------------------------+
string ModToString(ulong &Num,const int Mod=1000,const int Len=3)
  {
   const string Res=((bool)(Num/Mod) ? IntegerToString(Num%Mod,Len,'0') :(string)(Num%Mod));
   Num/=Mod;
   return(Res);
  }
//+------------------------------------------------------------------+

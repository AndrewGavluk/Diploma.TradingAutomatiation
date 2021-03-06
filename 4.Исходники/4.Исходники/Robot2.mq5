//+------------------------------------------------------------------+
//|                                                       Robot2.mq5 |
//|                                   Copyright 2018, Andrey Gavluck |
//|                                            gavl.andr96@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Andrey Gavluck"
#property link      "gavl.andr96@gmail.com"
#property version   "1.00"
#include "Program.mqh"
CProgram program;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- Инициализация программы
   if(!program.OnInitEvent())
     {
      ::Print(__FUNCTION__," > Failed to initialize!");
      return(INIT_FAILED);
     }  
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   program.OnDeinitEvent(reason);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   program.OnTickEvent();
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer(void)
  {
   program.OnTimerEvent();
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   program.ChartEvent(id,lparam,dparam,sparam);
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester(void)
  {
   return(program.OnTesterEvent());
  }
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit(void)
  {
   program.OnTesterInitEvent();
  }
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass(void)
  {
   program.OnTesterPassEvent();
  }
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit(void)
  {
   program.OnTesterDeinitEvent();
  }
//+------------------------------------------------------------------+

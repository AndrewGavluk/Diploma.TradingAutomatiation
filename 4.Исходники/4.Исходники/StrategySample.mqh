//+------------------------------------------------------------------+
//|                                                     Strategy.mqh |
//|                                   Copyright 2018, Andrey Gavluck |
//|                                            gavl.andr96@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Andrey Gavluck"
#property link      "gavl.andr96@gmail.com"

#define MACD_MAGIC 1234502
//---
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
//---
input double InpLots          =0.1; // Lots
input int    InpTakeProfit    =50;  // Take Profit (in pips)
input int    InpTrailingStop  =30;  // Trailing Stop Level (in pips)
input int    InpMACDOpenLevel =3;   // MACD open level (in pips)
input int    InpMACDCloseLevel=2;   // MACD close level (in pips)
input int    InpMATrendPeriod =26;  // MA trend period
//---
int ExtTimeOut=10; // time out in seconds between trade operations
//+------------------------------------------------------------------+
//| MACD Sample expert class                                         |
//+------------------------------------------------------------------+
class CStrategy
  {
protected:
   double            m_adjusted_point;             // Множитель
   CTrade            m_trade;                      // Торговый объект
   CSymbolInfo       m_symbol;                     // Торговый символ
   CPositionInfo     m_position;                   // Инфо позиции
   CAccountInfo      m_account;                    // Инфо аккаунта
   //--- индикаторы
   int               m_handle_macd;                // MACD индикатор
   int               m_handle_ema;                 // EMA индикатор
   //--- буферы (история) индикаторов
   double            m_buff_MACD_main[];           // история индикатора MACD main
   double            m_buff_MACD_signal[];         // история индикатора MACD signal
   double            m_buff_EMA[];                 // история индикатора EMA
   //--- Обработка индикаторов
   double            m_macd_current;
   double            m_macd_previous;
   double            m_signal_current;
   double            m_signal_previous;
   double            m_ema_current;
   double            m_ema_previous;
   
   double            m_macd_open_level;
   double            m_macd_close_level;
   double            m_traling_stop;
   double            m_take_profit;

public:
                     CStrategy(void);
                    ~CStrategy(void);

   bool              OnInitEvent();
   void              OnTickEvent(void);

   bool              Init(void);
   void              Deinit(void);
   bool              Processing(void);

protected:
   bool              InitCheckParameters(const int digits_adjust);
   bool              InitIndicators(void);
   bool              LongClosed(void);
   bool              ShortClosed(void);
   bool              LongModified(void);
   bool              ShortModified(void);
   bool              LongOpened(void);
   bool              ShortOpened(void);
  };
//--- global expert
CStrategy ExtExpert;
//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
CStrategy::CStrategy(void) : m_adjusted_point(0),
                                     m_handle_macd(INVALID_HANDLE),
                                     m_handle_ema(INVALID_HANDLE),
                                     m_macd_current(0),
                                     m_macd_previous(0),
                                     m_signal_current(0),
                                     m_signal_previous(0),
                                     m_ema_current(0),
                                     m_ema_previous(0),
                                     m_macd_open_level(0),
                                     m_macd_close_level(0),
                                     m_traling_stop(0),
                                     m_take_profit(0)
  {
   ArraySetAsSeries(m_buff_MACD_main,true);
   ArraySetAsSeries(m_buff_MACD_signal,true);
   ArraySetAsSeries(m_buff_EMA,true);
  }
//+------------------------------------------------------------------+
//| Деструктор                                                       |
//+------------------------------------------------------------------+
CStrategy::~CStrategy(void)
  {
  }
//+------------------------------------------------------------------+
//| Инициализация входных параметров                                 |
//+------------------------------------------------------------------+
bool CStrategy::Init(void)
  {
//--- initialize common information
   m_symbol.Name(Symbol());                  // Торговый символ (инструмент)
   m_trade.SetExpertMagicNumber(MACD_MAGIC); // magic
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(Symbol());

   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;
//--- Установка значений по умолчанию
   m_macd_open_level =InpMACDOpenLevel*m_adjusted_point;
   m_macd_close_level=InpMACDCloseLevel*m_adjusted_point;
   m_traling_stop    =InpTrailingStop*m_adjusted_point;
   m_take_profit     =InpTakeProfit*m_adjusted_point;
   m_trade.SetDeviationInPoints(3*digits_adjust);

   if(!InitCheckParameters(digits_adjust))
      return(false);
   if(!InitIndicators())
      return(false);

   return(true);
  }
//+------------------------------------------------------------------+
//| Проверка входных параметров                                      |
//+------------------------------------------------------------------+
bool CStrategy::InitCheckParameters(const int digits_adjust)
  {
//--- Проверка начальных данных
   if(InpTakeProfit*digits_adjust<m_symbol.StopsLevel())
     {
      printf("Take Profit must be greater than %d",m_symbol.StopsLevel());
      return(false);
     }
   if(InpTrailingStop*digits_adjust<m_symbol.StopsLevel())
     {
      printf("Trailing Stop must be greater than %d",m_symbol.StopsLevel());
      return(false);
     }
//--- Проверка установки правильных значений
   if(InpLots<m_symbol.LotsMin() || InpLots>m_symbol.LotsMax())
     {
      printf("Lots amount must be in the range from %f to %f",m_symbol.LotsMin(),m_symbol.LotsMax());
      return(false);
     }
   if(MathAbs(InpLots/m_symbol.LotsStep()-MathRound(InpLots/m_symbol.LotsStep()))>1.0E-10)
     {
      printf("Lots amount is not corresponding with lot step %f",m_symbol.LotsStep());
      return(false);
     }

   if(InpTakeProfit<=InpTrailingStop)
      printf("Warning: Trailing Stop must be less than Take Profit");

   return(true);
  }
//+------------------------------------------------------------------+
//| Инициализация индикаторов                                        |
//+------------------------------------------------------------------+
bool CStrategy::InitIndicators(void)
  {
//--- Создание MACD индикатора
   if(m_handle_macd==INVALID_HANDLE)
      if((m_handle_macd=iMACD(NULL,0,12,26,9,PRICE_CLOSE))==INVALID_HANDLE)
        {
         printf("Error creating MACD indicator");
         return(false);
        }
//--- Создание EMA индикатора
   if(m_handle_ema==INVALID_HANDLE)
      if((m_handle_ema=iMA(NULL,0,InpMATrendPeriod,0,MODE_EMA,PRICE_CLOSE))==INVALID_HANDLE)
        {
         printf("Error creating EMA indicator");
         return(false);
        }
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Обработка закрытия длинной позиции                               |
//+------------------------------------------------------------------+
bool CStrategy::LongClosed(void)
  {
   bool res=false;
//--- Проверка необходимости закрытия
   if(m_macd_current>0)
      if(m_macd_current<m_signal_current && m_macd_previous>m_signal_previous)
         if(m_macd_current>m_macd_close_level)
           {
            //--- закрытие позиции
            if(m_trade.PositionClose(Symbol()))
               printf("Long position by %s to be closed",Symbol());
            else
               printf("Error closing position by %s : '%s'",Symbol(),m_trade.ResultComment());
            //--- обработка
            res=true;
           }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Обработка закрытия короткой позиции                              |
//+------------------------------------------------------------------+
bool CStrategy::ShortClosed(void)
  {
   bool res=false;
//--- should it be closed?
   if(m_macd_current<0)
      if(m_macd_current>m_signal_current && m_macd_previous<m_signal_previous)
         if(MathAbs(m_macd_current)>m_macd_close_level)
           {
            //--- закрытие позиции
            if(m_trade.PositionClose(Symbol()))
               printf("Short position by %s to be closed",Symbol());
            else
               printf("Error closing position by %s : '%s'",Symbol(),m_trade.ResultComment());
            //--- обработка
            res=true;
           }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Обработка модификации длинной позиции                                |
//+------------------------------------------------------------------+
bool CStrategy::LongModified(void)
  {
   bool res=false;
//--- check for trailing stop
   if(InpTrailingStop>0)
     {
      if(m_symbol.Bid()-m_position.PriceOpen()>m_adjusted_point*InpTrailingStop)
        {
         double sl=NormalizeDouble(m_symbol.Bid()-m_traling_stop,m_symbol.Digits());
         double tp=m_position.TakeProfit();
         if(m_position.StopLoss()<sl || m_position.StopLoss()==0.0)
           {
            //--- модификация позиции
            if(m_trade.PositionModify(Symbol(),sl,tp))
               printf("Long position by %s to be modified",Symbol());
            else
              {
               printf("Error modifying position by %s : '%s'",Symbol(),m_trade.ResultComment());
               printf("Modify parameters : SL=%f,TP=%f",sl,tp);
              }
            //--- модификация и выход
            res=true;
           }
        }
     }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Обработка модификации короткой позиции                           |
//+------------------------------------------------------------------+
bool CStrategy::ShortModified(void)
  {
   bool   res=false;
//--- check for trailing stop
   if(InpTrailingStop>0)
     {
      if((m_position.PriceOpen()-m_symbol.Ask())>(m_adjusted_point*InpTrailingStop))
        {
         double sl=NormalizeDouble(m_symbol.Ask()+m_traling_stop,m_symbol.Digits());
         double tp=m_position.TakeProfit();
         if(m_position.StopLoss()>sl || m_position.StopLoss()==0.0)
           {
            //--- модификация позиции
            if(m_trade.PositionModify(Symbol(),sl,tp))
               printf("Short position by %s to be modified",Symbol());
            else
              {
               printf("Error modifying position by %s : '%s'",Symbol(),m_trade.ResultComment());
               printf("Modify parameters : SL=%f,TP=%f",sl,tp);
              }
            //--- модификация и выход
            res=true;
           }
        }
     }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Обработка открытия длинной позиции                               |
//+------------------------------------------------------------------+
bool CStrategy::LongOpened(void)
  {
   bool res=false;
//--- check for long position (BUY) possibility
   if(m_macd_current<0)
      if(m_macd_current>m_signal_current && m_macd_previous<m_signal_previous)
         if(MathAbs(m_macd_current)>(m_macd_open_level) && m_ema_current>m_ema_previous)
           {
            double price=m_symbol.Ask();
            double tp   =m_symbol.Bid()+m_take_profit;
            //--- Проверка назичия свободной маржи
            if(m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_BUY,InpLots,price)<0.0)
               printf("We have no money. Free Margin = %f",m_account.FreeMargin());
            else
              {
               //--- открытие позиции
               if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,InpLots,price,0.0,tp))
                  printf("Position by %s to be opened",Symbol());
               else
                 {
                  printf("Error opening BUY position by %s : '%s'",Symbol(),m_trade.ResultComment());
                  printf("Open parameters : price=%f,TP=%f",price,tp);
                 }
              }
            //--- in any case we must exit from expert
            res=true;
           }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Обработка открытия короткой позиции                              |
//+------------------------------------------------------------------+
bool CStrategy::ShortOpened(void)
  {
   bool res=false;
//--- check for short position (SELL) possibility
   if(m_macd_current>0)
      if(m_macd_current<m_signal_current && m_macd_previous>m_signal_previous)
         if(m_macd_current>(m_macd_open_level) && m_ema_current<m_ema_previous)
           {
            double price=m_symbol.Bid();
            double tp   =m_symbol.Ask()-m_take_profit;
            //--- Проверка назичия свободной маржи
            if(m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_SELL,InpLots,price)<0.0)
               printf("We have no money. Free Margin = %f",m_account.FreeMargin());
            else
              {
               //--- открытие позиции
               if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,InpLots,price,0.0,tp))
                  printf("Position by %s to be opened",Symbol());
               else
                 {
                  printf("Error opening SELL position by %s : '%s'",Symbol(),m_trade.ResultComment());
                  printf("Open parameters : price=%f,TP=%f",price,tp);
                 }
              }
            //--- Выход
            res=true;
           }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| main function returns true if any position processed             |
//+------------------------------------------------------------------+
bool CStrategy::Processing(void)
  {
//--- частота обновления
   if(!m_symbol.RefreshRates())
      return(false);
//--- обновление индикаторов
   if(BarsCalculated(m_handle_macd)<2 || BarsCalculated(m_handle_ema)<2)
      return(false);
   if(CopyBuffer(m_handle_macd,0,0,2,m_buff_MACD_main)  !=2 ||
      CopyBuffer(m_handle_macd,1,0,2,m_buff_MACD_signal)!=2 ||
      CopyBuffer(m_handle_ema,0,0,2,m_buff_EMA)         !=2)
      return(false);

   m_macd_current   =m_buff_MACD_main[0];
   m_macd_previous  =m_buff_MACD_main[1];
   m_signal_current =m_buff_MACD_signal[0];
   m_signal_previous=m_buff_MACD_signal[1];
   m_ema_current    =m_buff_EMA[0];
   m_ema_previous   =m_buff_EMA[1];

//--- условие закрытия ордера
   if(m_position.Select(Symbol()))
     {
      if(m_position.PositionType()==POSITION_TYPE_BUY)
        {
         //--- Закрытие или модификация длинной позиции
         if(LongClosed())
            return(true);
         if(LongModified())
            return(true);
        }
      else
        {
         //--- Закрытие или модификация короткой позиции
         if(ShortClosed())
            return(true);
         if(ShortModified())
            return(true);
        }
     }
//--- если нет откытых позиций по текущему инструменту
   else
     {
      //--- проверить необходимость открытия позиции
      if(LongOpened())
         return(true);
      if(ShortOpened())
         return(true);
     }
//--- Выход без открытия
   return(false);
  }
//+------------------------------------------------------------------+
//| Обработка события инициализации                                  |
//+------------------------------------------------------------------+
bool CStrategy::OnInitEvent(void)
  {
//--- create all necessary objects
   if(!ExtExpert.Init())
      return(false);

   return(true);
  }
//+------------------------------------------------------------------+
//| Обработка события нового тика                                    |
//+------------------------------------------------------------------+
void CStrategy::OnTickEvent(void)
  {
   static datetime limit_time=0; 
//--- обработка с учетом таймаута
   if(TimeCurrent()>=limit_time)
      if(Bars(Symbol(),Period())>2*InpMATrendPeriod)
         if(ExtExpert.Processing())
            limit_time=TimeCurrent()+ExtTimeOut;
  }
//+------------------------------------------------------------------+

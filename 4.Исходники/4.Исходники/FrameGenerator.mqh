//+------------------------------------------------------------------+
//|                                               FrameGenerator.mqh |
//|                                   Copyright 2018, Andrey Gavluck |
//|                                            gavl.andr96@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Andrey Gavluck"
#property link      "gavl.andr96@gmail.com"

#include <Graphics\Graphic.mqh>
//--- Резервный размер для массивов
#define RESERVE_FRAMES 1000000
//--- Количество статистических показателей
#define STAT_TOTAL 7
//+------------------------------------------------------------------+
//| Класс для работы с результатами оптимизации                      |
//+------------------------------------------------------------------+
class CFrameGenerator
  {
private:
   //--- Указатели на графики для визуализации данных
   CGraphic         *m_graph_balance;
   CGraphic         *m_graph_results;
   //--- Переменные для работы с фреймами
   string            m_name;
   ulong             m_pass;
   long              m_id;
   double            m_value;
   double            m_data[];
   //--- Параметры эксперта
   string            m_param_data[];
   uint              m_par_count;
   //--- Баланс результата
   double            m_balance[];
   //--- Количество серий
   uint              m_curves_total;
   //--- Индекс текущей серии на графике
   uint              m_last_serie_index;
   //--- Счётчик фреймов
   ulong             m_frames_counter;
   //--- Всего фреймов
   ulong             m_frames_total;
   //--- Для определения максимальной серии
   double            m_curve_max[];
   //--- Данные положительных и отрицательных исходов
   double            m_loss_x[];
   double            m_loss_y[];
   double            m_profit_x[];
   double            m_profit_y[];
   //--- Массив со статистическими показателями
   string            m_stat_data[];
   //---
public:
   //---
                     CFrameGenerator(void);
                    ~CFrameGenerator(void);
   //--- Установка количества серий для отображения на графике
   void              SetCurvesTotal(const uint total);
   //--- (1) Количество фреймов, (2) текущий индекс проверяемого фрейма, (3) текущий фрейм
   ulong             FramesTotal(void)  { return(m_frames_total);   }
   ulong             CurrentFrame(void) { return(m_frames_counter); }
   ulong             CurrentPass(void)  { return(m_pass);           }
   //--- Количество отрицательных/положительных исходов
   int               LossesTotal(void)  { return(::ArraySize(m_loss_y));   }
   int               ProfitsTotal(void) { return(::ArraySize(m_profit_y)); }

   //--- Обработчики событий тестера стратегий
   void              OnTesterEvent(const double on_tester_value);
   void              OnTesterInitEvent(CGraphic *graph_balance,CGraphic *graph_results);
   void              OnTesterDeinitEvent(void);
   bool              OnTesterPassEvent(void);
   //---
public:
   //--- Перебор фреймов
   bool              ReplayFrames(void);

   //--- Возвращает статистические показатели в переданный массив
   int               CopyStatData(string &dst_array[]) { return(::ArrayCopy(dst_array,m_stat_data));  }
   //--- Возвращает параметры эксперта в переданный массив
   int               CopyParamData(string &dst_array[]) { return(::ArrayCopy(dst_array,m_param_data)); }
   //---
private:
   //--- Получает данные баланса
   int               GetBalanceData(void);
   //--- Получает статистические данные
   void              GetStatData(double &dst_array[],double on_tester_value);

   //--- Освободить массивы
   void              ArraysFree(void);
   //--- Сохранить статистические данные 
   void              SaveStatData(void);

   //--- Обновить график результатов
   void              UpdateResultsGraph(void);
   //--- Обновить график балансов
   void              UpdateBalanceGraph(void);

   //--- Финальный пересчёт данных со всех фреймов после оптимизации
   void              FinalRecalculateFrames(void);

   //--- Добавляет (1) отрицательный и (2) положительный результат в массивы
   void              AddLoss(const double loss);
   void              AddProfit(const double profit);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CFrameGenerator::CFrameGenerator(void) : m_curves_total(0),
                                         m_frames_counter(0),
                                         m_frames_total(0)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CFrameGenerator::~CFrameGenerator(void)
  {
  }
//+------------------------------------------------------------------+
//| Установка количества серий для отображения на графике            |
//+------------------------------------------------------------------+
void CFrameGenerator::SetCurvesTotal(const uint total)
  {
   m_curves_total=total;
   ::ArrayResize(m_curve_max,total);
   ::ArrayInitialize(m_curve_max,0);
  }
//+------------------------------------------------------------------+
//| Должна вызываться в обработчике OnTesterInit()                   |
//+------------------------------------------------------------------+
void CFrameGenerator::OnTesterInitEvent(CGraphic *graph_balance,CGraphic *graph_results)
  {
   m_graph_balance =graph_balance;
   m_graph_results =graph_results;
  }
//+------------------------------------------------------------------+
//| Должна вызываться в обработчике OnTesterDeinit()                 |
//+------------------------------------------------------------------+
void CFrameGenerator::OnTesterDeinitEvent(void)
  {
//--- Финальный пересчёт данных со всех фреймов после оптимизации
   FinalRecalculateFrames();
//--- Запоминаем общее количество фреймов и обнуляем счётчики
   m_frames_total     =m_frames_counter;
   m_frames_counter   =0;
   m_last_serie_index =0;
  }
//+------------------------------------------------------------------+
//| Готовит массив значений баланса и отправляет его во фрейме       |
//| Функция должна вызываться в эксперте в обработчике  OnTester()   |
//+------------------------------------------------------------------+
void CFrameGenerator::OnTesterEvent(const double on_tester_value)
  {
//--- Получим данные баланса
   int data_count=GetBalanceData();
//--- Массив для отправки данных во фрейм
   double stat_data[];
   GetStatData(stat_data,on_tester_value);
//--- Cоздадим фрейм с данными и отправим его в терминал
   if(!::FrameAdd(::MQLInfoString(MQL_PROGRAM_NAME),1,data_count,stat_data))
      ::Print(__FUNCTION__," > Frame add error: ",::GetLastError());
   else
      ::Print(__FUNCTION__," > Frame added, Ok");
  }
//+------------------------------------------------------------------+
//| Получает фрейм с данными при оптимизации и отображает график     |
//+------------------------------------------------------------------+
bool CFrameGenerator::OnTesterPassEvent(void)
  {
//--- При получении нового фрейма пытаемся получить из него данные
   if(::FrameNext(m_pass,m_name,m_id,m_value,m_data))
     {
      //--- Получим входные параметры эксперта, для которых сформирован фрейм
      ::FrameInputs(m_pass,m_param_data,m_par_count);
      //--- Сохраняем статистические показатели результата в массив
      SaveStatData();
      //--- Обновить график результатов и балансов
      UpdateResultsGraph();
      UpdateBalanceGraph();
      //--- Увеличим счетчик обработанных фреймов
      m_frames_counter++;
      return(true);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Получает данные баланса                                          |
//+------------------------------------------------------------------+
int CFrameGenerator::GetBalanceData(void)
  {
   int    data_count      =0;
   double balance_current =0;
//--- Запросим всю торговую историю
   ::HistorySelect(0,LONG_MAX);
   uint deals_total=::HistoryDealsTotal();
//--- Собираем данные о сделках
   for(uint i=0; i<deals_total; i++)
     {
      //--- Получили тикет
      ulong ticket=::HistoryDealGetTicket(i);
      if(ticket<1)
         continue;
      //--- Если начальный баланс или out-/inout-сделка
      long entry=::HistoryDealGetInteger(ticket,DEAL_ENTRY);
      if(i==0 || entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_INOUT)
        {
         double swap      =::HistoryDealGetDouble(ticket,DEAL_SWAP);
         double profit    =::HistoryDealGetDouble(ticket,DEAL_PROFIT);
         double commision =::HistoryDealGetDouble(ticket,DEAL_COMMISSION);
         //--- Расчёт баланса
         balance_current+=(profit+swap+commision);
         //--- Сохранить в массив
         data_count++;
         ::ArrayResize(m_balance,data_count,1000000);
         m_balance[data_count-1]=balance_current;
        }
     }
//--- Вернуть количество данных
   return(data_count);
  }
//+------------------------------------------------------------------+
//| Получает статистические данные                                   |
//+------------------------------------------------------------------+
void CFrameGenerator::GetStatData(double &dst_array[],double on_tester_value)
  {
   ::ArrayResize(dst_array,::ArraySize(m_balance)+STAT_TOTAL);
   ::ArrayCopy(dst_array,m_balance,STAT_TOTAL,0);
//--- Заполним первые значения массива (STAT_TOTAL) результатами тестирования
   dst_array[0] =::TesterStatistics(STAT_PROFIT);               // чистая прибыль
   dst_array[1] =::TesterStatistics(STAT_PROFIT_FACTOR);        // фактор прибыльности
   dst_array[2] =::TesterStatistics(STAT_RECOVERY_FACTOR);      // фактор восстановления
   dst_array[3] =::TesterStatistics(STAT_TRADES);               // количество трейдов
   dst_array[4] =::TesterStatistics(STAT_DEALS);                // количество сделок
   dst_array[5] =::TesterStatistics(STAT_EQUITY_DDREL_PERCENT); // максимальная просадка средств в процентах
   dst_array[6] =on_tester_value;                               // значение пользовательского критерия оптимизации
  }
//+------------------------------------------------------------------+
//| Повторное проигрывание фреймов после окончания оптимизации       |
//+------------------------------------------------------------------+
bool CFrameGenerator::ReplayFrames(void)
  {
//--- Переводим указатель фреймов в начало
   if(m_frames_counter<1)
     {
      ArraysFree();
      ::FrameFirst();
     }
//--- Запускаем перебор фреймов
   if(::FrameNext(m_pass,m_name,m_id,m_value,m_data))
     {
      //--- Получим входные параметры эксперта, для которых сформирован фрейм
      ::FrameInputs(m_pass,m_param_data,m_par_count);
      //--- Сохраняем статистические показатели результата в массив
      SaveStatData();
      //--- Обновить график результатов и балансов
      UpdateResultsGraph();
      UpdateBalanceGraph();
      //--- Увеличим счетчик обработанных фреймов
      m_frames_counter++;
      return(true);
     }
//--- Закончили перебор
   m_frames_counter   =0;
   m_last_serie_index =0;
   return(false);
  }
//+------------------------------------------------------------------+
//| Освободить массивы                                               |
//+------------------------------------------------------------------+
void CFrameGenerator::ArraysFree(void)
  {
   ::ArrayFree(m_loss_y);
   ::ArrayFree(m_loss_x);
   ::ArrayFree(m_profit_y);
   ::ArrayFree(m_profit_x);
  }
//+------------------------------------------------------------------+
//| Сохраняет статистические показатели результата в массив          |
//+------------------------------------------------------------------+
void CFrameGenerator::SaveStatData(void)
  {
//--- Массив для приёма статистических показателей фрейма
   double stat[];
   ::ArrayCopy(stat,m_data,0,0,STAT_TOTAL);
   ::ArrayResize(m_stat_data,STAT_TOTAL);
//--- Заполним массив результатами тестирования
   m_stat_data[0] ="Net profit="+::StringFormat("%.2f",stat[0]);
   m_stat_data[1] ="Profit Factor="+::StringFormat("%.2f",stat[1]);
   m_stat_data[2] ="Factor Recovery="+::StringFormat("%.2f",stat[2]);
   m_stat_data[3] ="Trades="+::StringFormat("%G",stat[3]);
   m_stat_data[4] ="Deals="+::StringFormat("%G",stat[4]);
   m_stat_data[5] ="Equity DD="+::StringFormat("%.2f%%",stat[5]);
   m_stat_data[6] ="OnTester()="+::StringFormat("%G",stat[6]);
  }
//+------------------------------------------------------------------+
//| Обновить график результатов                                      |
//+------------------------------------------------------------------+
void CFrameGenerator::UpdateResultsGraph(void)
  {
//--- Отрицательный результат
   if(m_data[0]<0)
      AddLoss(m_data[0]);
//--- Положительный результат
   else
      AddProfit(m_data[0]);
//--- Обновить серии на графике результатов оптимизации
   CCurve *curve=m_graph_results.CurveGetByIndex(0);
   curve.Name("P: "+(string)ProfitsTotal());
   curve.Update(m_profit_x,m_profit_y);
//---
   curve=m_graph_results.CurveGetByIndex(1);
   curve.Name("L: "+(string)LossesTotal());
   curve.Update(m_loss_x,m_loss_y);
//--- Свойства горизонтальной оси
   CAxis *x_axis=m_graph_results.XAxis();
   x_axis.Min(0);
   x_axis.Max(m_frames_counter);
   x_axis.DefaultStep((int)(m_frames_counter/8.0));
//--- Обновить график
   m_graph_results.CalculateMaxMinValues();
   m_graph_results.CurvePlotAll();
   m_graph_results.Update();
  }
//+------------------------------------------------------------------+
//| Обновить график балансов                                         |
//+------------------------------------------------------------------+
void CFrameGenerator::UpdateBalanceGraph(void)
  {
//--- Массив для приема значений баланса текущего фрейма
   double serie[];
   ::ArrayCopy(serie,m_data,0,STAT_TOTAL,::ArraySize(m_data)-STAT_TOTAL);
//--- Отправим массив для вывода на график баланса
   CCurve *curve=m_graph_balance.CurveGetByIndex(m_last_serie_index);
   curve.Name((string)m_frames_counter);
   curve.Color((m_data[0]>=0)? ::ColorToARGB(clrLimeGreen) : ::ColorToARGB(clrRed));
   curve.Update(serie);
//--- Получим размер серии
   int serie_size=::ArraySize(serie);
   m_curve_max[m_last_serie_index]=serie_size;
//--- Определим ряд с максимальным количеством элементов
   double x_max=0;
   for(uint i=0; i<m_curves_total; i++)
      x_max=::fmax(x_max,m_curve_max[i]);
//--- Свойства горизонтальной оси
   CAxis *x_axis=m_graph_balance.XAxis();
   x_axis.Min(0);
   x_axis.Max(x_max);
   x_axis.DefaultStep((int)(x_max/8.0));
//--- Обновить график
   m_graph_balance.CalculateMaxMinValues();
   m_graph_balance.CurvePlotAll();
   m_graph_balance.Update();
//--- Увеличим счётчик серий
   m_last_serie_index++;
//--- Если дошли до лимита, обнулим счётчик серий
   if(m_last_serie_index>=m_curves_total)
      m_last_serie_index=0;
  }
//+------------------------------------------------------------------+
//| Финальный пересчёт данных со всех фреймов после оптимизации      |
//+------------------------------------------------------------------+
void CFrameGenerator::FinalRecalculateFrames(void)
  {
//--- Переводим указатель фреймов в начало
   ::FrameFirst();
//--- Сброс счётчика и массивов
   ArraysFree();
   m_frames_counter=0;
//--- Запускаем перебор фреймов
   while(::FrameNext(m_pass,m_name,m_id,m_value,m_data))
     {
      //--- Отрицательный результат
      if(m_data[0]<0)
         AddLoss(m_data[0]);
      //--- Положительный результат
      else
         AddProfit(m_data[0]);
      //--- Увеличим счетчик обработанных фреймов
      m_frames_counter++;
     }
//--- Обновить серии на графике
   CCurve *curve=m_graph_results.CurveGetByIndex(0);
   curve.Name("P: "+(string)ProfitsTotal());
   curve.Update(m_profit_x,m_profit_y);
//---
   curve=m_graph_results.CurveGetByIndex(1);
   curve.Name("L: "+(string)LossesTotal());
   curve.Update(m_loss_x,m_loss_y);
//--- Свойства горизонтальной оси
   CAxis *x_axis=m_graph_results.XAxis();
   x_axis.Min(0);
   x_axis.Max(m_frames_counter);
   x_axis.DefaultStep((int)(m_frames_counter/8.0));
//--- Обновить график
   m_graph_results.CalculateMaxMinValues();
   m_graph_results.CurvePlotAll();
   m_graph_results.Update();
  }
//+------------------------------------------------------------------+
//| Добавляет отрицательный результат в массивы                      |
//+------------------------------------------------------------------+
void CFrameGenerator::AddLoss(const double loss)
  {
   int size=::ArraySize(m_loss_y);
   ::ArrayResize(m_loss_y,size+1,RESERVE_FRAMES);
   ::ArrayResize(m_loss_x,size+1,RESERVE_FRAMES);
   m_loss_y[size] =loss;
   m_loss_x[size] =(double)m_frames_counter;
  }
//+------------------------------------------------------------------+
//| Добавляет положительный результат в массивы                      |
//+------------------------------------------------------------------+
void CFrameGenerator::AddProfit(const double profit)
  {
   int size=::ArraySize(m_profit_y);
   ::ArrayResize(m_profit_y,size+1,RESERVE_FRAMES);
   ::ArrayResize(m_profit_x,size+1,RESERVE_FRAMES);
   m_profit_y[size] =profit;
   m_profit_x[size] =(double)m_frames_counter;
  }
//+------------------------------------------------------------------+

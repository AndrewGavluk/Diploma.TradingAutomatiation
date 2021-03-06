//+------------------------------------------------------------------+
//|                                                      Program.mqh |
//|                                   Copyright 2018, Andrey Gavluck |
//|                                            gavl.andr96@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Andrey Gavluck"
#property link      "gavl.andr96@gmail.com"
#include <EasyAndFastGUI\WndEvents.mqh>
#include "Strategy.mqh"
#include "FrameGenerator.mqh"
#include "FormatString.mqh"

class CProgram : public CWndEvents
  {
private:
   //--- Стратегия
   CStrategy         m_strategy;
   //--- Генератор фреймов
   CFrameGenerator   m_frame_gen;

   //--- Окно
   CWindow           m_window1;
   //--- Статусная строка
   CStatusBar        m_status_bar;
   //--- Поля ввода
   CTextEdit         m_curves_total;
   CTextEdit         m_sleep_ms;
   //--- Кнопки
   CButton           m_reply_frames;
   //--- Таблицы
   CTable            m_table_stat;
   CTable            m_table_param;
   //--- Графики
   CGraph            m_graph1;
   CGraph            m_graph2;
   //--- Индикатор выполнения
   CProgressBar      m_progress_bar;
   //---
public:
                     CProgram(void);
                    ~CProgram(void);
   //--- Инициализация/деинициализация
   bool              OnInitEvent(void);
   void              OnDeinitEvent(const int reason);
   //--- Обработчик события "новый тик"
   void              OnTickEvent(void);
   //--- Обработчик торгового события
   void              OnTradeEvent(void);
   //--- Таймер
   void              OnTimerEvent(void);
   //--- Тестер
   double            OnTesterEvent(void);
   void              OnTesterPassEvent(void);
   void              OnTesterInitEvent(void);
   void              OnTesterDeinitEvent(void);
   //---
protected:
   //--- Обработчик событий графика
   virtual void      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   //---
public:
   //--- Создаёт графический интерфейс для работы с фреймами в режиме оптимизации
   bool              CreateFrameModeGUI(void);
   //---
private:
   //--- Форма
   bool              CreateWindow(const string text);
   //--- Статусная строка
   bool              CreateStatusBar(const int x_gap,const int y_gap);
   //--- Таблицы
   bool              CreateTableStat(const int x_gap,const int y_gap);
   bool              CreateTableParam(const int x_gap,const int y_gap);
   //--- Поля ввода
   bool              CreateCurvesTotal(const int x_gap,const int y_gap,const string text);
   bool              CreateSleep(const int x_gap,const int y_gap,const string text);
   //--- Кнопки
   bool              CreateReplyFrames(const int x_gap,const int y_gap,const string text);
   //--- Графики
   bool              CreateGraph1(const int x_gap,const int y_gap);
   bool              CreateGraph2(const int x_gap,const int y_gap);
   //--- Индикатор выполнения
   bool              CreateProgressBar(const int x_gap,const int y_gap,const string text);
   //---
private:
   //--- Доступность интерфейса
   void              IsAvailableGUI(const bool state);
   void              IsLockedGUI(const bool state);

   //--- Расчёт соотношения положительных и отрицательных исходов
   void              CalculateProfitsAndLosses(void);

   //--- Обновление статистической таблицы
   void              UpdateStatTable(void);
   //--- Обновление таблицы параметров
   void              UpdateParamTable(void);
   //--- Обновление графика
   void              UpdateBalanceGraph(void);

   //--- Просмотреть результаты оптимизации
   void              ViewOptimizationResults(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CProgram::CProgram(void)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CProgram::~CProgram(void)
  {
  }
//+------------------------------------------------------------------+
//| Инициализация                                                    |
//+------------------------------------------------------------------+
bool CProgram::OnInitEvent(void)
  {
   if(!m_strategy.OnInitEvent())
      return(false);
//--- Инициализация прошла успешно
   return(true);
  }
//+------------------------------------------------------------------+
//| Деинициализация                                                  |
//+------------------------------------------------------------------+
void CProgram::OnDeinitEvent(const int reason)
  {
//--- Удаление интерфейса
   CWndEvents::Destroy();
  }
//+------------------------------------------------------------------+
//| Событие торговой операции                                        |
//+------------------------------------------------------------------+
void CProgram::OnTradeEvent(void)
  {
  }
//+------------------------------------------------------------------+
//| Таймер                                                           |
//+------------------------------------------------------------------+
void CProgram::OnTimerEvent(void)
  {
   CWndEvents::OnTimerEvent();
  }
//+------------------------------------------------------------------+
//| Событие "новый тик"                                              |
//+------------------------------------------------------------------+
void CProgram::OnTickEvent(void)
  {
   m_strategy.OnTickEvent();
  }
//+------------------------------------------------------------------+
//| Событие окончания теста                                          |
//+------------------------------------------------------------------+
double CProgram::OnTesterEvent(void)
  {
//--- Функция вычисления критерия оптимизации
   double TesterCritetia=MathAbs(TesterStatistics(STAT_SHARPE_RATIO)*TesterStatistics(STAT_PROFIT));
   TesterCritetia=TesterStatistics(STAT_PROFIT)>0? TesterCritetia :(-TesterCritetia);
//--- Вызываем на каждом окончании тестирования и передаем в качестве параметра критерий оптимизации
   m_frame_gen.OnTesterEvent(TesterCritetia);
   return(TesterCritetia);
  }
//+------------------------------------------------------------------+
//| Событие начала процесса оптимизации                              |
//+------------------------------------------------------------------+
void CProgram::OnTesterInitEvent(void)
  {
//--- Создание графического интерфейса
   if(!CreateFrameModeGUI())
     {
      ::Print(__FUNCTION__," > Could not create the GUI!");
      return;
     }
//--- Сделать интерфейс недоступным
   IsLockedGUI(false);
//--- Инициализация генератора фреймов
   m_frame_gen.OnTesterInitEvent(m_graph1.GetGraphicPointer(),m_graph2.GetGraphicPointer());
  }
//+------------------------------------------------------------------+
//| Событие обработки прохода оптимизации                            |
//+------------------------------------------------------------------+
void CProgram::OnTesterPassEvent(void)
  {
//--- Обрабатываем полученные результаты тестирования и выводим графику
   if(m_frame_gen.OnTesterPassEvent())
     {
      UpdateStatTable();
      UpdateParamTable();
     }
  }
//+------------------------------------------------------------------+
//| Событие окончания процесса оптимизации                           |
//+------------------------------------------------------------------+
void CProgram::OnTesterDeinitEvent(void)
  {
//--- Завершение оптимизации
   m_frame_gen.OnTesterDeinitEvent();
//--- Сделать интерфейс доступным
   IsLockedGUI(true);
//--- Расчёт соотношения положительных и отрицательных исходов
   CalculateProfitsAndLosses();
//--- Инициализация ядра GUI
   CWndEvents::InitializeCore();
  }
//+------------------------------------------------------------------+
//| Обработчик событий                                               |
//+------------------------------------------------------------------+
void CProgram::OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
//--- События нажатия на кнопках
   if(id==CHARTEVENT_CUSTOM+ON_CLICK_BUTTON)
     {
      //--- Просмотреть результаты оптимизации 
      if(lparam==m_reply_frames.Id())
        {
         ViewOptimizationResults();
         return;
        }
      //--- Изменить количество серий на графике
      if(lparam==m_curves_total.Id())
        {
         UpdateBalanceGraph();
         return;
        }
      return;
     }
//--- События ввода значения в поле ввода
   if(id==CHARTEVENT_CUSTOM+ON_END_EDIT)
     {
      //--- Изменить количество серий на графике
      if(lparam==m_curves_total.Id())
        {
         UpdateBalanceGraph();
         return;
        }
      return;
     }
  }
//+------------------------------------------------------------------+
//| Методы для создания элементов управления                         |
//+------------------------------------------------------------------+
#include "CreateFrameModeGUI.mqh"
//+------------------------------------------------------------------+
//| Доступность интерфейса                                           |
//+------------------------------------------------------------------+
void CProgram::IsAvailableGUI(const bool state)
  {
   m_window1.IsAvailable(state);
   m_sleep_ms.IsAvailable(state);
   m_curves_total.IsAvailable(state);
   m_reply_frames.IsAvailable(state);
  }
//+------------------------------------------------------------------+
//| Блокировка интерфейса                                            |
//+------------------------------------------------------------------+
void CProgram::IsLockedGUI(const bool state)
  {
   m_window1.IsAvailable(state);
   m_sleep_ms.IsLocked(!state);
   m_curves_total.IsLocked(!state);
   m_reply_frames.IsLocked(!state);
  }
//+------------------------------------------------------------------+
//| Расчёт соотношения положительных и отрицательных исходов         |
//+------------------------------------------------------------------+
void CProgram::CalculateProfitsAndLosses(void)
  {
//--- Выйти, если нет фреймов
   if(m_frame_gen.FramesTotal()<1)
      return;
//--- Количество отрицательных и положительных результатов
   int losses  =m_frame_gen.LossesTotal();
   int profits =m_frame_gen.ProfitsTotal();
//--- Процентное соотношение
   string pl =::DoubleToString(((double)losses/(double)m_frame_gen.FramesTotal())*100,2);
   string pp =::DoubleToString(((double)profits/(double)m_frame_gen.FramesTotal())*100,2);;
//--- Вывод на строку состояния
   m_status_bar.SetValue(1,"Profits: "+(string)profits+" ("+pp+"%)"+" / Losses: "+(string)losses+" ("+pl+"%)");
   m_status_bar.GetItemPointer(1).Update(true);
  }
//+------------------------------------------------------------------+
//| Обновление статистической таблицы                                |
//+------------------------------------------------------------------+
void CProgram::UpdateStatTable(void)
  {
//--- Получим массив данных для статистической таблицы
   string stat_data[];
   int total=m_frame_gen.CopyStatData(stat_data);
   for(int i=0; i<total; i++)
     {
      //--- Расщепим на две строки и занесём в таблицу
      string array[];
      if(::StringSplit(stat_data[i],'=',array)==2)
        {
         if(m_frame_gen.CurrentFrame()>1)
            m_table_stat.SetValue(1,i,array[1],0,true);
         else
           {
            m_table_stat.SetValue(0,i,array[0],0,true);
            m_table_stat.SetValue(1,i,array[1],0,true);
           }
        }
     }
//--- Обновить таблицу
   m_table_stat.Update();
  }
//+------------------------------------------------------------------+
//| Обновление таблицы параметров                                    |
//+------------------------------------------------------------------+
void CProgram::UpdateParamTable(void)
  {
//--- Получим массив данных для таблицы параметров
   string param_data[];
   int total=m_frame_gen.CopyParamData(param_data);
   for(int i=0; i<total; i++)
     {
      //--- Расщепим на две строки и занесём в таблицу
      string array[];
      if(::StringSplit(param_data[i],'=',array)==2)
        {
         if(m_frame_gen.CurrentFrame()>1)
            m_table_param.SetValue(1,i,array[1],0,true);
         else
           {
            m_table_param.SetValue(0,i,array[0],0,true);
            m_table_param.SetValue(1,i,array[1],0,true);
           }
        }
     }
//--- Обновить таблицу
   m_table_param.Update();
  }
//+------------------------------------------------------------------+
//| Обновление графика                                               |
//+------------------------------------------------------------------+
void CProgram::UpdateBalanceGraph(void)
  {
//--- Установить количество серий для работы
   int curves_total=(int)m_curves_total.GetValue();
   m_frame_gen.SetCurvesTotal(curves_total);
//--- Удалить серии
   CGraphic *graph=m_graph1.GetGraphicPointer();
   int total=graph.CurvesTotal();
   for(int i=total-1; i>=0; i--)
      graph.CurveRemoveByIndex(i);
//--- Добавить серии
   double data[];
   for(int i=0; i<curves_total; i++)
      graph.CurveAdd(data,CURVE_LINES,"");
//--- Обновить график
   graph.CurvePlotAll();
   graph.Update();
  }
//+------------------------------------------------------------------+
//| Просмотреть результаты оптимизации                               |
//+------------------------------------------------------------------+
void CProgram::ViewOptimizationResults(void)
  {
//--- Сделать интерфейс недоступным
   IsAvailableGUI(false);
//--- Пауза
   int pause=(int)m_sleep_ms.GetValue();
//--- Запуск воспроизведения фреймов
   while(m_frame_gen.ReplayFrames() && !::IsStopped())
     {
      //--- Обновить таблицы
      UpdateStatTable();
      UpdateParamTable();
      //--- Обновить прогресс-бар
      m_progress_bar.Show();
      m_progress_bar.LabelText("Replay frames: "+string(m_frame_gen.CurrentFrame())+"/"+string(m_frame_gen.FramesTotal()));
      m_progress_bar.Update((int)m_frame_gen.CurrentFrame(),(int)m_frame_gen.FramesTotal());
      //--- Пауза
      ::Sleep(pause);
     }
//--- Расчёт соотношения положительных и отрицательных исходов
   CalculateProfitsAndLosses();
//--- Скрыть прогресс-бар
   m_progress_bar.Hide();
//--- Сделать интерфейс доступным
   IsAvailableGUI(true);
   m_reply_frames.MouseFocus(false);
   m_reply_frames.Update(true);
  }
//+------------------------------------------------------------------+

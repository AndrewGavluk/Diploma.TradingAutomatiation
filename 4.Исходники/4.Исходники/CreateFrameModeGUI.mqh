//+------------------------------------------------------------------+
//|                                           CreateFrameModeGUI.mqh |
//|                                   Copyright 2018, Andrey Gavluck |
//|                                            gavl.andr96@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Andrey Gavluck"
#property link      "gavl.andr96@gmail.com"
#include "Program.mqh"
//+------------------------------------------------------------------+
//| Создаёт графический интерфейс                                    |
//| для анализа результатов оптимизации и работы с фреймами          |
//+------------------------------------------------------------------+
bool CProgram::CreateFrameModeGUI(void)
  {
//--- Создание этого интерфейса только в режиме работы с фреймами оптимизации
   if(!::MQLInfoInteger(MQL_FRAME_MODE))
      return(false);
//--- Создание формы для элементов управления
   if(!CreateWindow("Frame mode"))
      return(false);
//--- Создание элементов управления
   if(!CreateStatusBar(1,23))
      return(false);
   if(!CreateCurvesTotal(7,25,"Curves total:"))
      return(false);
   if(!CreateSleep(145,25,"Sleep:"))
      return(false);
   if(!CreateReplyFrames(255,25,"Replay frames"))
      return(false);
   if(!CreateTableStat(2,50))
      return(false);
   if(!CreateTableParam(2,212))
      return(false);
   if(!CreateGraph1(200,50))
      return(false);
   if(!CreateGraph2(200,159))
      return(false);
//--- Индикатор выполнения
   if(!CreateProgressBar(2,3,"Processing..."))
      return(false);
//--- Завершение создания GUI
   CWndEvents::CompletedGUI();
   return(true);
  }
//+------------------------------------------------------------------+
//| Создаёт форму для элементов управления                           |
//+------------------------------------------------------------------+
bool CProgram::CreateWindow(const string caption_text)
  {
//--- Добавим указатель окна в массив окон
   CWndContainer::AddWindow(m_window1);
//--- Размеры
   int x_size =700;
   int y_size =480;
//--- Координаты
   int x =(m_window1.X()>1)? m_window1.X() : 1;
   int y =(m_window1.Y()>1)? m_window1.Y() : 1;
//--- Свойства
   m_window1.XSize(x_size);
   m_window1.YSize(y_size);
   m_window1.IsMovable(false);
   m_window1.ResizeMode(true);
   m_window1.CloseButtonIsUsed(true);
   m_window1.CollapseButtonIsUsed(true);
   m_window1.TooltipsButtonIsUsed(true);
   m_window1.FullscreenButtonIsUsed(true);
   m_window1.TransparentOnlyCaption(true);
//--- Установим всплывающие подсказки
   m_window1.GetCloseButtonPointer().Tooltip("Close");
   m_window1.GetTooltipButtonPointer().Tooltip("Tooltips");
   m_window1.GetFullscreenButtonPointer().Tooltip("Fullscreen");
   m_window1.GetCollapseButtonPointer().Tooltip("Collapse/Expand");
//--- Создание формы
   if(!m_window1.CreateWindow(m_chart_id,m_subwin,caption_text,x,y))
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Создаёт статусную строку                                         |
//+------------------------------------------------------------------+
bool CProgram::CreateStatusBar(const int x_gap,const int y_gap)
  {
#define STATUS_LABELS_TOTAL 2
//--- Сохраним указатель на окно
   m_status_bar.MainPointer(m_window1);
//--- Ширина
   int width[]={0,250};
//--- Установим свойства перед созданием
   m_status_bar.YSize(22);
   m_status_bar.AutoXResizeMode(true);
   m_status_bar.AutoXResizeRightOffset(1);
   m_status_bar.AnchorBottomWindowSide(true);
//--- Укажем сколько должно быть частей и установим им свойства
   for(int i=0; i<STATUS_LABELS_TOTAL; i++)
      m_status_bar.AddItem(width[i]);
//--- Создадим элемент управления
   if(!m_status_bar.CreateStatusBar(x_gap,y_gap))
      return(false);
//--- Установка текста в первый пункт статусной строки
   m_status_bar.SetValue(0,"Press the button 'Replay frames' to view the frames");
   m_status_bar.SetValue(1,"");
//--- Добавим объект в общий массив групп объектов
   CWndContainer::AddToElementsArray(0,m_status_bar);
   return(true);
  }
//+------------------------------------------------------------------+
//| Создаёт прогресс бар                                             |
//+------------------------------------------------------------------+
bool CProgram::CreateProgressBar(const int x_gap,const int y_gap,const string text)
  {
//--- Сохраним указатель на главный элемент
   m_progress_bar.MainPointer(m_status_bar);
//--- Свойства
   m_progress_bar.XSize(220);
   m_progress_bar.YSize(17);
   m_progress_bar.BarYSize(14);
   m_progress_bar.BarXGap(0);
   m_progress_bar.BarYGap(1);
   m_progress_bar.LabelXGap(5);
   m_progress_bar.LabelYGap(2);
   m_progress_bar.PercentXGap(5);
   m_progress_bar.PercentYGap(2);
   m_progress_bar.BorderColor(clrSilver);
   m_progress_bar.IndicatorBackColor(clrWhiteSmoke);
   m_progress_bar.IndicatorColor(clrLightGreen);
   m_progress_bar.AutoXResizeMode(true);
   m_progress_bar.AutoXResizeRightOffset(2);
   m_progress_bar.IsDropdown(true);
   m_progress_bar.Font("Consolas");
//--- Создание элемента
   if(!m_progress_bar.CreateProgressBar(text,x_gap,y_gap))
      return(false);
//--- Добавим указатель на элемент в базу
   CWndContainer::AddToElementsArray(0,m_progress_bar);
   return(true);
  }
//+------------------------------------------------------------------+
//| Создаёт чекбокс с полем ввода "Curves total"                     |
//+------------------------------------------------------------------+
bool CProgram::CreateCurvesTotal(const int x_gap,const int y_gap,const string text)
  {
//--- Сохраним указатель на главный элемент
   m_curves_total.MainPointer(m_window1);
//--- Свойства
   m_curves_total.XSize(125);
   m_curves_total.MaxValue(50);
   m_curves_total.MinValue(1);
   m_curves_total.StepValue(1);
   m_curves_total.SetDigits(0);
   m_curves_total.SpinEditMode(true);
   m_curves_total.SetValue((string)10);
   m_curves_total.GetTextBoxPointer().XSize(60);
   m_curves_total.GetTextBoxPointer().AutoSelectionMode(true);
   m_curves_total.GetTextBoxPointer().AnchorRightWindowSide(true);
//--- Создадим элемент управления
   if(!m_curves_total.CreateTextEdit(text,x_gap,y_gap))
      return(false);
//--- Добавим объект в общий массив групп объектов
   CWndContainer::AddToElementsArray(0,m_curves_total);
   return(true);
  }
//+------------------------------------------------------------------+
//| Создаёт чекбокс с полем ввода "Sleep (ms)"                       |
//+------------------------------------------------------------------+
bool CProgram::CreateSleep(const int x_gap,const int y_gap,const string text)
  {
//--- Сохраним указатель на главный элемент
   m_sleep_ms.MainPointer(m_window1);
//--- Свойства
   m_sleep_ms.XSize(95);
   m_sleep_ms.MaxValue(100);
   m_sleep_ms.MinValue(0);
   m_sleep_ms.StepValue(1);
   m_sleep_ms.SetDigits(0);
   m_sleep_ms.SpinEditMode(true);
   m_sleep_ms.SetValue((string)0);
   m_sleep_ms.GetTextBoxPointer().XSize(60);
   m_sleep_ms.GetTextBoxPointer().AutoSelectionMode(true);
   m_sleep_ms.GetTextBoxPointer().AnchorRightWindowSide(true);
//--- Создадим элемент управления
   if(!m_sleep_ms.CreateTextEdit(text,x_gap,y_gap))
      return(false);
//--- Добавим объект в общий массив групп объектов
   CWndContainer::AddToElementsArray(0,m_sleep_ms);
   return(true);
  }
//+------------------------------------------------------------------+
//| Создаёт кнопку для обновления графика с результатом теста        |
//+------------------------------------------------------------------+
bool CProgram::CreateReplyFrames(const int x_gap,const int y_gap,const string text)
  {
//--- Сохраним указатель на главный элемент
   m_reply_frames.MainPointer(m_window1);
//--- Свойства
   m_reply_frames.XSize(90);
   m_reply_frames.YSize(20);
   m_reply_frames.IconXGap(3);
   m_reply_frames.IconYGap(3);
   m_reply_frames.IsCenterText(true);
//--- Создадим элемент управления
   if(!m_reply_frames.CreateButton(text,x_gap,y_gap))
      return(false);
//--- Добавим указатель на элемент в базу
   CWndContainer::AddToElementsArray(0,m_reply_frames);
   return(true);
  }
//+------------------------------------------------------------------+
//| Создаёт таблицу статистики                                       |
//+------------------------------------------------------------------+
bool CProgram::CreateTableStat(const int x_gap,const int y_gap)
  {
#define COLUMNS1_TOTAL 2
#define ROWS1_TOTAL    7
//--- Сохраним указатель на главный элемент
   m_table_stat.MainPointer(m_window1);
//--- Массив ширины столбцов
   int width[COLUMNS1_TOTAL];
   ::ArrayInitialize(width,100);
   width[1]=96;
//--- Массив отступа текста в столбцах по оси X
   int text_x_offset[COLUMNS1_TOTAL];
   ::ArrayInitialize(text_x_offset,7);
//--- Массив выравнивания текста в столбцах
   ENUM_ALIGN_MODE align[COLUMNS1_TOTAL];
   ::ArrayInitialize(align,ALIGN_LEFT);
   align[0]=ALIGN_RIGHT;
//--- Свойства
   m_table_stat.XSize(197);
   m_table_stat.YSize(161);
   m_table_stat.CellYSize(20);
   m_table_stat.TableSize(COLUMNS1_TOTAL,ROWS1_TOTAL);
   m_table_stat.TextAlign(align);
   m_table_stat.ColumnsWidth(width);
   m_table_stat.TextXOffset(text_x_offset);
   m_table_stat.LabelXGap(5);
   m_table_stat.LabelYGap(4);
   m_table_stat.ShowHeaders(true);
   m_table_stat.IsSortMode(false);
   m_table_stat.LightsHover(false);
   m_table_stat.SelectableRow(false);
   m_table_stat.IsWithoutDeselect(false);
   m_table_stat.ColumnResizeMode(false);
   m_table_stat.IsZebraFormatRows(clrWhiteSmoke);
   m_table_stat.IsDisabledScrolls(true);
//--- Установим названия заголовков
   m_table_stat.SetHeaderText(0,"Description");
   m_table_stat.SetHeaderText(1,"Value");
//--- Создадим элемент управления
   if(!m_table_stat.CreateTable(x_gap,y_gap))
      return(false);
//--- Добавим объект в общий массив групп объектов
   CWndContainer::AddToElementsArray(0,m_table_stat);
   return(true);
  }
//+------------------------------------------------------------------+
//| Создаёт таблицу параметров                                       |
//+------------------------------------------------------------------+
bool CProgram::CreateTableParam(const int x_gap,const int y_gap)
  {
#define COLUMNS2_TOTAL 2
#define ROWS2_TOTAL    5
//--- Сохраним указатель на главный элемент
   m_table_param.MainPointer(m_window1);
//--- Массив ширины столбцов
   int width[COLUMNS2_TOTAL];
   ::ArrayInitialize(width,100);
   width[1]=96;
//--- Массив отступа текста в столбцах по оси X
   int text_x_offset[COLUMNS2_TOTAL];
   ::ArrayInitialize(text_x_offset,7);
//--- Массив выравнивания текста в столбцах
   ENUM_ALIGN_MODE align[COLUMNS2_TOTAL];
   ::ArrayInitialize(align,ALIGN_LEFT);
   align[0]=ALIGN_RIGHT;
//--- Свойства
   m_table_param.XSize(197);
   m_table_param.YSize(62);
   m_table_param.CellYSize(20);
   m_table_param.TableSize(COLUMNS2_TOTAL,ROWS2_TOTAL);
   m_table_param.TextAlign(align);
   m_table_param.ColumnsWidth(width);
   m_table_param.TextXOffset(text_x_offset);
   m_table_param.LabelXGap(5);
   m_table_param.LabelYGap(4);
   m_table_param.ShowHeaders(true);
   m_table_param.IsSortMode(false);
   m_table_param.LightsHover(false);
   m_table_param.SelectableRow(false);
   m_table_param.IsWithoutDeselect(false);
   m_table_param.ColumnResizeMode(false);
   m_table_param.IsZebraFormatRows(clrWhiteSmoke);
   m_table_param.IsDisabledScrolls(false);
   m_table_param.AutoYResizeMode(true);
   m_table_param.AutoYResizeBottomOffset(24);
//--- Установим названия заголовков
   m_table_param.SetHeaderText(0,"Description");
   m_table_param.SetHeaderText(1,"Value");
//--- Создадим элемент управления
   if(!m_table_param.CreateTable(x_gap,y_gap))
      return(false);
//--- Добавим объект в общий массив групп объектов
   CWndContainer::AddToElementsArray(0,m_table_param);
   return(true);
  }
//+------------------------------------------------------------------+
//| Создаёт график 1                                                 |
//+------------------------------------------------------------------+
bool CProgram::CreateGraph1(const int x_gap,const int y_gap)
  {
//--- Сохраним указатель на главный элемент
   m_graph1.MainPointer(m_window1);
//--- Свойства
   m_graph1.AutoXResizeMode(true);
   m_graph1.AutoYResizeMode(true);
   m_graph1.AutoXResizeRightOffset(1);
   m_graph1.AutoYResizeBottomOffset(160);
//--- Создание элемента
   if(!m_graph1.CreateGraph(x_gap,y_gap))
      return(false);
//--- Свойства графика
   CGraphic *graph=m_graph1.GetGraphicPointer();
   graph.BackgroundMainSize(16);
   graph.BackgroundMain("Optimization results");
   graph.BackgroundColor(::ColorToARGB(clrWhite));
   graph.IndentLeft(-15);
   graph.IndentRight(-5);
   graph.IndentUp(0);
   graph.IndentDown(-20);
//--- Свойства X-оси
   CAxis *x_axis=graph.XAxis();
   x_axis.AutoScale(false);
   x_axis.Min(0);
   x_axis.Max(1);
   x_axis.MaxGrace(0);
   x_axis.MinGrace(0);
   x_axis.NameSize(14);
   x_axis.DefaultStep(0.5);
   x_axis.Type(AXIS_TYPE_CUSTOM);
   x_axis.ValuesFunctionFormat(ValueFormat);
//--- Свойства Y-оси
   CAxis *y_axis=graph.YAxis();
   y_axis.MaxLabels(10);
   y_axis.ValuesWidth(60);
   y_axis.Type(AXIS_TYPE_CUSTOM);
   y_axis.ValuesFunctionFormat(ValueFormat);
//--- Зарезервировать серии
   double data[];
   int curves_total=(int)m_curves_total.GetValue();
   m_frame_gen.SetCurvesTotal(curves_total);
   for(int i=0; i<curves_total; i++)
      graph.CurveAdd(data,CURVE_LINES,"");
//--- Нарисовать данные на графике
   graph.CurvePlotAll();
//--- Добавим указатель на элемент в базу
   CWndContainer::AddToElementsArray(0,m_graph1);
   return(true);
  }
//+------------------------------------------------------------------+
//| Создаёт график 2                                                 |
//+------------------------------------------------------------------+
bool CProgram::CreateGraph2(const int x_gap,const int y_gap)
  {
//--- Сохраним указатель на главный элемент
   m_graph2.MainPointer(m_window1);
//--- Свойства
   m_graph2.AutoXResizeMode(true);
   m_graph2.AutoYResizeMode(true);
   m_graph2.AutoXResizeRightOffset(1);
   m_graph2.AutoYResizeBottomOffset(24);
   m_graph2.AnchorBottomWindowSide(true);
//--- Создание элемента
   if(!m_graph2.CreateGraph(x_gap,y_gap))
      return(false);
//--- Свойства графика
   CGraphic *graph=m_graph2.GetGraphicPointer();
   graph.BackgroundColor(::ColorToARGB(clrWhite));
   graph.IndentLeft(-15);
   graph.IndentRight(-5);
   graph.IndentUp(0);
   graph.IndentDown(-20);
//---
   CAxis *x_axis=graph.XAxis();
   x_axis.AutoScale(false);
   x_axis.Min(0);
   x_axis.Max(1);
   x_axis.MaxGrace(0);
   x_axis.MinGrace(0);
   x_axis.NameSize(14);
   x_axis.DefaultStep(0.5);
   x_axis.Type(AXIS_TYPE_CUSTOM);
   x_axis.ValuesFunctionFormat(ValueFormat);
//---
   CAxis *y_axis=graph.YAxis();
   y_axis.MaxLabels(5);
   y_axis.ValuesWidth(60);
   y_axis.Type(AXIS_TYPE_CUSTOM);
   y_axis.ValuesFunctionFormat(ValueFormat);
//--- Создать кривые
   double data[1];
//--- Зарезервировать серии
   graph.CurveAdd(data,::ColorToARGB(clrLimeGreen),CURVE_POINTS,"");
   graph.CurveAdd(data,::ColorToARGB(clrRed),CURVE_POINTS,"");
//---
   int points_size=2;
   CCurve *curve=graph.CurveGetByIndex(0);
   curve.PointsFill(true);
   curve.PointsSize(points_size);
   curve.PointsType(POINT_SQUARE);
//---
   curve=graph.CurveGetByIndex(1);
   curve.PointsFill(true);
   curve.PointsSize(points_size);
   curve.PointsType(POINT_SQUARE);
//--- Нарисовать данные на графике
   graph.CurvePlotAll();
//--- Добавим указатель на элемент в базу
   CWndContainer::AddToElementsArray(0,m_graph2);
   return(true);
  }
//+------------------------------------------------------------------+

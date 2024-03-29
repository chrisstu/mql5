#property copyright   "2009, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Bollinger Bands"
#property description "------------------------- 2015 SearchSurf's Version 3.2 (RmDj)"
#include <MovingAverages.mqh>
//---
#property indicator_chart_window
#property indicator_buffers 6                          
#property indicator_plots   5                           
#property indicator_type1   DRAW_LINE
#property indicator_color1  LightSeaGreen
#property indicator_type2   DRAW_LINE
#property indicator_color2  LightSeaGreen
#property indicator_type3   DRAW_LINE
#property indicator_color3  LightSeaGreen
#property indicator_type4   DRAW_ARROW                   
#property indicator_color4  Blue                         
#property indicator_type5   DRAW_ARROW                    
#property indicator_color5  Red                           
#property indicator_label1  "Bands middle"
#property indicator_label2  "Bands upper"
#property indicator_label3  "Bands lower"
//--- input parametrs
input int     InpBandsPeriod=20;       // Period
input int     InpBandsShift=0;         // Shift
input double  InpBandsDeviations=2;  // Deviation
input bool    OuterBandArrow=true;     // Enable Arrow Indicator 
input bool    BandLineOnly=false;      // Arrow on BandLine Only
//--- global variables
int           ExtBandsPeriod,ExtBandsShift;
double        ExtBandsDeviations;
int           ExtPlotBegin=0;
//---- indicator buffer
double        ExtMLBuffer[];
double        ExtTLBuffer[];
double        ExtBLBuffer[];
double        ExtUpBuffer[];
double        ExtLoBuffer[];
double        ExtStdDevBuffer[];
//--- Other Variable;
double        UpperBOL;
double        LowerBOL;
double        MidBOL;
string        InSeconds; // The string
string        sec[]; // result
ushort        usec; // code of seperator
long          seconds;
bool          play=1;
long          delay_sec;
double        notification=true;  //mail condition  (true = Allow / false = Don't queue);
int total;
int lastEpochTimeOfAlert;
double factorLimit=1.5;
double maxFactor;
int m_nLastBars;
int db;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input values
   if(InpBandsPeriod<2)
     {
      ExtBandsPeriod=20;
      printf("Incorrect value for input variable InpBandsPeriod=%d. Indicator will use value=%d for calculations.",InpBandsPeriod,ExtBandsPeriod);
     }
   else ExtBandsPeriod=InpBandsPeriod;
   if(InpBandsShift<0)
     {
      ExtBandsShift=0;
      printf("Incorrect value for input variable InpBandsShift=%d. Indicator will use value=%d for calculations.",InpBandsShift,ExtBandsShift);
     }
   else
      ExtBandsShift=InpBandsShift;
   if(InpBandsDeviations==0.0)
     {
      ExtBandsDeviations=2.0;
      printf("Incorrect value for input variable InpBandsDeviations=%f. Indicator will use value=%f for calculations.",InpBandsDeviations,ExtBandsDeviations);
     }
   else ExtBandsDeviations=InpBandsDeviations;
//--- define buffers
   SetIndexBuffer(0,ExtMLBuffer);
   SetIndexBuffer(1,ExtTLBuffer);
   SetIndexBuffer(2,ExtBLBuffer);
   SetIndexBuffer(3,ExtUpBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtLoBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,ExtStdDevBuffer,INDICATOR_CALCULATIONS);
   
//--- set index labels
   PlotIndexSetString(0,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Middle");
   PlotIndexSetString(1,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Upper");
   PlotIndexSetString(2,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Lower");
//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"Bollinger Bands");
//--- indexes draw begin settings
   ExtPlotBegin=ExtBandsPeriod-1;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   PlotIndexSetInteger(3,PLOT_ARROW,217);
   PlotIndexSetInteger(4,PLOT_ARROW,218);
//--- indexes shift settings
   PlotIndexSetInteger(0,PLOT_SHIFT,ExtBandsShift);
   PlotIndexSetInteger(1,PLOT_SHIFT,ExtBandsShift);
   PlotIndexSetInteger(2,PLOT_SHIFT,ExtBandsShift);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,ExtBandsShift);
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,ExtBandsShift);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   string filename = "MT5Alerts.db";
   
   db=DatabaseOpen(filename, DATABASE_OPEN_READWRITE);
   if(db==INVALID_HANDLE)
     {
      Alert("DB: ", filename, " open failed with code ", GetLastError());
      return;
     }
//---- OnInit done
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Alert("Closing DB");
   DatabaseClose(db);
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//--- variables
   int pos;
   int i;
   string Ptrimmed;
   double the_price;
   bool isNewCandle = IsNewCandle();
//--- indexes draw begin settings, when we've recieved previous begin
   if(ExtPlotBegin!=ExtBandsPeriod+begin)
     {
      ExtPlotBegin=ExtBandsPeriod+begin;
      //PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPlotBegin);
      //PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtPlotBegin);
      //PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ExtPlotBegin);
     }
//--- check for bars count
   if(rates_total<ExtPlotBegin)
      return(0);
//--- starting calculation
   if(prev_calculated>1) pos=prev_calculated-1;
   else pos=0;
//--- This serves the calculated bars candle details.              
   MqlRates crates[];
   if(CopyRates(_Symbol,_Period,0,rates_total,crates)<0)
     {
      Alert("Unable to get total rates bars --- ",GetLastError());
      return(rates_total);
     }

//--- main cycle   
   for(i=pos;i<rates_total && !IsStopped();i++)
     {
      //--- middle line
      ExtMLBuffer[i]=SimpleMA(i,ExtBandsPeriod,price);
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i]=StdDev_Func(i,price,ExtMLBuffer,ExtBandsPeriod);
      //--- upper line
      ExtTLBuffer[i]=ExtMLBuffer[i]+ExtBandsDeviations*ExtStdDevBuffer[i];
      //--- lower line
      ExtBLBuffer[i]=ExtMLBuffer[i]-ExtBandsDeviations*ExtStdDevBuffer[i];
      //--- Will copy BOL band value of last bar:     
      MidBOL=ExtMLBuffer[i];
      LowerBOL = ExtBLBuffer[i];
      UpperBOL = ExtTLBuffer[i];
      ExtUpBuffer[i]=0;
      ExtLoBuffer[i]=0;
      //--- Places arrow indicator whenever price passed over outer bands******          
      if(OuterBandArrow)
        {
         if(BandLineOnly)
           {
            if(crates[i].low<UpperBOL && crates[i].high>UpperBOL) ExtUpBuffer[i]=UpperBOL;
            else ExtUpBuffer[i]=0;
            if(crates[i].high>LowerBOL && crates[i].low<LowerBOL) ExtLoBuffer[i]=LowerBOL;
            else ExtLoBuffer[i]=0;
           }
         else
           {
            if((crates[i].low<UpperBOL && crates[i].high>UpperBOL) || 
               (crates[i].low>UpperBOL && crates[i].high>UpperBOL)) ExtUpBuffer[i]=UpperBOL;
            else ExtUpBuffer[i]=0;
            if((crates[i].high>LowerBOL && crates[i].low<LowerBOL) || 
               (crates[i].high<LowerBOL && crates[i].low<LowerBOL)) ExtLoBuffer[i]=LowerBOL;
            else ExtLoBuffer[i]=0;
           }
        }
     }

//--- To get the latest close price:   (high,low,close,open,real volume,spread,tick volume,time)    
   MqlRates mrates[];  // for storing the price,volume,spread 
   ArraySetAsSeries(mrates,true);  // Records data in series format.
   if(CopyRates(_Symbol,_Period,0,3,mrates)<0) //CopyRates(Chart Current Symbol, Chart Current Period,start position, count, rates array)
     {
      Alert("Unable to get rates of 3 bars --- ",GetLastError());
      return(rates_total);
     }
//---
   the_price=mrates[0].close;
   if((mrates[0].close>UpperBOL || mrates[0].close<LowerBOL))
   {
      usec=StringGetCharacter("_",0);
      StringSplit(EnumToString(_Period),usec,sec);
      Ptrimmed=sec[1];
      string message = "";
      double factor=0;
      if(mrates[0].close>UpperBOL)
      {
         factor = (the_price-MidBOL)/(UpperBOL-MidBOL);
         message = _Symbol+
         " detected ABOVE Bollinger's Upper Band: "+
         DoubleToString(the_price,8)+
         " Factor = "+
         DoubleToString(factor,2);
      }
      else
      {
         factor = (LowerBOL-the_price)/(MidBOL-LowerBOL);
         message = _Symbol+
         " detected BELOW Bollinger's Lower Band: "+
         DoubleToString(the_price,8)+
         " Factor = "+
         DoubleToString(factor,2);
      }
      if ((notification && UnixTimeStamp()>lastEpochTimeOfAlert+30) ||
          (factor>maxFactor*1.1 && factor>factorLimit && lastEpochTimeOfAlert+5))
      {
         notification = false;
         Alert(message);
         datetime dt = TimeCurrent();
         string dbInsertString = StringFormat("INSERT INTO Alert (Time, Security, TimeFrame, Value, Factor) VALUES (%d, '%s', '%s', %g, %g);",
                                              (int)TimeCurrent(), _Symbol, EnumToString(_Period), the_price, factor);
         int prepareHandle = DatabasePrepare(db, dbInsertString);
         if (prepareHandle == INVALID_HANDLE)
         {
            Alert("DB: prepare failed for ", dbInsertString, " ", GetLastError());
         }
         DatabaseRead(prepareHandle);       
         lastEpochTimeOfAlert = UnixTimeStamp();
      }
      if (factor>maxFactor)
         maxFactor=factor;
   }
   else
   {
      notification=true;
      if (isNewCandle)
      {
         maxFactor=0;
      }
   }
   //---- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(int position,const double &price[],const double &MAprice[],int period)
  {
//--- variables
   double StdDev_dTmp=0.0;
//--- check for position
   if(position<period) return(StdDev_dTmp);
//--- calcualte StdDev
   for(int i=0;i<period;i++) StdDev_dTmp+=MathPow(price[position-i]-MAprice[position],2);
   StdDev_dTmp=MathSqrt(StdDev_dTmp/period);
//--- return calculated value
   return(StdDev_dTmp);
  }
//+------------------------------------------------------------------+

  
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   //---
   total++;
   if (total==1)
   {
   UnixTimeStamp();
   //SendNotification("ping");
   //Alert("ping");
   }
  }

int UnixTimeStamp()
{
   string unixTimestamp = (TimeCurrent()-0);
   int trk=StringToInteger(unixTimestamp);
   return trk;
}

bool IsNewCandle()
{
bool m_bNewBar;
int nBars=Bars(Symbol(),PERIOD_CURRENT);
if(m_nLastBars!=nBars)
  {
   m_nLastBars=nBars;
   m_bNewBar=true;
  }
else
  {
   m_bNewBar=false;
  }
  return m_bNewBar;
 }
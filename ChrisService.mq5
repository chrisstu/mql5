//+------------------------------------------------------------------+
//|                                                 ChrisService.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Service program start function                                   |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   int i=0;
   int handle = FileOpen("chrislog.txt", FILE_READ|FILE_WRITE|FILE_TXT);
   FileSeek(handle, 0, SEEK_END);
   do
   {
      Print("PING");
      FileWrite(handle, "PING");
      i++;
      Sleep(1);
   }
   while (i<100);
         FileClose(handle);
  }

//+------------------------------------------------------------------+

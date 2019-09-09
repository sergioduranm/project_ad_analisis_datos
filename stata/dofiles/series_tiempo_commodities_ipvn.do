** PROJECT: ANALISIS DE DATOS
** PROGRAM: series_tiempo_commodities_ipvn.do
** PROGRAM TASK: SERIES DE TIEMPO
** AUTHOR: RODRIGO TABORDA
** DATE CREATEC: 02/02/2017
** DATE REVISION 1: 03/07/2019
** DATE REVISION #:

********************************************************************;
** #0
********************************************************************;

** PROGRAM SETUP

    pause on
    #delimit ;

*** #0.1 ** SET PATH FOR READING/SAVING DATA;
*
**    cd ../../;
*
**********************************************************************;
**** #0 ** TRATAMIENTO DE FECHA;
**********************************************************************;
*
*    display mdy(1,1,1960);
*    display hms(0,0,1); /*1 segundo = 1 milisegundo*/;
*    display dow(mdy(11,1,2000)); /*0 = Sun, 1 = Mon, 2 = Tues, 3 = Wed, 4 = Thurs, 5 = Fri, 6 = Saturday*/;
*    display doy(mdy(11,1,2000)); /*dia del año*/;
*
**********************************************************************;
**** #10 ** IMF;
**********************************************************************;
**
**** #10.2 ** READ, ORGANIZE DATA;
**
**** #10.2.1 ** IMPORT DATA;
*
*    import delimited
*        http://rodrigotaborda.com/ad/data/commodities/commodities_20190426.csv
*        ,
*        delimiter(";")
*        clear
*        ;
*
**** #10.2.2 ** ORGANIZE DATE VARIABLE;
*
*    generate date_num = monthly(date,"YM");
*    format %tm date_num;
*
**** #10.2.3 ** DECLARE TIME SERIES FORMAT;
*
*    tsset date_num;
*sss
**** #10.2.4 ** EXTRACT DATE VARIABLES;
*
*    generate date_date = dofm(date_num);
*        format date_date %d;
*    generate date_day = day(date_date);
*    generate date_week = week(date_date);
*    generate date_month = month(date_date);
*    generate date_quarter = quarter(date_date);
*    generate date_semester = halfyear(date_date);
*    generate date_year = year(date_date);
*
**** #10.2.5 ** LAG, FORWARD, DIFFERENCE;
*
*    generate pcoco_l1 = l.pcoco;
*    generate pcoco_l2 = l2.pcoco;
*    generate pcoco_f1 = f.pcoco;
*    generate pcoco_f2 = f2.pcoco;
*    generate pcoco_d1 = d.pcoco;
*    generate pcoco_d2 = d2.pcoco;
*    generate pcoco_g12 = d12.pcoco / l12.pcoco;
*
**** #10.3 ** GRAPHS;
*
*    tsline pcoco;
*    tsline pcoco if tin(1990m1,1995m12);
*
**** #10.4 ** SMOOTHING;
*
*    tssmooth nl pcoco_sm3 = pcoco, smoother(3);
*        tsline pcoco pcoco_sm3;
*    tssmooth nl pcoco_sm9 = pcoco, smoother(9);
*        tsline pcoco pcoco_sm9;

********************************************************************;
** #20 ** IPVN;
********************************************************************;

*** #20.2 ** READ, ORGANIZE DATA;

*** #20.2.1 ** IMPORT DATA;

    import delimited
        http://rodrigotaborda.com/ad/data/ipvn/ipvn_am_201904.csv
        ,
        delimiter(";")
        clear
        ;

    label var total "Total nacional";

*** #10.2.2 ** ORGANIZE DATE VARIABLE;

    gen date = yq(year,q);
    format date %tq;

*** #10.2.3 ** DECLARE TIME SERIES FORMAT & ADD TIME;

    tsset date;
    tsappend, add(12);
sss
*** #10.2.4 ** GROWTH RATES;

    gen total_gr_month = (total/l.total) - 1;
    gen total_gr_year = (total/l4.total) - 1;

    gen bogotasoacha_gr_month = (bogotasoacha/l.bogotasoacha) - 1;
    gen bogotasoacha_gr_year = (bogotasoacha/l4.bogotasoacha) - 1;

* #10.2.5 ** ANÁLISIS UNIVARIADO;

* #10.2.5.1 ** BOGOTA;

    /*REGRESIÓN AJUSTE TIEMPO*/;
        reg bogotasoacha_gr_year date;
        twoway (tsline bogotasoacha_gr_year) (lfit bogotasoacha_gr_year date);

    /*FUNCIÓN DE AUTOCORRELACIÓN */;
        ac bogotasoacha_gr_year;

    /*FUNCIÓN DE AUTOCORRELACIÓN PARCIAL*/;
        pac bogotasoacha_gr_year;

    /*REGRESIÓN ARIMA*/;
        arima bogotasoacha_gr_year date, arima(3,0,0);
            predict bogotasoacha_arima300t_res, residuals;
            label var bogotasoacha_arima300t_res "Bogotá ARIMA(3,0,0) + T";
            estat ic;

        arima bogotasoacha_gr_year date, arima(2,0,0);
            predict bogotasoacha_arima200t_res, residuals;
            label var bogotasoacha_arima200t_res "Bogotá ARIMA(2,0,0) + T";
            estat ic;

        arima bogotasoacha_gr_year, arima(2,0,0);
            predict bogotasoacha_arima200_res, residuals;
            label var bogotasoacha_arima200_res "Bogotá ARIMA(2,0,0)";
            estat ic;

        arima bogotasoacha_gr_year date, arima(1,0,0);
            predict bogotasoacha_arima100t_res, residuals;
            label var bogotasoacha_arima100t_res "Bogotá ARIMA(1,0,0) + T";
            estat ic;

        arima bogotasoacha_gr_year, arima(1,0,0);
            predict bogotasoacha_arima100_res, residuals;
            label var bogotasoacha_arima100_res "Bogotá ARIMA(1,0,0)";
            estat ic;

    /*REGRESIÓN ARIMA MODELO PREFERIDO Y PREDICCIÓN*/;
        arima bogotasoacha_gr_year if tin(1997q1,2016q4), arima(2,0,0);
            predict bogotasoacha_arima200t_xb, y;
            label var bogotasoacha_arima200t_xb "Bogotá prediccion";

            predict bogotasoacha_arima200t_fcast, dynamic(tq(2018q1));
            label var bogotasoacha_arima200t_fcast "Bogotá pronostico";

        tsline bogotasoacha_gr_year
               bogotasoacha_arima200t_xb
               bogotasoacha_arima200t_fcast
               ,
               ttick(1997q1(4)2021q4, tpos(out))
               tlabel(1997q1(8)2021q4, format(%tqCCYY) angle(90))
               ;

**** #90.9.9 ** GOOD BYE;
*
*    clear;
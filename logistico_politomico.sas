/* ===================================================================
   FASE 1: PREPARAZIONE E IMPORTAZIONE DATI
   =================================================================== */

/* 0. DEFINIZIONE FORMATI (Cruciale per l'ordine Farm < ... < Prof) */
proc format;
    value $occ_ord
    'farm'    = '1. Farm'
    'unskill' = '2. Unskill'
    'skill'   = '3. Skill'
    'prof'    = '4. Prof';
run;

/* 1. DATA STEP: Importazione */
data mobility;
    length fatherOccup $10 sonOccup $10 black $3 nonintact $3;
    input cod fatherOccup $ sonOccup $ black $ nonintact $ count;
    
    /* Applichiamo i formati per garantire l'ordine gerarchico nei grafici e modelli */
    format fatherOccup sonOccup $occ_ord.;
    
    datalines;
1            farm            farm      no          no     592  
2            farm            farm      no         yes      55  
3            farm            farm     yes          no      41  
4            farm            farm     yes         yes      15  
5            farm        unskill      no          no    1005  
6            farm        unskill      no         yes     134  
7            farm        unskill     yes          no     254  
8            farm        unskill     yes         yes      85  
9            farm          skill      no          no    1095  
10            farm          skill      no         yes     158  
11            farm          skill     yes          no     133  
12            farm          skill     yes         yes      44  
13            farm         prof      no          no     943  
14            farm         prof      no         yes      89  
15            farm         prof     yes          no      59  
16            farm         prof     yes         yes      18  
17        unskill            farm      no          no      45  
18        unskill            farm      no         yes       6  
19        unskill            farm     yes          no       5  
20        unskill            farm     yes         yes       2  
21        unskill        unskill      no          no    1289  
22        unskill        unskill      no         yes     180  
23        unskill        unskill     yes          no     227  
24        unskill        unskill     yes         yes      60  
25        unskill          skill      no          no    1284  
26        unskill          skill      no         yes     197  
27        unskill          skill     yes          no     115  
28        unskill          skill     yes         yes      34  
29        unskill         prof      no          no    1255  
30        unskill         prof      no         yes     185  
31        unskill         prof     yes          no      99  
32        unskill         prof     yes         yes      29  
33          skill            farm      no          no      50  
34          skill            farm      no         yes      10  
35          skill            farm     yes          no       1  
36          skill            farm     yes         yes       2  
37          skill        unskill      no          no    1073  
38          skill        unskill      no         yes     176  
39          skill        unskill     yes          no     102  
40          skill        unskill     yes         yes     102  
41          skill          skill      no          no    1678  
42          skill          skill      no         yes     244  
43          skill          skill     yes          no      69  
44          skill          skill     yes         yes      77  
45          skill         prof      no          no    2074  
46          skill         prof      no         yes     284  
47          skill         prof     yes          no      76  
48          skill         prof     yes         yes      49  
49         prof            farm      no          no      49  
50         prof            farm      no         yes      11  
51         prof            farm     yes          no       1  
52         prof        unskill      no          no     604  
53         prof        unskill      no         yes      97  
54         prof        unskill     yes          no      34  
55         prof        unskill     yes         yes      14  
56         prof          skill      no          no    1001  
57         prof          skill      no         yes     146  
58         prof          skill     yes          no      26  
59         prof          skill     yes         yes      10  
60         prof         prof      no          no    2927  
61         prof         prof      no         yes     317  
62         prof         prof     yes          no      52  
63         prof         prof     yes         yes      19  
;
run;

/* ===================================================================
   FASE 2: ANALISI ESPLORATIVA (EDA)
   =================================================================== */

/* 2. PROC FREQ: Matrice di Mobilità (Padre vs Figlio) */
/* Questa tabella mostra la distribuzione congiunta delle classi */
proc freq data=mobility order=formatted; /* Usa l'ordine definito nel format */
    weight count; 
    tables fatherOccup * sonOccup / 
           chisq 
           measures 
           nocol nopercent 
           plots=mosaicplot(color=stdres); /* Mosaic Plot con residui standardizzati */
run;

/* 3. PROC SGPANEL: Distribuzione Condizionata */
/* Visualizziamo come cambia la distribuzione del Figlio in base al Padre e alla Razza */
proc sgpanel data=mobility;
    panelby fatherOccup / layout=columnlattice novarname; /* Un pannello per ogni classe paterna */
    
    /* Istogramma pesato */
    vbar sonOccup / 
        freq=count 
        group=black 
        groupdisplay=cluster 
        transparency=0.2;
        
    rowaxis label="Frequenza Assoluta" grid;
    colaxis label="Occupazione Figlio (Y)";
run;

/* ===================================================================
   ANALISI ESPLORATIVA DELLA VARIABILE RISPOSTA (Y = sonOccup)
   =================================================================== */

/* 1. DEFINIZIONE FORMATO ORDINALE
   Fondamentale per forzare l'ordine logico (Farm < Unskill < Skill < Prof)
   al posto dell'ordine alfabetico di default. */
proc format;
    value $occ_ord
    'farm'    = '1. Farm'
    'unskill' = '2. Unskill'
    'skill'   = '3. Skill'
    'prof'    = '4. Prof';
run;

/* 2. TABELLA DI FREQUENZA E DISTRIBUZIONE CUMULATA 
   Obiettivo: Visualizzare le probabilità marginali P(Y=j) e 
   le probabilità cumulate P(Y<=j) che sono alla base del modello. */
title "Distribuzione Marginale della Variabile Risposta (sonOccup)";
title2 "Dati Raggruppati (N totale atteso = 21.107)";

proc freq data=mobility order=formatted;
    /* WEIGHT è obbligatorio perché i dati sono raggruppati nella variabile 'count' */
    weight count; 
    
    /* Applichiamo il formato per l'ordinamento corretto */
    format sonOccup $occ_ord.;
    
    /* Richiediamo:
       - nocol nopercent: per pulizia (qui guardiamo solo la marginale)
       - plots=freqplot: istogramma semplice
    */
    tables sonOccup / 
           plots=freqplot(type=bar scale=percent) 
           out=marginal_dist; /* Salviamo i risultati per eventuali grafici custom */
run;

/* 3. VISUALIZZAZIONE DELLE PROBABILITÀ CUMULATE (Step-Plot)
   Questo grafico aiuta a visualizzare le "soglie" (Cut-points) che
   il modello andrà a stimare (alfa_1, alfa_2, alfa_3). */
data marginal_dist;
    set marginal_dist;
    /* Calcolo manuale della cumulata per il grafico (se non generato da proc freq) */
    retain cum_percent 0;
    cum_percent + percent;
run;

title "Funzione di Ripartizione Empirica" ;
proc sgplot data=marginal_dist;
    /* Disegna la curva a gradini delle frequenze cumulate */
    step x=sonOccup y=cum_percent / 
         lineattrs=(color=CX4c72b0 thickness=2)
         markers markerattrs=(symbol=circlefilled);
         
    /* Linee di riferimento per capire dove cadono le soglie (es. mediana) */
    refline 50 / axis=y label="Mediana (50%)" lineattrs=(pattern=dash);
    
    yaxis label="Percentuale Cumulata P(Y <= j)" grid values=(0 to 100 by 10);
    xaxis label="Classe Occupazionale (Y)";
run;



/* ===================================================================
   FASE 3: MODELLAZIONE GERARCHICA (CUMULATIVE LOGIT)
   =================================================================== */
/* Nota: descending modella la probabilità di avere uno status PIÙ ALTO (Y >= j) */

/* --- STEP 1: MODELLO NULLO (Benchmark) --- */
/* Stima solo le 3 intercette (cut-points) che definiscono le probabilità di base */
title "Step 1: Modello Nullo (Solo Intercette)";
proc logistic data=mobility descending;
    freq count;
    model sonOccup = ; 
run;

/* --- STEP 2: MODELLO MONOVARIATO (Solo Origine Sociale) --- */
/* Valuta l'impatto della classe del padre sulle probabilità cumulative del figlio */
title "Step 2: Modello Mobilità Pura (Solo Occupazione Padre)";
proc logistic data=mobility descending;
    freq count;
    class fatherOccup (ref='1. Farm') / param=ref;
    
    model sonOccup = fatherOccup / 
          link= glogit      /* Specifica esplicita: Cumulative Logit */
          rsquare;
run;

/* --- STEP 3: MODELLO ADDITIVO (Main Effects) --- */
/* Aggiunge Razza e Famiglia assumendo effetti costanti (Odds Proporzionali) */
title "Step 3: Modello Additivo (Padre + Razza + Famiglia)";
proc logistic data=mobility descending;
    freq count;
    class fatherOccup (ref='1. Farm') 
          black       (ref='no') 
          nonintact   (ref='no') / param=ref;
    
    model sonOccup = fatherOccup black nonintact / 
          link= glogit
          rsquare 
          expb             /* Mostra gli Odds Ratio */
          clodds=pl;       /* Intervalli di confidenza Profile Likelihood */
run;

/*MODELLO SATURO (M_s) */
title "Modello Saturo / Completo (Interazione a 3 vie)";
proc logistic data=mobility descending;
    freq count;
    
    /* Definiamo i riferimenti */
    class fatherOccup (ref='1. Farm') 
          black       (ref='no') 
          nonintact   (ref='no') / param=ref;

    /* SINTASSI CHIAVE: A | B | C genera:
       A, B, C (Effetti principali)
       A*B, A*C, B*C (Interazioni doppie)
       A*B*C (Interazione tripla) */
    model sonOccup = fatherOccup | black | nonintact / 
          link= glogit
          aggregate scale=none /* Fondamentale per vedere la Devianza corretta */
          rsquare;
run;

/* --- STEP 4: MODELLO INTERATTIVO (Testing the Theory) --- */
/* Verifica se lo svantaggio razziale cambia in base alla classe di partenza.
   Include anche il test per l'assunzione di Odds Proporzionali. */
title "Step 4: Modello con Interazione (Razza * Classe Padre)";
proc logistic data=mobility descending;
    freq count;
    class fatherOccup (ref='1. Farm') 
          black       (ref='no') 
          nonintact   (ref='no') / param=ref;
    
    /* Sintassi con barra verticale '|' include effetti principali e interazione */
    model sonOccup = nonintact black | fatherOccup / 
          link= glogit
          scale=none       /* Nessuna correzione per sovradispersione a priori */
          aggregate        /* Necessario per i test di bontà di adattamento su dati raggruppati */
          lackfit          /* Test di devianza residua */
          rsquare
          expb 
          clodds=pl;

    /* LSMEANS per interpretare l'interazione complessa */
    /* Calcola la probabilità media di superare una certa soglia per ogni gruppo */
    lsmeans black * fatherOccup / ilink diff cl;
    
    /* Salviamo i risultati per il report */
    ods output ParameterEstimates=ParamEst;
    ods output OddsRatios=ORs;
run;


title "Selezione Ottimizzata su AIC (High-Performance)";
proc hplogistic data=mobility;
    freq count;
    class fatherOccup (ref='1. Farm') 
          black       (ref='no') 
          nonintact   (ref='no') / param=ref;

    model sonOccup(descending) = fatherOccup|black|nonintact / 
          link=glogit;

    /* Qui comandiamo l'algoritmo usando l'AIC */
    selection method=stepwise(select=BIC choose=BIC) hierarchy=single;
run;


/* ===================================================================
   DIAGNOSTICA: VERIFICA ASSUNZIONE PROPORTIONAL ODDS
   =================================================================== */

/* --- METODO 1: Il Test Formale (Score Test) --- */
/* SAS calcola automaticamente questo test quando usi link=clogit su risposta ordinale.
   Se il p-value è < 0.05, l'assunzione è statisticamente rifiutata. */

title "1. Test Formale (Score Test per Proportional Odds)";
proc logistic data=mobility descending;
    freq count; /* Fondamentale per dati raggruppati */
    
    /* Definiamo i riferimenti (Corner Point) */
    class fatherOccup(ref='1. Farm') black(ref='no') nonintact(ref='no') / param=ref;
    
    /* Il modello cumulativo standard */
    model sonOccup = fatherOccup black nonintact / link=clogit scale=none aggregate;
run;

/* ===================================================================
   SELEZIONE ESAUSTIVA DEL MODELLO (CORRETTA)
   =================================================================== */

%macro FitModel(name, predictors);
    proc logistic data=mobility;
        freq count;
        class fatherOccup(ref='1. Farm') black(ref='no') nonintact(ref='no') / param=ref;
        model sonOccup(ref='1. Farm') = &predictors / link=glogit;
        ods output FitStatistics=Stats_&name;
    run;

    data Stats_&name;
        length Modello $ 50;
        set Stats_&name;
        if Criterion = 'SC'; /* Seleziona il criterio BIC (SBC in SAS) */
        Modello = "&name";
        
        /* CORREZIONE: Assegnazione corretta della variabile Value */
        /* SAS crea due colonne: InterceptOnly e InterceptAndCovariates */
        /* Prendiamo quella del modello completo. Se manca, prendiamo quella dell'intercetta */
        
        Value = InterceptAndCovariates; 
        if Value = . then Value = InterceptOnly;
        
        keep Modello Value;
    run;
%mend FitModel;

/* --- ESECUZIONE DEI MODELLI --- */

/* M0: Nullo */
%FitModel(M0_Nullo, );

/* M1-M3: Una variabile */
%FitModel(M1_Padre, fatherOccup);
%FitModel(M2_Razza, black);
%FitModel(M3_Famiglia, nonintact);

/* M4-M6: Due variabili */
%FitModel(M4_Padre_Razza, fatherOccup black);
%FitModel(M5_Padre_Fam, fatherOccup nonintact);
%FitModel(M6_Razza_Fam, black nonintact);

/* M7: Additivo Completo */
%FitModel(M7_Additivo, fatherOccup black nonintact);

/* M8: Interattivo */
%FitModel(M8_Interattivo, fatherOccup black nonintact fatherOccup*black);


/* --- CONFRONTO FINALE --- */
data Model_Comparison;
    set Stats_M0_Nullo 
        Stats_M1_Padre Stats_M2_Razza Stats_M3_Famiglia
        Stats_M4_Padre_Razza Stats_M5_Padre_Fam Stats_M6_Razza_Fam
        Stats_M7_Additivo 
        Stats_M8_Interattivo;
run;

proc sort data=Model_Comparison;
    by Value;
run;

title "CLASSIFICA DEFINITIVA DEI MODELLI (BIC Reale)";
proc print data=Model_Comparison noobs;
    var Modello Value;
    format Value 10.2;
run;

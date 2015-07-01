numero_di_oggetti=10;
numero_di_classi=10;
zipf_alpha=1.2;
numero_di_campioni=55000;
seed = 2;
rand('seed',seed);
[richieste_per_classe, richieste_per_oggetto] = ZipfQuantizedRng(numero_di_oggetti,numero_di_classi,numero_di_campioni,zipf_alpha);
richieste_per_oggetto

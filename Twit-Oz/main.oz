functor
import 
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
   Application
   Open
   OS
   Pickle
   Property
   Browser
define
   NumberWord={Pickle.load 'Pickle/NumberWord.ozp'} % à généraliser pour tout système
   DataBase={Pickle.load 'Pickle/DataBase.ozp'} %load Pickle

   %%% Pour ouvrir les fichiers
   class TextFile
      from Open.file Open.text
   end

   proc {Browse Buf}
      {Browser.browse Buf}
   end

   %%% /!\ Fonction testee /!\
   %%% @pre : les threads sont "ready"
   %%% @post: Fonction appellee lorsqu on appuie sur le bouton de prediction
   %%%        Affiche la prediction la plus probable du prochain mot selon les deux derniers mots entres
   %%% @return: Retourne une liste contenant la liste du/des mot(s) le(s) plus probable(s) accompagnee de 
   %%%          la probabilite/frequence la plus elevee. 
   %%%          La valeur de retour doit prendre la forme:
   %%%                  <return_val> := <most_probable_words> '|' <probability/frequence> '|' nil
   %%%                  <most_probable_words> := <atom> '|' <most_probable_words> 
   %%%                                           | nil
   %%%                  <probability/frequence> := <int> | <float>
   proc {Press} %était fun avant mais ca buggait
      {Browse 'On y travaille'}
   end

   %%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
   %%% Les threads de parsing envoient leur resultat au port Port
   proc {LaunchThreads Port N}
      % TODO
      skip
   end

   %%% Ajouter vos fonctions et procédures auxiliaires ici
   proc {Save} %To Save input
      {Browse 'Stop clicking me it is awkward'} 
   end


   %%% Fetch Tweets Folder from CLI Arguments
   %%% See the Makefile for an example of how it is called
   fun {GetSentenceFolder}
      Args = {Application.getArgs record('folder'(single type:string optional:false))}
   in
      Args.'folder'
   end

   proc {NewWin Message Inside Handle Return}
      {{QTk.build Inside} show}
      {Handle set(Message)}
      %{Wait Return}  Return will be bound when the window is closed
   end

   fun {Split Input Track} SearchChar in % lis une entrée bytestring et sépare à chaque espace
      SearchChar={ByteString.strchr Input Track " ".1}
      if SearchChar==false then
         nil % Include the last word
      else
         {ByteString.slice Input Track SearchChar}|{Split Input SearchChar+1}
      end
   end
      
   % Prends un String (pas un byteString) donc utilisable directement en lecture de fichier
   fun {SplitMultiple ArrayString}
      case ArrayString of nil then nil
      [] H|T then {Split {ByteString.make H} 0}|{SplitMultiple T}
      end
   end

   %fun {Split Input Track Acc}
   %   case Input of nil then Acc
   %   [] H|T then
   %      if H==" " then
   %end

   fun {ReadFile File} F Res in
      F={New Open.file init(name:"tweets/"#{String.toAtom File} flags:[read])}
      {F read(list:Res size:all)} % set size to all to read the whole text
      {F close}
      Res
   end

   % Lis un fichier et fais une liste de son contenu
   fun {OpenMultipleFile L}
      case L of nil then nil
      [] H|T then {ReadFile H}|{OpenMultipleFile T}
      end
   end

   fun {Read Content}
      Content
   end

   %Prends en entrée le contenu d'un fichier (un gros string) et retourne le nombre de mot
   fun {CountWords File} Count in
      {List.length {Split {ByteString.make {String.toAtom File}} 0} Count}
      Count+1
   end

   %Prends en entrée une liste de nom de fichier et retourner la somme totale du nombres de mots
   fun {CountAllWords Files}
      case Files of nil then 0
      [] H|T then {CountWords H} + {CountAllWords T}
      end
   end

   %%% Decomnentez moi si besoin
   proc {ListAllFiles L}
      case L of nil then skip
      [] H|T then {Browse {String.toAtom H}} {ListAllFiles T}
      end
   end

   %Word: le mot en byteString à trouver     File: un fichier lu et séparé en byteString
   %Flag: si le mot précédent est bien Word  Acc: contient un Dictionnaire qui est mis à jour 
   proc {TrainingOneWord Word File Flag Acc} Size Retrieve Inc in
      Size=NumberWord

      case File of nil then skip
      [] H|T then
         if Flag then
            Retrieve={Dictionary.condGet Acc {String.toAtom {ByteString.toString H}} 0}
            Inc=1
            {Dictionary.put Acc {String.toAtom {ByteString.toString H}} Retrieve+Inc} %1 needs to be modified just meant for testing
         else
            if {ByteString.toString H}==Word then
               {TrainingOneWord Word T true Acc}
            else
               {TrainingOneWord Word T Flag Acc}
            end
         end
      end
   end

   %Cherche parmis tous les fichiers (liste dans Files) un mot et retourner les probas d'avoir un tel comme second
   proc {TrainingOneWordFiles Word Files Acc} Size NewAcc ByteFiles in
      Size=NumberWord % Nombre de mots, à remplacer par CountAllWords
      
      case Files of nil then 
         %Because Dictionnary is not supported by pickle in Oz
         {Pickle.saveWithHeader {Dictionary.toRecord {String.toAtom Word} Acc} "Pickle/Word/"#Word#".ozp" "Pour "#Word 0}
      [] H|T then 
         {TrainingOneWord Word H false Acc} 
         {TrainingOneWordFiles Word T Acc}
      end
   end

   proc {UpdateDatabase Handle} Test in
      NumberWord={CountAllWords {OpenMultipleFile {OS.getDir {GetSentenceFolder}}}}
      DataBase=0

      {Pickle.saveWithHeader NumberWord "Pickle/NumberWord.ozp" "Nombre mots" 0} %0 à 9 et au + haut au + compressé
      {Pickle.saveWithHeader DataBase "Pickle/DataBase.ozp" "La base de donnée" 0}

      {Handle set(1:"La base de donnée à été mise à jour avec succès!" foreground:green)}
   end

   proc {DisplayDictHelper List Dic}
      case List of nil then skip
      [] H|T then {Browse {Dictionary.get Dic H}} % ajouter concatenation mais incompréhensible et inefficace en Oz
                  {DisplayDictHelper T Dic}
      end
   end

   %Print the key and its value associate with
   proc {DisplayDict Dic}
      {DisplayDictHelper {Dictionary.keys Dic} Dic}
   end

   fun {FindBiggestDictHelper List Dic Biggest Name}
      case List of nil then Name
      [] H|T then
         if {Dictionary.get Dic H} > Biggest then
            {FindBiggestDictHelper T Dic {Dictionary.get Dic H} H}
         else
            {FindBiggestDictHelper T Dic Biggest Name}
         end
      end
   end

   %Find the key with the highest number
   fun {FindBiggestDict Dic}
      {FindBiggestDictHelper {Dictionary.keys Dic} Dic 0 nil}
   end

   fun {GetLast List Acc}
      case List of nil then Acc
      [] H|T then {GetLast T H}
      end
   end

   %Function for pressing the "Result" button in the GUI
   proc {PressSecond InputHandle OutputHandle} InputText Last Dict TempDict TempRes in
      {InputHandle get(1:InputText)}
      Last={GetLast {Split {ByteString.make {String.toAtom InputText}} 0} {ByteString.make "NaN"}} %need to change NaN

      %Check if the Pickle is already existing
      if {List.member {VirtualString.toString {ByteString.toString Last}#".ozp"} {OS.getDir "Pickle/Word"}} then
         TempDict={Pickle.load "Pickle/Word/"#{String.toAtom{ByteString.toString Last}}#".ozp"} 
         Dict={Record.toDictionary TempDict}
      else
         Dict={NewDictionary}
         TempRes={SplitMultiple {OpenMultipleFile {OS.getDir {GetSentenceFolder}}}}
         {TrainingOneWordFiles {ByteString.toString Last} TempRes Dict}
      end

      %Add the true Pickle loading with concatenation
      %create a search inside a tuple
      {OutputHandle set(1:InputText#{FindBiggestDict Dict})}
   end


%%% Procedure principale qui cree la fenetre et appelle les differentes procedures et fonctions
   proc {Main}
      TweetsFolder = {GetSentenceFolder}
      BGColor=c(242 242 242) % couleur fond
      DarkerBGC=c(230 230 230) % couleur de contraste
      Maxsize=maxsize(width:1920 height:1080)
      Minsize=minsize(width:300 height:180)
      Font={QTk.newFont font(family:"Helvetica" size:10 weight:normal slant:roman underline:false overstrike:false)}
      %ICO=bitmap(url:"https://cdn.discordapp.com/attachments/590178963477757972/1092545816339697674/twitozICO.xbm") Faire fonctionner ce truc

      HelpMessage="\n This tool has been designed for the class 'LINFO1104'\n \n The purpose of this tool is to provide completion of tweets based on a dataset (here right and far right public figure)\n \n Simply type in the white box something, click result and get the rest of the tweet in the black box\n \n If you want to save your input type CTRL+S and CTRL+SHIFT+S to save it somewhere else \n  repo: https://github.com/BrieucDallemagne/projet-oz"
      POPUP R
      Desc=td(
      title:"PopUp"
      maxsize:Maxsize
      minsize:Minsize
      background:BGColor
      message(aspect:200
      init:"This is a message widget" 
      handle:POPUP
      return:R
      padx:40
      pady:40
      background:BGColor
      foreground:black
      )
      action:toplevel#close) % quitte le programme quand la fenetre est fermee)

   in
      %% Fonction d'exemple qui liste tous les fichiers
      %% contenus dans le dossier passe en Argument.
      %% Inspirez vous en pour lire le contenu des fichiers
      %% se trouvant dans le dossier
      %%% N'appelez PAS cette fonction lors de la phase de
      %%% soumission !!!
      % {ListAllFiles {OS.getDir TweetsFolder}}

      local NbThreads InputText OutputText Description Window SeparatedWordsStream SeparatedWordsPort Saving GetText ReadFiles TestRes CountTest FeedbackUpdate Another in
      {Property.put print foo(width:1000 depth:1000)}  % for stdout siz

      %Lis les fichiers
      ReadFiles={OpenMultipleFile {OS.getDir TweetsFolder}}
      %Test de la fonction de split les espaces
      %{Browse {String.toAtom {ByteString.toString {Split {ByteString.make {String.toAtom ReadFiles.1}} 0}.2.1}}}

      %TestRes={SplitMultiple ReadFiles}

      %CountTest={CountAllWords ReadFiles}
      %{Browse CountTest}

      %Pickle Test
      %CountTest={NewDictionary}
      %TestRes={SplitMultiple ReadFiles}
      %{TrainingOneWordFiles "the" TestRes CountTest}
      %{Browse {Dictionary.keys CountTest}}
      %{DisplayDict CountTest} Décommenter si on veut voir les valeurs
      %{Browse {FindBiggestDict CountTest}}


      % Creation de l interface graphique
      Description=td(
      title: "Tweet predictor"
      bg:BGColor
      maxsize:Maxsize
      minsize:Minsize

      %iconbitmap:ICO
      lr(glue:nw
      background:DarkerBGC
      menubutton(glue:nw foreground:black highlightcolor:DarkerBGC bg:DarkerBGC text:"File" font:Font width:5
      menu:menu(background:DarkerBGC 
      tearoff:false
      command(text:"Update Database" foreground:black action:proc{$}{UpdateDatabase FeedbackUpdate}end accelerator:"Control-b")
      separator
      command(text:"Save" foreground:black action:Save accelerator:"Control-s")
      command(text:"Save As" foreground:black action:proc{$} {Browse 'Stop clicking me it is really awkward'} end accelerator:"Control-Alt-s") % Ici, on ajoute des boutons pour controler l'application
      separator
      command(text:"Quit" foreground:black action:proc{$}{Application.exit 0} end accelerator:"Control-q")    
      ))
      menubutton(glue:nw foreground:black highlightcolor:DarkerBGC bg:DarkerBGC text:"Help" font:Font width:5
      menu:menu(background:DarkerBGC 
      tearoff:false
      command(text:"Newcommers"  foreground:black action:proc{$} {NewWin HelpMessage Desc POPUP R}end)
      command(text:"About" foreground:black))))
      lr(background:BGColor 
      glue:nw
      text(handle:InputText init:"Type a Tweet" width:50 height:10 background:white foreground:black wrap:word glue:nw) 
      button(text:"Predict" init:"Result" padx:10 foreground:black bg:DarkerBGC width:15 action:proc{$} {PressSecond InputText OutputText} end key:"Return"))
      text(handle:OutputText width:50 height:10 background:black foreground:white glue:nw wrap:word)
      text(init:"Pour mettre à jour la base de donnée, cliquez sur File puis Update Database" font:Font handle:FeedbackUpdate wrap:word padx:5 background:BGColor foreground:black cursor:"X_cursor" width:30 height:10 glue:w relief:{String.toAtom "flat"} action:proc{$}{FeedbackUpdate set(1:"Pour mettre à jour la base de donnée, cliquer sur File" foreground:black)}end)
      action:proc{$}{Application.exit 0} end % quitte le programme quand la fenetre est fermee
      )

      % Creation de la fenetre
      Window={QTk.build Description}
      {Window show}

      {InputText tk(insert 'end' "Loading... Please wait.")}
      %{InputText bind(event:"<Control-s>" action:Press)}  %You can also bind events



      % On lance les threads de lecture et de parsing
      SeparatedWordsPort = {NewPort SeparatedWordsStream}
      NbThreads = 4
      {LaunchThreads SeparatedWordsPort NbThreads}

      {InputText set(1:"")}
   end
end
% Appelle la procedure principale
   {Main}
end
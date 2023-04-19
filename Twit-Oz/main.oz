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
   Extra at 'extra.ozf'
define
   InputText
   OutputText
   InfiniteInput
   NumberWord={Pickle.load 'Pickle/NumberWord.ozp'} % à généraliser pour tout système
   DataBase={Pickle.load 'Pickle/DataBase.ozp'} %load Pickle
   N=4 %set the size of Ngram


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
      {PressNgram InputText OutputText N}
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

   %To create a pop-up window displaying some text
   proc {NewWin Message Inside Handle Return}
      {{QTk.build Inside} show}
      {Handle set(Message)}
      %{Wait Return}  Return will be bound when the window is closed
   end

   %Takes a String and remove all non Ascii Character
   fun {Clean Input}
      case Input of nil then nil
      [] H|T then 
         if {Char.isCntrl H} then
            32|{Clean T}
         else 
            if {Char.isAlNum H} then
               H|{Clean T}
            else
               32|{Clean T}
            end
         end
      end
   end

   %Takes a String, clean and put each word in a list
   fun {Split Input}
         {List.filter {String.tokens {Clean Input} & } fun {$ O} O \= nil end}
   end
   
   fun {SplitMultiple ListInput}
         case ListInput of nil then nil
         [] H|T then {Split H}|{SplitMultiple T}
         end
   end

   %Read a file. File is the name of the file
   fun {ReadFile File} F Res in
      F={New Open.file init(name:"tweets/"#{String.toAtom File} flags:[read])}
      {F read(list:Res size:all)} % set size to all to read the whole text
      {F close}
      Res
   end

   %Read a directory of file (L is a list of name) and make a list of string of a file
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
      {List.length {Split File} Count}
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
            {TrainingOneWord Word T false Acc}
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
         {Pickle.saveWithHeader {Dictionary.toRecord {String.toAtom Word} Acc} "Pickle/Word/"#Word#".ozp" "Pour "#Word 0} %It uses a false compression take 4kb on disk for 24bit
      [] H|T then 
         {TrainingOneWord Word H false Acc} 
         {TrainingOneWordFiles Word T Acc}
      end
   end

   %Use {ClusterMaker}
   fun {SubCluster Input Start Num} Res in
      if {List.length Input} < Num then
         {SubCluster {List.append {ByteString.make 'EMPTYSTRING'}|nil Input} Start Num}
      else
         if {List.length Input}<Start+Num then
            nil
         else
            Res={List.drop Input Start}
            {List.take Res Num}
         end
      end
   end

   %With Start being 0, split a List of word into packet of Num size of word -->[a b c d] --> [[a b c] [b c d]]
   %Input: a List of ByteString  Start: Where to Start in the List    Num: The size of each subarray
   fun {ClusterMaker Input Start Num} Sub in
      case Input of nil then nil
      [] H|T then
         Sub={SubCluster Input Start Num}
         if Sub==nil then
            nil
         else
            Sub|{ClusterMaker Input Start+1 Num}
         end
      end
   end

   %Word: le mot en byteString à trouver     File: un fichier lu et séparé en byteString
   %Flag: si le mot précédent est bien Word  Acc: contient un Dictionnaire qui est mis à jour 
   fun {TrainingWord Word File Acc Track} Size Retrieve Inc Name in


      case File of nil then 
         Acc
      [] H|T then
         if Track>{List.length Word} then
            Name={String.toAtom H}
            Retrieve={Value.condSelect Acc Name 0}+1
            {TrainingWord Word T {Record.adjoin Acc a(Name : Retrieve)} 1}
         else
            if H=={List.nth Word Track} then
                  {TrainingWord Word T Acc Track+1}
            else
                  {TrainingWord Word T Acc 1}
            end
         end

      end
   end

   %Take a List and "mash" them together
   %ex: [a b c d] --> a_b_c_d
   fun {Mashing Input}
      case Input of nil then ""
      [] H|T then H#"_"#{Mashing T}
      end
   end

   %Cherche parmis tous les fichiers (liste dans Files) un mot et retourner les probas d'avoir un tel comme second
   fun {TrainingWordFiles Word Files Acc N} Size NewAcc ByteFiles Mashed in
      Size=NumberWord % Nombre de mots, à remplacer par CountAllWords

      case Files of nil then 
         %Because Dictionnary is not supported by pickle in Oz
         Mashed={VirtualString.toString {Mashing Word}}
         {Pickle.saveWithHeader Acc "Pickle/Word/"#Mashed#".ozp" "Pour "#Mashed 0} %It uses a false compression take 4kb on disk for 24bit
         {Browse 'Finished'}
         Acc
      [] H|T then
         NewAcc={TrainingWord Word H Acc 1} 
         {TrainingWordFiles Word T NewAcc N}
      end
   end

   fun {FindBiggestHelper List Name Max}
      case List of nil then Name
      [] H|T then
          if H.2 > Max then
              {FindBiggestHelper T H.1 H.2}
          else
              {FindBiggestHelper T Name Max}
          end
      end
  end
  
   %Take a Record and return the biggest key for its value
   fun {FindBiggest Input} Temp in
      {FindBiggestHelper {Record.toListInd Input} nil 0}
   end

   Parsed={SplitMultiple{List.map {OpenMultipleFile {OS.getDir {GetSentenceFolder}}} Clean}} %Contains the parsed documents
   
   proc {PressNgram InputHandle OutputHandle Ngram} InputText CleanText1 CleanText Last Dict TempDict TempRes PlaceHolder WordRecord TempAcc in
      if Ngram =< 0 then
         {Browse 'There is no word like this'}
      else
         %To get the user's input
         {InputHandle get(1:InputText)}
         CleanText1={Split InputText}
         if {List.length CleanText1} < Ngram then
            {Browse 'None'}
            {Delay 1000}
            {PressNgram InputHandle OutputHandle {List.length CleanText1}}
         else
            CleanText={ClusterMaker CleanText1 0 Ngram}
            Last={List.last CleanText}

            {Browse 'Trying with '#Ngram#' word and for '#{List.map Last String.toAtom}}
            %Check if the Pickle is already existing
            {Browse {List.map {OS.getDir "Pickle/Word"} String.toAtom}}
            {Browse {String.toAtom {VirtualString.toString {Mashing Last}#".ozp"}}}
            if {List.member {VirtualString.toString {Mashing Last}#".ozp"} {OS.getDir "Pickle/Word"}} then
               {Browse 'Exist'}
               WordRecord={Pickle.load "Pickle/Word/"#{VirtualString.toAtom {ByteString.toString {Mashing Last}}#".ozp"}}
            else
               {Browse 'Working'}
               TempDict=a()
               WordRecord={TrainingWordFiles Last Parsed TempDict Ngram}
            end

            {Browse WordRecord}
            %Add the true Pickle loading with concatenation
            %create a search inside a tuple
            case {FindBiggest WordRecord} of nil then    
               {Browse {FindBiggest WordRecord}}
               {PressNgram InputHandle OutputHandle Ngram-1}   
            else
               {Browse {FindBiggest WordRecord}}  
               PlaceHolder={FindBiggest WordRecord}
               {OutputHandle set(1:{Clean InputText}#" "#PlaceHolder)} %{FindBiggestDict Dict}
            end
         end
      end
   end

   % Acept only alpha character
   fun {OnlyAlpha List}
      case List of nil then nil
      [] H|T then 
         %{Browse {Atom.toString H}}
         %{Browse {List.filter {Atom.toString H} Char.isAlpha}} %h
         {List.filter {Atom.toString H} Char.isAlpha}|{OnlyAlpha T}
      end
   end

   % Avoiding to pick twice the same word
   % File: Openmultiple files    Dict: Dict to store everything
   proc {RemoveTwice File Dict} Res in
      case File of nil then skip
      [] H|T then
         if {Dictionary.member Dict {String.toAtom {ByteString.toString H}}} then
            {RemoveTwice T Dict}
         else
            if {List.member 39 {ByteString.toString H}} then
               {Browse true}
            else
               {Dictionary.put Dict {String.toAtom {ByteString.toString H}} 1}
               {RemoveTwice T Dict}
            end
         end
      end
   end

   %Takes a list of list of bytestring and make it into a list of bytestring
   fun {Fuse Files}
      case Files of nil then nil
      [] H|T then 
          if {List.is H} then
              {List.append H {Fuse T}}
          else
              {List.append H|nil {Fuse T}}
          end
      end
   end

   fun {RemoveTwiceAll Files} Clean Res Finish in
      Finish={SplitMultiple Files}
      Clean={Fuse Finish}

      Res={Dictionary.new}
      {RemoveTwice Clean Res}

      {List.drop {Dictionary.keys Res} 1}
   end

   %Function to create a new Database of words
   %Files: openmultiple result of a file
   proc {TrainingAllWord Files} TrackWord SubFiles Clean Splited in
      Splited={SplitMultiple Files}
      Clean={RemoveTwiceAll Files}
      
      %Remove Issue with Keys
      {List.forAll Clean proc{$ Word} {TrainingOneWordFiles {Atom.toString Word} Splited {Dictionary.new}} end}

      %Splited={SplitMultiple Files}
      %{List.forAll {List.drop {Dictionary.keys Clean} 1} proc{$ Word} {Browse Word} {TrainingOneWordFiles Word Splited {Dictionary.new}} end}
   end
      
   %To get the current OS
   fun {GetOs} OSType in
      OSType={Atom.toString {OS.getEnv 'OZHOME'}}
      if OSType.1 == 67 then %67 is the ASCII code for "C"
         "Windows"
      else
         "Linux"
      end 
   end      


   %To Update the databse It looks to every file in the directory to count word and TODO clean every pickle or force to always redo pickle
   proc {UpdateDatabase Handle} Test PidI StatusT OSType Info in
      {Handle set(1:"Démarrage du procéssus cela peut prendre quelques minutes" foreground:red)}
      OSType={GetOs}
      Test={CountAllWords {OpenMultipleFile {OS.getDir {GetSentenceFolder}}}}

      {Pickle.saveWithHeader Test "Pickle/NumberWord.ozp" "Nombre mots" 0} % 0 à 9 et au + haut au + compressé

      if OSType=="Linux" then
         {OS.pipe "sh Pickle/Update.sh" "" PidI StatusT}
         Info=" "
      else
         Info="\n ATTENTION Pour forcer la mise à jour de tous les mots, veuillez supprimer les fichiers contenu dans Twit-Oz/Pickle/Word (cela est dû à une limitation du langage)"
      end

      {Browse 'Updating'}
      {TrainingAllWord {OpenMultipleFile {OS.getDir {GetSentenceFolder}}}}

      {Handle set(1:"La base de donnée à été mise à jour avec succès!"#Info foreground:green)}
   end

   %Just a Helper procedure to dipslay all Keys of dictionary. YOU SHOULD CALL {DisplayDict Dic} RATHER
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

   %Just a HELPER procedure to find the biggest value.  YOU SHOULD CALL {FingBiggestDic Dic} RATHER
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

   %Take a string and remove extra space and newline 
   fun {RemoveNewLine String} CleanText in
      case String
      of nil then nil
      [] H|T then
         if {List.last String} == 10 then
            {RemoveNewLine {List.take String {List.length String}-1}}
         else if {List.last String} == 32 then
               {RemoveNewLine {List.take String {List.length String}-1}}
            else
               {List.append String 32|nil} %Just add a space character so the split function works perfectly
            end
         end
      end
   end

   %Get the last input of an input of text
   fun {GetLast List Acc}
      case List of nil then Acc
      [] H|T then {GetLast T H}
      end
   end

   proc {Infinity Num} Res in
      if Num =< 0 then
         skip
      else
         {Delay 50}
         {PressNgram InputText OutputText N}
         {OutputText get(1:Res)}
         {InputText set(1:Res)}
         {Browse Num}
         {Infinity Num-1}
      end
   end

   proc {ButtonInfinity} UserInput CleanInput in
      {InfiniteInput get(1:UserInput)}
      CleanInput={List.filter UserInput Char.isDigit}
      case CleanInput of nil then {Browse 'Please provide a correct number'}
      else
          {Browse {String.toInt CleanInput}}
          {Browse 'We are good'}
          {Infinity {String.toInt CleanInput}}
      end
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

      local NbThreads Description Window SeparatedWordsStream SeparatedWordsPort Saving GetText ReadFiles TestRes CountTest FeedbackUpdate Another Newcommers in
      {Property.put print foo(width:1000 depth:1000)}  % for stdout siz

      %Lis les fichiers
      ReadFiles={OpenMultipleFile {OS.getDir TweetsFolder}}

      proc {Newcommers POPUP}
         {NewWin HelpMessage Desc POPUP R}
      end
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
      background:black
      menubutton(glue:nw foreground:black highlightcolor:DarkerBGC background:DarkerBGC text:"File" font:Font width:5
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
      %local han in
         %han = {New POPUP}
      command(text:"Newcommers"  foreground:black action:proc{$}{Newcommers POPUP} end)
      %end
      command(text:"About" foreground:black )))) %action:proc{$} {Extra.Test} end
      lr(background:BGColor 
      glue:nw
      text(handle:InputText init:"Type a Tweet" width:50 height:10 background:white foreground:black wrap:word glue:nw insertbackground:black) 
      td(
         background:BGColor 
         glue:w
         button(glue:w text:"Predict" init:"Result" padx:10 pady:3 foreground:black bg:DarkerBGC width:15 action:Press key:"Return")
         button(glue:w text:"Infinity" init:"Infinity" padx:10 pady:3 foreground:black bg:DarkerBGC width:15 action:ButtonInfinity)
         text(handle:InfiniteInput init:"Amount" width:10 height:1 font:Font wrap:word background:white glue:w  padx:40 pady:3 foreground:black insertbackground:black)))
      lr(background:BGColor 
      glue:nw
      text(handle:OutputText width:50 height:10 background:black foreground:white glue:nw wrap:word)
      text(init:"Pour mettre à jour la base de donnée, cliquez sur File puis Update Database" font:Font handle:FeedbackUpdate wrap:word padx:5 background:BGColor foreground:black cursor:"X_cursor" width:30 height:10 glue:w relief:{String.toAtom "flat"} action:proc{$}{FeedbackUpdate set(1:"Pour mettre à jour la base de donnée, cliquer sur File" foreground:black)}end))
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
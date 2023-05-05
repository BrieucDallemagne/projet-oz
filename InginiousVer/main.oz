functor
import 
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
   Application
   Open
   OS
   Property
   Browser
define
   Parsed
   SeparatedWordsStream
   NumFiles
   Files
   FilesPerThread
   InputText 
   OutputText
   NbThreads


   proc {DataThread Files Ports}
      thread {Send Ports  {SplitMultiple{List.map {OpenMultipleFile Files} Clean} }}end
   end

   proc {Rec I FilesPerThread NumFiles Files Ports}
      local
         StartIndex 
         EndIndex 
         ThreadFiles
         TakeLol 
      in
         if I == 0 then skip 
         else
            if FilesPerThread.2 == nil then
               TakeLol=FilesPerThread.1
            else
               TakeLol=FilesPerThread.2.1-FilesPerThread.1
            end
            StartIndex = (I - 1) * FilesPerThread.1
            EndIndex = I * FilesPerThread.1
            ThreadFiles = {List.take {List.drop Files FilesPerThread.1} TakeLol} 
            {DataThread ThreadFiles Ports}
            {Rec I-1 FilesPerThread.2 NumFiles Files Ports }
         end
      end
   end  

   fun {LoadBalancer NumFiles NbThreads Remaining}
      if Remaining < 2*(NumFiles div NbThreads) then
         Remaining|nil
      else
         (NumFiles div NbThreads)|{LoadBalancer NumFiles NbThreads Remaining-(NumFiles div NbThreads)}
      end
   end

   fun {FakeFold List Acc}
      case List of nil then nil
      [] H|T then H+Acc|{FakeFold T H+Acc}
      end
   end

   proc {LaunchThreads Ports NbThreads}
   
      Files = {OS.getDir {GetSentenceFolder}}
   
      NumFiles = {List.length Files}
      FilesPerThread = {FakeFold {LoadBalancer NumFiles NbThreads NumFiles} ~{LoadBalancer NumFiles NbThreads NumFiles}.1}
      {Rec NbThreads FilesPerThread NumFiles Files Ports}
   end

   %%% Pour ouvrir les fichiers
   class TextFile
      from Open.file Open.text
   end

   %Use {ClusterMaker}
   fun {SubCluster Input Start Num} Res in
      if {List.length Input} < Num then
         {SubCluster nil|Input Start Num}
      else
         if {List.length Input}<Start+Num then
            nil
         else
            Res={List.drop Input Start}
            {List.take Res Num}
         end
      end
   end


   %Word: le mot en byteString à trouver     File: un fichier lu et séparé en byteString
   %Flag: si le mot précédent est bien Word  Acc: contient un Dictionnaire qui est mis à jour 
   fun {TrainingWord Word File PassFile Acc Track} Retrieve Name in
      %{Browse File}

      case File of nil then 
         Acc
      [] H|T then
         if Track>{List.length Word} then
            Name={String.toAtom H}
            Retrieve={Value.condSelect Acc Name 0}+1
            {TrainingWord Word {List.take PassFile 1}.1|H|T PassFile {Record.adjoin Acc a(Name : Retrieve)} 1}
         else
            if H=={List.nth Word Track} then
                  {TrainingWord Word T H|PassFile Acc Track+1}
            else
               if Track > 1 then
                  {TrainingWord Word H|T PassFile Acc 1}
               else
                  {TrainingWord Word T H|PassFile Acc 1}
               end
            end
         end

      end
   end

   fun {TrainingWordHelper Word BigFiles Acc}
      case BigFiles of nil then Acc
      [] H|T then {TrainingWordHelper Word T {TrainingWord Word {NilatorHelp H 2}  nil Acc 1}}
      end
   end

   %Cherche parmis tous les fichiers (liste dans Files) un mot et retourner les probas d'avoir un tel comme second
   fun {TrainingWordFiles Word Files Acc N} NewAcc in
      %Size=NumberWord % Nombre de mots, à remplacer par CountAllWords

      case Files of nil then 
         %Because Dictionnary is not supported by pickle in Oz
         {Browse Acc}
         Acc
      [] H|T then
         NewAcc={TrainingWordHelper Word H Acc} 
         {TrainingWordFiles Word T NewAcc N}
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


   fun {NilatorHelp ListSimplePointSplit Ngram}
      if Ngram =< 1 then
         ListSimplePointSplit
      else
         {NilatorHelp nil|ListSimplePointSplit Ngram-1}
      end
   end
   
   fun {Nilator ListPointSplit Ngram}
      case ListPointSplit of nil then nil
      [] H|T then {NilatorHelp H Ngram}|{Nilator T Ngram}
      end
   end
   
   fun {SplitHelper Input}
      case Input of nil then nil
      [] H|T then {List.filter {String.tokens H & } fun {$ O} O \= nil end}|{SplitHelper T}
      end
   end
   
   fun {Split Input}
      {SplitHelper {String.tokens {Clean Input} &.}}
   end

   fun {SplitMultiple ListInput}
         case ListInput of nil then nil
         [] H|T then {Split H}|{SplitMultiple T}
         end
   end

   fun {FindBiggestHelper List Name Max}
      case List of nil then Name
      [] H|T then
          if H.2 > Max then
               if {Char.isPunct {Atom.toString H.1}.1} then
                  {FindBiggestHelper T Name Max}
               else
                  {FindBiggestHelper T H.1 H.2}
               end
          else
              {FindBiggestHelper T Name Max}
          end
      end
  end
  
   %Take a Record and return the biggest key for its value
   fun {FindBiggest Input}
      {FindBiggestHelper {Record.toListInd Input} nil 0}
   end

   %Read a file. File is the name of the file
   fun {ReadFile File} F Res in
      F={New Open.file init(name:{GetSentenceFolder}#"/"#{String.toAtom File} flags:[read])}
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

   proc {Browse Buf}
      {Browser.browse Buf}
   end

   %Takes a String and remove all non Ascii Character
   fun {Clean Input}
      case Input of nil then nil
      [] H|T then 
         if {Char.isCntrl H} then
            32|46|32|{Clean T}
         else 
            if {Char.isAlNum H} then
                  if H >= 126 then
                     32|{Clean T}
                  else
                     {Char.toLower H}|{Clean T}
                  end
            else
               if {Char.isPunct H} then
                  32|46|32|{Clean T}
               else
                  32|{Clean T}
               end
            end
         end
      end
   end



   proc {PressNgram InputHandle OutputHandle Ngram Result} InputText CleanText1 CleanText Last TempDict Occu WordRecord BigWord TPMResult in
      if Ngram =< 0 then
         %{Browse 'There is no word like this'}
         Result=[[nil] 0]
      else
         %To get the user's input
         {InputHandle get(1:InputText)}
         CleanText1={List.last {List.filter {List.filter {Split {Clean InputText}} fun{$ O} O \= "." end} fun{$ O} O \= nil end}}
         if {List.length CleanText1} == 0 then
            Result=[[nil] 0]
         else 
            CleanText={ClusterMaker CleanText1 0 Ngram}
            Last={List.last CleanText}

            {Browse 'Last'}
            {Browse Last}
            TempDict=a()
            WordRecord={TrainingWordFiles Last Parsed TempDict Ngram}
            {Browse WordRecord}


            %Add the true Pickle loading with concatenation 
            %create a search inside a tuple
            BigWord={FindBiggest WordRecord}
            case BigWord of nil then    
               Result=[[nil] 0]
               %{PressNgram InputHandle OutputHandle Ngram-1 Result}
            else
               Occu={Value.'.' WordRecord BigWord}
               TPMResult=[{List.filter {List.filter {Record.arity WordRecord} fun{$ C} {Char.isPunct {Atom.toString C}.1}==false end} fun{$ O} {Value.'.' WordRecord O}==Occu end} Occu]

               if TPMResult.1 == nil then
                  Result=[[nil] 0]
               else
                  Result=TPMResult
                  {OutputHandle set(1:BigWord)}
               end               
            end
         end
      end
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
   fun {Press} Result in
      {PressNgram InputText OutputText 2 Result}
      {Browse Result}
      Result
   end
   
   %%% Ajouter vos fonctions et procédures auxiliaires ici


   %%% Fetch Tweets Folder from CLI Arguments
   %%% See the Makefile for an example of how it is called
   fun {GetSentenceFolder}
      Args = {Application.getArgs record('folder'(single type:string optional:false))}
   in
      Args.'folder'
   end

   fun {StreamtoList S }
      case S of nil|T then nil
      [] H|T then if H == fin then {Browse 'fin du stream'} nil
                  else H|{StreamtoList T}
                  end
      else nil
      end
   end

   fun {ForList S NbThreads Acc}
      if NbThreads < 1 then Acc
      else {ForList S.2 NbThreads-1 {List.append {StreamtoList S.1} Acc} }
      end
   end

   SeparatedWordsPort = {NewPort SeparatedWordsStream}
   WantedNbThreads=8

   if {List.length {OS.getDir {GetSentenceFolder}}} < WantedNbThreads then
      NbThreads={List.length {OS.getDir {GetSentenceFolder}}}
   else
      NbThreads=WantedNbThreads
   end

   {LaunchThreads SeparatedWordsPort NbThreads}

   Parsed = {ForList SeparatedWordsStream NbThreads nil}
   %{Browse {List.length Parsed}}

   %%% Decomnentez moi si besoin
   %proc {ListAllFiles L}
   %   case L of nil then skip
   %   [] H|T then {Browse {String.toAtom H}} {ListAllFiles T}
   %   end
   %end
    
   %%% Procedure principale qui cree la fenetre et appelle les differentes procedures et fonctions
   proc {Main}
      TweetsFolder = {GetSentenceFolder}
   in
      %% Fonction d'exemple qui liste tous les fichiers
      %% contenus dans le dossier passe en Argument.
      %% Inspirez vous en pour lire le contenu des fichiers
      %% se trouvant dans le dossier
      %%% N'appelez PAS cette fonction lors de la phase de
      %%% soumission !!!
      % {ListAllFiles {OS.getDir TweetsFolder}}
       
      local NbThreads Description Window SeparatedWordsStream SeparatedWordsPort in
	 {Property.put print foo(width:1000 depth:1000)}  % for stdout siz
	 
            % TODO
	 
            % Creation de l interface graphique
	 Description=td(
			title: "Text predictor"
			lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:proc{$} _={Press} end))
			text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
			action:proc{$}{Application.exit 0} end % quitte le programme quand la fenetre est fermee
			)
	 
            % Creation de la fenetre
	 Window={QTk.build Description}
	 {Window show}
	 
	 {InputText tk(insert 'end' "Loading... Please wait.")}
	 {InputText bind(event:"<Control-s>" action:Press)} % You can also bind events
	 
	 
	 {InputText set(1:"")}
      end
      %%ENDOFCODE%%
   end
    % Appelle la procedure principale
   {Main}
end
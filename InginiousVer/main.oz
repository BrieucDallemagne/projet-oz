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
   InputText 
   OutputText

   thread
      %Permet de lire tous les fichiers et fait des listes de mots
      Parsed={SplitMultiple{List.map {OpenMultipleFile {OS.getDir {GetSentenceFolder}}} Clean}} %Contains the parsed documents
   end



   %%% Pour ouvrir les fichiers
   class TextFile
      from Open.file Open.text
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

   %Word: le mot en byteString à trouver     File: un fichier lu et séparé en byteString
   %Flag: si le mot précédent est bien Word  Acc: contient un Dictionnaire qui est mis à jour 
   fun {TrainingWord Word File Acc Track} Retrieve Name in
      %{Browse File}

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

   %Cherche parmis tous les fichiers (liste dans Files) un mot et retourner les probas d'avoir un tel comme second
   fun {TrainingWordFiles Word Files Acc N} NewAcc in
      %Size=NumberWord % Nombre de mots, à remplacer par CountAllWords

      case Files of nil then 
         %Because Dictionnary is not supported by pickle in Oz
         
         Acc
      [] H|T then
         NewAcc={TrainingWord Word H Acc 1} 
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

   fun {Split Input}
      {List.filter {String.tokens {Clean Input} & } fun {$ O} O \= nil end}
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
              {FindBiggestHelper T H.1 H.2}
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
            32|46|{Clean T}
         else 
            if {Char.isAlNum H} then
                  if H >= 126 then
                     32|{Clean T}
                  else
                     {Char.toLower H}|{Clean T}
                  end
            else
               if {Char.isPunct H} then
                  32|H|{Clean T}
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
         CleanText1={List.filter {Split {Clean InputText}} fun{$ O} O \= "." end}
         %{Browse CleanText1}
         if {List.length CleanText1} < Ngram then
         
            %{PressNgram InputHandle OutputHandle {List.length CleanText1} Result}
            Result=[[nil] 0]
         else
            CleanText={ClusterMaker CleanText1 0 Ngram}
            Last={List.last CleanText}
            TempDict=a()
            WordRecord={TrainingWordFiles Last Parsed TempDict Ngram}

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
      %{Browse Result}
      Result
   end
   
    %%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
    %%% Les threads de parsing envoient leur resultat au port Port
   proc {LaunchThreads Port N}
        % TODO
      skip
   end
   
   %%% Ajouter vos fonctions et procédures auxiliaires ici


   %%% Fetch Tweets Folder from CLI Arguments
   %%% See the Makefile for an example of how it is called
   fun {GetSentenceFolder}
      Args = {Application.getArgs record('folder'(single type:string optional:false))}
   in
      Args.'folder'
   end

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
	 
            % On lance les threads de lecture et de parsing
	 SeparatedWordsPort = {NewPort SeparatedWordsStream}
	 NbThreads = 4
	 {LaunchThreads SeparatedWordsPort NbThreads}
	 
	 {InputText set(1:"")}
      end
      %%ENDOFCODE%%
   end
    % Appelle la procedure principale
   {Main}
end
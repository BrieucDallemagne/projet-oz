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
   %For QTK
   BGColor=c(242 242 242) % couleur fond
   DarkerBGC=c(230 230 230) % couleur de contraste
   BlueNice=c(0 114 153)
   Font={QTk.newFont font(family:"Helvetica" size:10 weight:normal slant:roman underline:false overstrike:false)}
   MidFont={QTk.newFont font(family:"Helvetica" size:15 weight:normal slant:roman underline:false overstrike:false)}
   BigFont={QTk.newFont font(family:"Helvetica" size:20 weight:normal slant:roman underline:false overstrike:false)}

   SpiceHandle
   NumFiles
   SeparatedWordsStream
   FilesPerThread
   InputText
   OutputText
   InfiniteInput
   Parsed
   NbThreads
   ListFile
   NumberWord
   DataBase
   N % le N de N-gramme
   NgramHandle % son Handle
   Files
   Akinator={QTk.newImage photo(file:"./Pic/akinator_1_defi.png" format:"png" height:100 width:100)}
   C
   D
   Running
   
   thread
      NumberWord={Pickle.load 'Pickle/NumberWord.ozp'} % à généraliser pour tout système
      DataBase={Pickle.load 'Pickle/DataBase.ozp'} %load Pickle
   end


   %%% Pour ouvrir les fichiers
   class TextFile
      from Open.file Open.text
   end

   proc {Browse Buf}
      {Browser.browse Buf}
   end

   fun {GetN} NHandle in
      {NgramHandle get(1:NHandle)}
      if {String.isInt NHandle} then
         {String.toInt NHandle}
      else
         2
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

   fun {Press} Result in
      {System.gcDo}
      {PressNgram InputText OutputText {GetN} Result}
      Result
   end

   %%% Fetch Tweets Folder from CLI Arguments
   %%% See the Makefile for an example of how it is called
   fun {GetSentenceFolder}
      Args = {Application.getArgs record('folder'(single type:string optional:false) 'ngram'(single type:string optional:false) 'save'(single type:string optional:false) 'random'(single type:string optional:false))}
   in
      Args.'folder'
   end

   fun {NgramCLI}
      Args = {Application.getArgs record('folder'(single type:string optional:false) 'ngram'(single type:string optional:false) 'save'(single type:string optional:false) 'random'(single type:string optional:false))}
   in
      Args.'ngram'
   end

   fun {SaveCLI}
      Args = {Application.getArgs record('folder'(single type:string optional:false) 'ngram'(single type:string optional:false) 'save'(single type:string optional:false) 'random'(single type:string optional:false))}
   in
      Args.'save'
   end

   fun {RandomCLI}
      Args = {Application.getArgs record('folder'(single type:string optional:false) 'ngram'(single type:string optional:false) 'save'(single type:string optional:false) 'random'(single type:string optional:false))}
   in
      Args.'random'
   end

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


   %%% Ajouter vos fonctions et procédures auxiliaires ici

   %To create a pop-up window displaying some text
   proc {NewWin Message Inside Handle Return}
      {{QTk.build Inside} show}
      {Handle set(Message)}
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

   %Take a List and "mash" them together
   %ex: [a b c d] --> a_b_c_d
   fun {Mashing Input}
      case Input of nil then ""
      [] H|T then H#"_"#{Mashing T}
      end
   end

   %Word: le mot en byteString à trouver     File: un fichier lu et séparé en byteString
   %Flag: si le mot précédent est bien Word  Acc: contient un Dictionnaire qui est mis à jour 
   fun {TrainingWord Word File PassFile Acc Track} Retrieve Name in

      case File of nil then 
         Acc
      [] H|T then
         if Track>{List.length Word} then
            Name={String.toAtom H}
            Retrieve={Value.condSelect Acc Name 0}+1
            if Track == 2 then
               {TrainingWord Word H|T PassFile {Record.adjoin Acc a(Name : Retrieve)} 1}
            else
               {TrainingWord Word {List.take PassFile 1}.1|H|T PassFile {Record.adjoin Acc a(Name : Retrieve)} 1}
            end
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

   fun {TrainingWordHelper Word BigFiles Acc N}
      case BigFiles of nil then Acc
      [] H|T then {TrainingWordHelper Word T {TrainingWord Word {NilatorHelp H N}  nil Acc 1} N}
      end
   end

   %Cherche parmis tous les fichiers (liste dans Files) un mot et retourner les probas d'avoir un tel comme second
   fun {TrainingWordFiles Word Files Acc N} NewAcc in
      %Size=NumberWord % Nombre de mots, à remplacer par CountAllWords

      case Files of nil then 
         %Because Dictionnary is not supported by pickle in Oz
         Acc
      [] H|T then
         NewAcc={TrainingWordHelper Word H Acc {GetN}} 
         {TrainingWordFiles Word T NewAcc N}
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

   %take a list of string ["hello" "world"] and output "hello world"
   fun {BuildSentence StringList}
      case StringList of nil then nil
      [] H|T then
         if T == nil then
            H
         else
            H#" "#{BuildSentence T}
         end
      end
   end
   
   proc {PressNgram InputHandle OutputHandle Ngram Result} InputText CleanText1 CleanText Last Dict TempDict TempRes PlaceHolder WordRecord TempAcc Dir BigWord SpiceTest in
      if Ngram =< 0 then
         {OutputHandle set(1:'There is no word like this')}
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

            try %To Handle missing directory and inginious issue
               _={List.member {VirtualString.toString {Mashing Last}#".ozp"} {OS.getDir "Pickle/Word"}}
               Dir=true
            catch X then
               {Browse 'No directory found'}
               Dir=false
            end
 
            if Dir then
               if {List.member {VirtualString.toString {Mashing Last}#".ozp"} {OS.getDir "Pickle/Word"}} then
                  WordRecord={Pickle.load "Pickle/Word/"#{VirtualString.toAtom {ByteString.toString {Mashing Last}}#".ozp"}}
               else
                  TempDict=a()
                  WordRecord={TrainingWordFiles Last Parsed TempDict Ngram}
               end
            else
               TempDict=a()
               WordRecord={TrainingWordFiles Last Parsed TempDict Ngram}
            end

            %Add the true Pickle loading with concatenation 
            %create a search inside a tuple
            BigWord={FindBiggest WordRecord}
            case BigWord of nil then    

               {PressNgram InputHandle OutputHandle Ngram-1 Result}
            else
               {SpiceHandle get(1:SpiceTest)}

               if SpiceTest then
                  PlaceHolder={List.nth {Record.toListInd WordRecord} 1+{OS.rand} mod {Record.width WordRecord}}.1
               else
                  PlaceHolder=BigWord
               end
               Result=[{Record.arity WordRecord} {List.foldL {Record.toList WordRecord} fun{$ X Y} X+Y end 0}]
               {TestImage WordRecord.PlaceHolder Result.2.1}

               {OutputHandle set(1:{BuildSentence CleanText1}#" "#PlaceHolder)}
            
            end
         end
      end
   end

   % Acept only alpha character
   fun {OnlyAlpha List}
      case List of nil then nil
      [] H|T then 
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
         PidI={OS.system "ls"}
         StatusT={OS.system "make pickle"}
         Info="\n ATTENTION Pour forcer la mise à jour de tous les mots, veuillez supprimer les fichiers contenu dans Twit-Oz/Pickle/Word (cela est dû à une limitation du langage)"
      end

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

   proc {Infinity Num} Res Result in
      if Num =< 0 then
         skip
      else
         Result={Press}
         {OutputText get(1:Res)}
         {InputText set(1:Res)}
         {Infinity Num-1}
      end
   end

   proc {ButtonInfinity} UserInput CleanInput in
      {Loading 100.0}
      {InfiniteInput get(1:UserInput)}
      CleanInput={List.filter UserInput Char.isDigit}
      case CleanInput of nil then {Browse 'Please provide a correct number'} {Running set(1:false)}
      else
          {Infinity {String.toInt CleanInput}}
          {Running set(1:false)}
      end
   end

   proc {FullGramHelper N Files}
      {Browse 'New'}
   end


   proc {FullGram}
      {FullGramHelper {GetN} Parsed}
   end

   proc {Save} F Input Ecrit in %To Save input 
      {OutputText get(1:Input)}
      F={New Open.file init(name:"User/"#{Mashing {Split Input}}#".txt" flags:[write] mode:mode(owner:[write] all:[write] group:[write] others:[write]))}

      {F write(vs:Input len:{List.length Input})}
      {F close()}
   end

   proc {CleanPickle} Done in
      Done={OS.system "make pickle"}
   end

   proc {CleanUser} Done in
      Done={OS.system "make user"}
   end

   fun {Reducing ListInput}
      {List.map ListInput fun{$ O}{List.foldL O fun{$ X Y} X+Y end 0} end }
   end
   
   fun {FindClosest Input ListWord Start Track Diff} Close in
      if Start > {List.length ListWord} then
            Track
      else
            Close={Number.abs {Number.'-' Input {List.nth ListWord Start}}}
            if Close < Diff then
               {FindClosest Input ListWord Start+1 Start Close}
            else
               {FindClosest Input ListWord Start+1 Track Diff}
            end
      end
   end 
      
   fun {CorrectInputHelper Check Correct} Result in
      Result={FindClosest {Reducing [Check]}.1 {Reducing Correct} 1 0 1000}
      if Result == 0 then
         Check
      else
         {List.nth Correct Result}
      end
   end

   fun {CorrectInputSecond Count Correct Input}
      case Input of nil then nil
      [] H|T then {CorrectInputHelper H Correct}|{CorrectInputSecond Count-1 Correct T}
      end
   end

   proc {CorrectInput} Input Result CorrectWord in
      {InputText get(1:Input)}
      CorrectWord={List.map {RemoveTwiceAll {OpenMultipleFile {OS.getDir {GetSentenceFolder}}}} Atom.toString} % Accelerate process using Parsedµ
      {Delay 1000}
      Result={CorrectInputSecond {List.length Input} CorrectWord {Split {Clean Input}}}
      {OutputText set(1:{List.tokens {Mashing Result} & })}
   end

   proc {OpenDialog} Path F Content in
      thread
         Path={QTk.dialogbox load(initialdir:"./User" title:"Load" filetypes:q(q( "Texte" q(".txt"))) defaultextension:"txt" $)}
      end
      if Path==nil then
         skip
      else
         F={New Open.file init(name:Path flags:[read])}
         {F read(list:Content size:all)}
         {F close}
         {InputText set(1:Content)}
      end
   end

   proc {TestImage Occ All} Ratio InFill NewFont in


      NewFont={QTk.newFont font(family:"Helvetica" size:10 weight:normal slant:roman underline:false overstrike:false)}
      Ratio={Int.toFloat Occ} / {Int.toFloat All} %Number/All
      InFill=c({Float.toInt (1.0-Ratio)*255.0} {Float.toInt Ratio*255.0} 0)

      {C create(arc 10 10 190 190 fill:BGColor outline:DarkerBGC start:220 extent:~260 width:11 style:arc)} %to clean
      {C create(rectangle 50 50 150 150 fill:BGColor outline:BGColor)}

      {C create(text 95 95 font:BigFont text:{Int.toString {Float.toInt 100.0*Ratio}}#"%" width:70 fill:InFill)}
      {C create(arc 10 10 190 190 fill:BGColor outline:InFill start:220 extent:{Float.toInt ~260.0*Ratio} width:10 style:arc)}
   end

   proc {Loader Phase Rot} State in
      {Running get(1:State)}
      {D create(arc 12 12 88 88 fill:BGColor outline:DarkerBGC start:(Phase-2)*Rot-2 extent:Rot+2 width:16 style:arc)}
      if State then
         {D create(arc 10 10 90 90 fill:BGColor outline:BlueNice start:(Phase-1)*Rot extent:Rot width:11 style:arc)}
         {Delay Rot}
         if Phase > 360 div Rot then
            {Loader 0 Rot}
         else
            {Loader Phase+1 Rot}
         end
      else
         skip
      end
   end

   proc {Loading Time} Fact in
      Fact=(Time / 1000.0)
      thread
         {Running set(1:true)}
         {Loader 0 {Float.toInt (360.0 * Fact)}}
         {D create(oval 10 10 90 90 fill:BGColor outline:DarkerBGC width:15)}
      end
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

%%% Procedure principale qui cree la fenetre et appelle les differentes procedures et fonctions
   proc {Main}
      TweetsFolder = {GetSentenceFolder}
      Maxsize=maxsize(width:1920 height:1080)
      Minsize=minsize(width:720 height:380)
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

      % Parse args
      NgramYes={NgramCLI}
      SaveYes={SaveCLI}
      RandomYes={RandomCLI}
   in

      local NbThreads Description Window SeparatedWordsStream SeparatedWordsPort ReadFiles FeedbackUpdate Newcommers in
      {Property.put print foo(width:1000 depth:1000)}  % for stdout siz

      %Lis les fichiers
      ReadFiles={OpenMultipleFile {OS.getDir TweetsFolder}}

      proc {Newcommers POPUP}
         {NewWin HelpMessage Desc POPUP R}
      end

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
      command(text:"Delete Tree" foreground:black action:CleanPickle accelerator:"Control-Alt-b") % Ici, on ajoute des boutons pour controler l'application
      separator
      command(text:"Save" foreground:black action:Save accelerator:"Control-s")
      command(text:"Delete Save" foreground:black action:CleanUser accelerator:"Control-Alt-s") % Ici, on ajoute des boutons pour controler l'application
      separator
      command(text:"Open" foreground:black action:OpenDialog accelerator:"Control-o")
      separator
      command(text:"Quit" foreground:black action:proc{$}{Application.exit 0} end accelerator:"Control-q")    
      ))
      menubutton(glue:nw foreground:black highlightcolor:DarkerBGC bg:DarkerBGC text:"Help" font:Font width:5
      menu:menu(background:DarkerBGC 
      tearoff:false
      %local han in
         %han = {New POPUP}
      command(text:"About"  foreground:black action:proc{$} Pop=POPUP Win=Newcommers in {Win Pop} end)))) %action:proc{$} {Extra.Test} end
      lr(background:BGColor 
      glue:nw
      text(handle:InputText init:"Type a Tweet" width:50 height:10 background:white foreground:black wrap:word glue:nw insertbackground:black) 
      td(
         background:BGColor 
         glue:w
         entry(handle:NgramHandle init:"N (default:2)" width:10 font:Font background:white glue:w  padx:30 pady:3 foreground:black insertbackground:black)
         button(glue:w text:"Predict" init:"Result" padx:10 pady:3 foreground:black bg:DarkerBGC width:15 action:proc{$} ResultatPress in {Loading 100.0} ResultatPress={Press} {Running set(1:false)} end key:"Return")
         button(glue:w text:"Infinity" init:"Infinity" padx:10 pady:3 foreground:black bg:DarkerBGC width:15 action:ButtonInfinity)
         entry(handle:InfiniteInput init:"Amount" width:10 font:Font background:white glue:w  padx:30 pady:3 foreground:black insertbackground:black)
         %button(glue:w text:"Correct" init:"Correct" padx:10 pady:3 foreground:black bg:DarkerBGC width:15 action:CorrectInput)
         lr(
            checkbutton(text:"Running" handle:Running init:false background:BGColor foreground:black)
            checkbutton(text:"Randomizer" handle:SpiceHandle init:false background:BGColor foreground:black)
         )
         )
      canvas(handle:D height:100 width:100 background:BGColor borderwidth:0 highlightthickness:0 padx:10)
      %listbox(init:[a b c d] handle:ListFile)
      )
      lr(background:BGColor 
      glue:nw
      text(handle:OutputText width:50 height:10 background:black foreground:white glue:nw wrap:word)
      %message(init:"Pour mettre à jour la base de donnée, cliquez sur File puis Update Database" font:Font handle:FeedbackUpdate  padx:5 background:BGColor foreground:black glue:w)
      canvas(handle:C height:200 width:200 background:BGColor borderwidth:0 highlightthickness:0))
      action:proc{$}{Application.exit 0} end % quitte le programme quand la fenetre est fermee
      )

      % Creation de la fenetre
      Window={QTk.build Description}
      {Window show}
   
      {InputText tk(insert 'end' " Loading... Please wait.")}
   
      {InputText set(1:"")}

      {C create(arc 10 10 190 190 fill:BGColor outline:DarkerBGC start:220 extent:~260 width:11 style:arc)} %to clean
      {C create(text 100 160 font:MidFont text:"Probability" width:100)}
      {D create(oval 10 10 90 90 fill:BGColor outline:DarkerBGC width:15)}

      %Create the correct folder
      local PidA  in
         PidA={OS.system "make folder"}
      end
      
      %%ENDOFCODE%%
   end
end
% Appelle la procedure principale
   {Main}
end
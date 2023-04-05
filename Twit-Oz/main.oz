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

   %fun {Split Input Track Acc}
   %   case Input of nil then Acc
   %   [] H|T then
   %      if H==" " then
   %end

   fun {ReadFile File} F Res in
      F={New Open.file init(name:"tweets/"#{String.toAtom File} flags:[read])}
      {F read(list:Res size:100)} % set size to all to read the whole text
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

   %%% Decomnentez moi si besoin
   proc {ListAllFiles L}
      case L of nil then skip
      [] H|T then {Browse {String.toAtom H}} {ListAllFiles T}
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

      Opti={ByteString.make " hello world !"}
   in
      %% Fonction d'exemple qui liste tous les fichiers
      %% contenus dans le dossier passe en Argument.
      %% Inspirez vous en pour lire le contenu des fichiers
      %% se trouvant dans le dossier
      %%% N'appelez PAS cette fonction lors de la phase de
      %%% soumission !!!
      % {ListAllFiles {OS.getDir TweetsFolder}}

      local NbThreads InputText OutputText Description Window SeparatedWordsStream SeparatedWordsPort Saving GetText ReadFiles in
      {Property.put print foo(width:1000 depth:1000)}  % for stdout siz

      %Utilisation de Byte-String
      {Browse Opti}   
      {Browse {ByteString.width Opti}}
      {Browse {ByteString.length Opti}}
      {Browse {Char.is " "}}
      {Browse {ByteString.strchr Opti 0 " ".1}}

      ReadFiles={OpenMultipleFile {OS.getDir TweetsFolder}}
      % TODO

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
      button(text:"Predict" init:"Result" padx:10 foreground:black bg:DarkerBGC width:15 action:proc{$} {Browse {String.toAtom ReadFiles.1}} end key:"Return"))
      text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
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
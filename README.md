# rock-paper-scissors-dapp
## Entwicklung des Spiels "Rock, Paper, Scissors" als dApp auf der Ropsten Blockchain in der Sprache Solidity.

### Installationsanleitung
Für die Installation werden die Dateien im GitHub-Repository https://github.com/jhehemann/rock-paper-scissors-dapp, sowie ein Metamask Account mit ausreichend Ether auf der Ropsten Blockchain benötigt.

Um das Spiel spielen zu können, müssen die Dateien im Repository heruntergeladen werden. Anschließend navigiert man über die Konsole in den entsprechenden Ordner und führt die Datei server.js mit dem Befehl „node server.js“ aus. Nun kann über einen Browser die Adresse localhost:3000 aufgerufen werden. Die Weboberfläche des Spiels wird geladen und es öffnet sich das Metamask Plug-in. Nach erfolgreicher Anmeldung bei Metamask, kann das Spiel gespielt werden.

Falls man über die Remix IDE auf den Smart Contract und die ABI zugreifen oder die DApp gegebenenfalls weiterentwickeln möchte, sollte man zunächst den Code der Dokumente CloneFactory.sol und RockPaperScissors.sol in der Remix IDE kompilieren. Als nächstes muss zunächst der RockPaperScissorsGame Contract deployt und anschließend die erzeugte Adresse beim Deployment des RockPaperScissorsFactory Contracts als Parameter für den Konstruktor mitgegeben werden. Die Adressen für die Smart Contracts sind nachfolgend aufgelistet:

•	RockPaperScissorsFactory: 0xBB73D808cFFBb76b46C0Fc4aBEB8D72d4510996a
•	RockPaperScissorsGame: 0x90fD0DAc2e4b566752bC6963B6A93817AC4219fc
•	CloneFactory: 0x3a056b5922e4a9F1F1E6b4F61627b2609f8FE9Ad


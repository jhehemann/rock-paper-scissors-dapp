pragma solidity >=0.7.0 <0.9.0;               

import "./CloneFactory.sol";                        // Funktionen, die zum Erstellen eines Proxy-Contracts benötigt werden

contract RockPaperScissorsFactory is
    CloneFactory                                    //Vererbung von CloneFactory. Hier werden die Funktionen immer mit Werten gefüttert.
{
    address private owner;                          // Bestimmung des Eigentümers
    address gameContract;                           // Adresse des Game-Contracts, der die Grundlage für die Proxys ist
    address public queue;                           // Adresse des Spielers, der in der Warteschlange ist (erste Suchanfrage)
    address public PublicGame;                      // Öffentliche Adresse des erstellten Proxy-Contracts
    //address private gameaddress = address(0);     // temporäre GameAddresse
    uint public fee = 2000;                         // Service-Gebühr zum Starten einer Spielinstanz
    uint public bet = 10000;                        // Wetteinsatz
    event Game(address game);                       // Event zum loggen eines neuen Proxy Contracts des geklonten Spiels
    

    constructor(address _gamecontract) public {     // Adresse des deployten Game-Contracts muss manuell übergeben werden
        owner = msg.sender;                         // Setzen des Contract-Besitzers 
        gameContract = _gamecontract;               // Die Adresse des Basis-Contracts kommt in die globale Variable gameContract
    }

    modifier validFee() {
        require(msg.value == fee);                  //Modifier zur Prüfung, ob die Servicegebühr übermittelt wurde
        _;
    }

    modifier notAlreadyRegistered() {               //Modifier zur Prüfung, ob ein Spieler sich bereits für die Spielersuche registriert hat
        require(msg.sender != queue);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);                //Modifier zur Prüfung, ob der Sender der Besitzer des Contracts ist
        _;
    }

    function startGame() public payable notAlreadyRegistered validFee { 
        
       address gameaddress;
        if (queue == address(0)) {
            queue = msg.sender;                      //Wenn in der Queue keine Adresse hinterlegt ist, dann ist die Adresse des Aufrufers die queue und die Adresse des Game-Proxys 0
            gameaddress = address(0);

        } else {
            createGame(queue, msg.sender); 
            gameaddress = PublicGame;
            PublicGame = address(0);                 //Falls bereits ein Spieler in der Queue ist, wird ein Spiel für beide Spieler erstellt.
            queue = address(0);                      //Nach der Erstellung wird der Spieler aus der Warteschlange genommen
       }
       emit Game(gameaddress);                       //Event mit der Adresse des neuen Game-Proxys wird emittiert
    }


    function createGame(address playerA, address playerB) private {
        
        RockPaperScissorsGame game = RockPaperScissorsGame(
            createClone(gameContract)
        );                                                                  // Hier wird auf den Basiscontract zugegriffen und ein Clone von der Sorte RockPaperScissorGame erstellt. Dieser wird game genannt.
        game.init(playerA, playerB, bet);                                   // Dem Basiscontract werden mit der init-Funktion beide Spieleradressen und der Wetteinsatz übergeben. 
        PublicGame = address(game);
        
    } 
    
    
    //Hilfsfunktionen für den Owner
    //Anpassung des Wetteinsatzes
    function adjustBet(uint256 newBet) public onlyOwner {                  
        bet = newBet;                                           
    }  
    //Anpassung der Servicegebühr
    function adjustFee(uint256 newFee) public onlyOwner {                  
        fee = newFee;                                           
    }           
    //Auszahlung der Servicegebühren
    function withdrawFees() public onlyOwner {
        (bool success, bytes memory data)=  msg.sender.call{value: address(this).balance}("");           
    }
    //Ausgabe der gesammelten Gebühren
    function getBalance() public view onlyOwner returns (uint256 balance) {
        return address(this).balance;
    }
    //Eliminierung des Contracts aus der Blockchain
    function destroy() public onlyOwner {
        selfdestruct(payable(owner));
    }

}


contract RockPaperScissorsGame {                    //Basiscontract
    
    address public playerA;                         //Addressen beider Spieler
    address public playerB;
    uint public bet;  
    uint constant public revealTime = 5 minutes;    //Timer für Revealphase 
    uint firstRevealTime;
    uint constant public playTime = 5 minutes;     //Timer für Spielphase
    uint firstPlayTime;
    address private paid;

    enum Moves {None, Rock, Paper, Scissors}        //Aufzählungstypen für Wahl und Ausgang
    enum Outcomes {None, PlayerA, PlayerB, Draw} 

    bytes32 private encrMovePlayerA;                //Hier wird die gehashte Wahl der Spieler gespeichert
    bytes32 private encrMovePlayerB;

    Moves private movePlayerA;                      //Hier wird die tatsächliche Wahl (Rock, Paper, Scissors) der Spieler gespeichert
    Moves private movePlayerB;

    function init(
        address _playerA,                           //Init, als Funktion für die Übergabe der nötigen Parameter für das Proxy Spiel
        address _playerB,
        uint _bet
    ) public {
        playerA = _playerA;
        playerB = _playerB;
        bet = _bet;
    }

    modifier isRegistered() {                       //Modifier zur Prüfung, ob der Sender für das Spiel registriert ist
        require (msg.sender == playerA || msg.sender == playerB);
        _;
    }

    modifier commitPhaseEnded() {                   //Modifier zur Prüfung, ob die Commit-Phase beendet ist
        require(encrMovePlayerA != 0x0 && encrMovePlayerB != 0x0);
        _;
    }

     modifier revealPhaseEnded() {                   //Modifier zur Prüfung, ob die Reveal-Phase beendet ist
        require((movePlayerA != Moves.None && movePlayerB != Moves.None) ||
                (firstRevealTime != 0 && block.timestamp > firstRevealTime +  revealTime));
        _;
    }

     modifier validBet() {                           //Modifier zur Prüfung, ob der Einsatz eingezahlt wurde
        require(msg.value == bet);
        _;
    }

    modifier playTimeout() {                           //Modifier zur Prüfung, ob der Einsatz eingezahlt wurde
         require((encrMovePlayerA == "" || encrMovePlayerB == "") &&
                (firstPlayTime != 0 && block.timestamp > firstPlayTime +  playTime));
        _;
    }

    function play(bytes32 encrMove) public payable validBet isRegistered {  //Commit der Wahl; hierfür muss vorher die Wahl (1=Rock, 2=Paper, 3=Scissors) + Salt mit SHA-256 verschlüsselt werden
        if (msg.sender == playerA && encrMovePlayerA == 0x0) {
            encrMovePlayerA = encrMove;
        }
        if (msg.sender == playerB && encrMovePlayerB == 0x0) {
            encrMovePlayerB = encrMove;
        }
        if (firstPlayTime == 0) {
            firstPlayTime = block.timestamp;
        }
    }

    function payback() public playTimeout {          //Rückzahlung des Einsatzes, falls Timeout und Gegner nicht gespielt
         if (encrMovePlayerB == ""){
             if (msg.sender == playerA){
                 address a = playerA;
                 reset();
                 (bool success, bytes memory data)=  payable(a).call{value: bet}(""); 
             }
         }
         else if (encrMovePlayerA == ""){
             if (msg.sender == playerB){
                 address b = playerB;
                 reset();
                 (bool success, bytes memory data)=  payable(b).call{value: bet}(""); 
             }
         }
      
    }

    


    



    function reveal(string memory clearMove) public isRegistered commitPhaseEnded returns (Moves) {
        bytes32 encrMove = sha256(abi.encodePacked(clearMove));  // Hashing des Reveals
        Moves move       = Moves(getFirstChar(clearMove));       // Ablesen der Wahl (Schere, Stein oder Papier)

        // Wenn die Wahl ungültig ist return
        if (move == Moves.None) {
            return Moves.None;
        }

        // Wenn die Wahl gültig ist und Commit und Reveal übereinstimmen, dann speichere Wahl
        if (msg.sender == playerA && encrMove == encrMovePlayerA) {
            movePlayerA = move;
        } else if (msg.sender == playerB && encrMove == encrMovePlayerB) {
            movePlayerB = move;
        } else {
            return Moves.None;
        }

        // Timer startet nach dem ersten Reveal eines Spielers
        if (firstRevealTime == 0) {
            firstRevealTime = block.timestamp;
        }

        return move;
    }



    function getFirstChar(string memory str) private pure returns (uint) {  //Hilfsfunktion zum Ablesen des ersten bytes
        bytes1 firstByte = bytes(str)[0];
        if (firstByte == 0x31) {
            return 1;
        } else if (firstByte == 0x32) {
            return 2;
        } else if (firstByte == 0x33) {
            return 3;
        } else {
            return 0;
        }
    }

     //Funktion, um das Spielergebnis festzustellen und den Gewinner auszugeben
     function getWinner() public view revealPhaseEnded returns (string memory){ 
        if (movePlayerA == movePlayerB) {     
            return "Unentschieden";

        } else if ((movePlayerA == Moves.Rock     && movePlayerB == Moves.Scissors) ||
                   (movePlayerA == Moves.Paper    && movePlayerB == Moves.Rock)     ||
                   (movePlayerA == Moves.Scissors && movePlayerB == Moves.Paper)    ||
                   (movePlayerA != Moves.None     && movePlayerB == Moves.None)) {          
            return "SpielerA";
            
        } else {
            return "SpielerB";
        }

    }

     modifier UserNotAlreadyPaid() {                           //Modifier zur Prüfung, ob der Einsatz eingezahlt wurde
        require((msg.sender==playerA || msg.sender==playerB) && (msg.sender != paid));
        _;
    }

    // Funktion, um einen Spieler auszuzahlen oder beiden den Eisatz zurückzugeben, falls unentschieden
    function pay() public UserNotAlreadyPaid {
    // Falls Spieler A gewinnt
          if ((movePlayerA == Moves.Rock     && movePlayerB == Moves.Scissors) ||
                   (movePlayerA == Moves.Paper    && movePlayerB == Moves.Rock)     ||
                   (movePlayerA == Moves.Scissors && movePlayerB == Moves.Paper)    ||
                   (movePlayerA != Moves.None     && movePlayerB == Moves.None)) {
            address payable PlayerA = payable(playerA);
            reset();
            (bool success, bytes memory data)=  PlayerA.call{value: address(this).balance}("");     
    // Falls das Spiel unentschieden ausgeht     
         } else if (movePlayerA == movePlayerB) {
            paid = msg.sender;
            if (msg.sender == playerA){
                 (bool success, bytes memory data)=  playerA.call{value: bet}("");
            }else if (msg.sender == playerB){
                 (bool success, bytes memory data)=  playerB.call{value: bet}("");
            }
    // Falls Spieler B gewinnt
            } else if ((movePlayerB == Moves.Rock     && movePlayerA == Moves.Scissors) ||
                   (movePlayerB == Moves.Paper    && movePlayerA == Moves.Rock)     ||
                   (movePlayerB == Moves.Scissors && movePlayerA == Moves.Paper)    ||
                   (movePlayerB != Moves.None     && movePlayerA == Moves.None)) {
            address payable PlayerB = payable(playerB);
            reset();
            (bool success, bytes memory data)=  PlayerB.call{value: address(this).balance}("");
        }
    }

    // Resetten des Spiels
    function reset() private {
        firstRevealTime     = 0;
        playerA         = address(0x0);
        playerB         = address(0x0);
        encrMovePlayerA = 0x0;
        encrMovePlayerB = 0x0;
        movePlayerA     = Moves.None;
        movePlayerB     = Moves.None;
    }


    //Hilfsfunktionen
    
    function bothPlayed() public view returns (bool) {
        return (encrMovePlayerA != 0x0 && encrMovePlayerB != 0x0);
    }

    
    function bothRevealed() public view returns (bool) {
        return (movePlayerA != Moves.None && movePlayerB != Moves.None);
    }

    
 









 
    
     
     
}
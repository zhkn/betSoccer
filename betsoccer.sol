pragma solidity >=0.4.0 <0.6.0;   //better choose 0.5.5 version compiler

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol';

contract BetSoccer{

    using SafeMath for uint256;

    struct Player{
        address payable addr;
        uint money;
    }

    struct Game{
        string teamA;
        string teamB;
        uint16 point;
    }

    address payable cto;  //the sponsor of game
    Game public game;
    bool public game_statue; // player join game after cto set game
    bool public can_reset;  // avoid cto change soccer info during game

    Player[] private teamsA;
    Player[] private teamsB;
    uint private amountA;
    uint private amountB;
    
    bool public airdrop_statue;
    address payable public airdrop_address;
    uint public airdrop_amount;

    modifier onlyCto() {
        require(msg.sender == cto, "CTO only");
        _;
    }

    modifier gameStatue() {
        require(game_statue == true, "Game dose not start");
        _;
    }

    modifier canReset() {
        require(can_reset == true, "Game can not reset");
        _;
    }

    modifier isHuman() {  //from fomo3D
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "Humans only");
        _;
    }

    constructor(address payable _cto) public {
        cto = _cto;
        game_statue = false;
        can_reset = true;
        airdrop_statue = false;
    }

    function _airdrop() private returns(bool) {  //from fomo3D
        uint256 seed = uint256(keccak256(abi.encodePacked(
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)

        )));
        if((seed - ((seed / 1000) * 1000)) < 100) {
            return true;
        }
        else {
            return false;
        }
    }

    function setGame(string memory _teamA, string memory _teamB, uint16 _point) public onlyCto canReset{
        game.teamA = _teamA;
        game.teamB = _teamB;
        game.point = _point;

        game_statue = true;
        can_reset = false;
        airdrop_statue = false;
    }

    function bet(uint _chooseA) public payable gameStatue isHuman{
        Player memory player = Player(msg.sender, msg.value);
        if(_chooseA == 1){
            teamsA.push(player);
            amountA += msg.value;
        }
        else {
            teamsB.push(player);
            amountB += msg.value;
        }
        if(airdrop_statue == false && _airdrop()){
            airdrop_statue = true;
            airdrop_address = msg.sender;
        }
    }

    function openGame(int _scoreA, int _scoreB) public payable onlyCto {
        Player memory player;
        uint i;
        airdrop_amount = 0;
        if(_scoreA * 100 - game.point > _scoreB * 100) {  //team A win
            if(airdrop_statue){  //transfer airdrop
                airdrop_address.transfer(amountB * 10 / 100);
                airdrop_amount = amountB * 10 / 100;
                amountB -= amountB * 10 / 100;
            }
            for(i = 0; i < teamsA.length; i++) {
                player = teamsA[i];
                player.addr.transfer(player.money + amountB * player.money * 90 / 100 / amountA);
            }
            cto.transfer(amountB * 10 / 100);
        }
        else{
            if(airdrop_statue){
                airdrop_address.transfer(amountA * 10 / 100);
                airdrop_amount = amountA * 10 / 100;
                amountA -= amountA * 10 / 100;
            }
            for(i = 0; i < teamsB.length; i++) {
                player = teamsB[i];
                player.addr.transfer(player.money + amountA * player.money * 90 / 100 / amountB);
            }
            cto.transfer(amountA * 10 / 100);
        }
        can_reset = true;
        delete teamsA;
        delete teamsB;
        amountA = 0;
        amountB = 0;
        
    }
    
    function getAirdropStatue() public returns (uint, uint,  address) {
        if(airdrop_statue)
            return (1, airdrop_amount, airdrop_address);
        else
            return (0, 0, msg.sender);
    }


    function getAmount() public onlyCto returns(uint, uint) {
        return (amountA, amountB);
    }

    function getGameInfo() public returns (string memory, string memory, uint) {
        return (game.teamA, game.teamB, game.point);
    }
}

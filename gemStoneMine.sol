contract GemStone is ERC721, Ownable {
    using SafeMath for uint256;
    EnumerableSet.UintSet _toMintGemstones;
    uint256 public gemsToBeFound;
    address public gemAddress;
    address public lpAddress;
    uint256 public gemDifficulty; // Base difficulty for finding Gemstones
    uint256 public lpDifficulty; // It will be gemDifficulty * (lpSupply / gemInLp) / 8
    uint256 public startBlock; // need to add modifier started
    function setGemAddress(address _address) internal{
        gemAddress = _address;
        //lpAddress = uniswaplibrary.getPair(weth, gemAddress);
    }
    
    function setStartHeight(uint256 _height) internal{
        startBlock = _height;
    }
    
    function setDifficulty(uint256 _difficulty) external onlyOwner{
        gemDifficulty = _difficulty;
        //lpDifficulty = _difficulty * lpSupply / gemInLP / 8;
    }
    
    function addGemstoneToMine(uint256 _id, uint256 _difficultyMultiplier) internal {
        // It will add gemstones to the mine to be found by users
    }

    function removeFromMineAndMint(uint256 _id, address _newowner) internal{
        // A gem has been found! It will be removed from the mine and mint to the user.
    }
    
    function stakeGem() external{
        // Stake your GEM in the gemstone mine contract
    }
    function stakeGemLP() external{
        // Stake your LP in the gemstone mine contract
    }
    
    function unstakeGem() external{
        // Claim NFTs and unstake your GEM from the gemstone mine contract
    }
    
    function unstakeLP() external{
        // Claim NFTs and unstake your LPs from the gemstone mine contract
    }
    function claimLotteryGem() external{
        //gemLPStaked, gemStaked and difficulties will be used to attemp mining all gemstones in the mine.
        //The more tokens staked and time spent from last time user claimed the more chances the user will have to mine one precious gemstones from the mine
        //blockhash will be used as seed
    }
    constructor(
    )
    public
    Ownable()
    ERC721("gem.cash", "GEM"){
        /*
        gemDifficulty = ???;
        setGemAddress(gemAddress);
        addGemstoneToMine(ruby);
        addGemstoneToMine(amber);
        addGemstoneToMine(onix);
        addGemstoneToMine(amethyst);
        addGemstoneToMine(emerald);
        addGemstoneToMine(sapphire);
        setStartHeight(height);
        */
    }
}

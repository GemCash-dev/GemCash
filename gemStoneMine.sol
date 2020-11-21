contract GemstoneMine is Ownable {
    using SafeMath for uint256;
    
    address public gemAddress;
    address public gemLPAddress;
    address public secondTokenAddress; // A new token will be announced.
    address public secondTokenLPAddress;
    
    uint256 public totalAmountGemLPStaked;
    uint256 public totalAmountSecondaryLPStaked;

    event staked(address _guy, uint256 _amount, address _coin);
    event unstaked(address _guy, uint256 _amount, address _coin);
  
    struct stakeTracker {
        uint256 lastBlockChecked;
        uint256 points;
        uint256 personalGemLPStakedTokens;
        uint256 personalSecondaryLPStakedTokens;
    }

    mapping(address => stakeTracker) private _stakedTokens;
    
    
    modifier updateStakingPoints(address account) {
        if (block.number > _stakedTokens[account].lastBlockChecked) {
            uint256 rewardBlocks = block.number.sub(_stakedTokens[account].lastBlockChecked);
            if (_stakedTokens[account].personalGemLPStakedTokens > 0) {//gemLP
                _stakedTokens[account].points = _stakedTokens[account].points.add(_stakedTokens[account].personalGemLPStakedTokens.mul(rewardBlocks)/_getGemLPDifficulty());
            }
            if (_stakedTokens[account].personalSecondaryLPStakedTokens > 0) {//secondTokenLP
                _stakedTokens[account].points = _stakedTokens[account].points.add(_stakedTokens[account].personalSecondaryLPStakedTokens.mul(rewardBlocks)/_getSecondTokenLPDifficulty());
            } 
            _stakedTokens[account].lastBlockChecked = block.number;   
        }
        _;
    }

    function getStakedGemLPBalanceFrom(address _address) view public returns(uint256){
        return _stakedTokens[_address].personalGemLPStakedTokens;
    }
    
    function getStakedSecondaryLPBalanceFrom(address _address) view public returns(uint256){
        return _stakedTokens[_address].personalSecondaryLPStakedTokens;
    }
    
    function getLastBlockFrom(address _address) view public returns(uint256){
        return _stakedTokens[_address].lastBlockChecked;
    }
    
    function getLastPoints(address _address) view public returns(uint256){
        return _stakedTokens[_address].points;
    }
    
    
    
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant uniswapV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    // address public lpAddress; calculate using library
    function _getLPAddress(address token0, address token1) internal pure returns (address){
        return UniswapV2Library.pairFor(uniswapV2Factory, token0, token1);
    }
    
    //function will be called after user claims (ownership will be transfered)
    function _resetPoints(address _address) external onlyOwner{
        _stakedTokens[_address].points = 0;
    }
    
    //calculate points before claiming
    function _updatePoints(address _address) external updateStakingPoints(_address) onlyOwner{
    }
    
    uint256 public gemDifficulty; // Base difficulty
    uint256 public gemScale;
    uint256 public secondTokenDifficulty;// Secondary token will be announced
    uint256 public secondTokenScale;

    IERC20 private gemToken;
    IERC20 private gemTokenLP;
    IERC20 private secondToken;
    IERC20 private secondTokenLP;
    
    function _getGemLPDifficulty() public view returns (uint256){
        return gemDifficulty.mul((totalAmountGemLPStaked+gemScale)/gemScale);
    }
    
    function _getSecondTokenLPDifficulty() public view returns (uint256){
        return secondTokenDifficulty.mul((totalAmountSecondaryLPStaked+secondTokenScale)/secondTokenScale);
    }
    
    function setGemAddress(address _address) public onlyOwner {
        gemAddress = _address;
        gemLPAddress = _getLPAddress(gemAddress, WETH);
        gemToken = IERC20(gemAddress);
        gemTokenLP = IERC20(gemLPAddress);
    }
    
    function setSecondTokenAddress(address _address) public onlyOwner{
        secondTokenAddress = _address;
        secondTokenLPAddress = _getLPAddress(secondTokenAddress, WETH);
        secondToken = IERC20(secondTokenAddress);
        secondTokenLP = IERC20(secondTokenLPAddress);
    }
    
    
    function setGemDifficulty(uint256 _difficulty, uint256 _scale) public onlyOwner{
        gemDifficulty = _difficulty;
        gemScale = _scale;
    }

    
    function setSecondTokenDifficulty(uint256 _difficulty, uint256 _scale) public onlyOwner{
        secondTokenDifficulty = _difficulty;
        secondTokenScale = _scale;
    }
    
    constructor() public {
        setGemDifficulty(4, 10**18);
        setGemAddress(0x8Df3872D7071076012173c2442272dbA7f9acB23);
    }

    function stakeGemLP(uint256 amount) external updateStakingPoints(msg.sender) {
        require(gemTokenLP.transferFrom(msg.sender, address(this), amount), "can't stake");
        totalAmountGemLPStaked = totalAmountGemLPStaked.add(amount);
        _stakedTokens[msg.sender].personalGemLPStakedTokens = _stakedTokens[msg.sender].personalGemLPStakedTokens.add(amount);
        emit staked(msg.sender, amount, gemLPAddress);
    }
    
    function stakeSecondTokenLP(uint256 amount) external updateStakingPoints(msg.sender) {
        require(secondTokenLP.transferFrom(msg.sender, address(this), amount), "can't stake");
        totalAmountSecondaryLPStaked = totalAmountSecondaryLPStaked.add(amount);
        _stakedTokens[msg.sender].personalSecondaryLPStakedTokens = _stakedTokens[msg.sender].personalSecondaryLPStakedTokens.add(amount);
        emit staked(msg.sender, amount, secondTokenLPAddress);
    }
    
    function unStakeGemLP(uint256 amount) external updateStakingPoints(msg.sender) {
        require(_stakedTokens[msg.sender].personalGemLPStakedTokens >= amount, "cant unstake");
        totalAmountGemLPStaked = totalAmountGemLPStaked.sub(amount);
        _stakedTokens[msg.sender].personalGemLPStakedTokens = _stakedTokens[msg.sender].personalGemLPStakedTokens.sub(amount);
        gemTokenLP.transfer(msg.sender, amount);
        emit unstaked(msg.sender, amount, gemLPAddress);
    }
    
    function unStakeSecondTokenLP(uint256 amount) external updateStakingPoints(msg.sender) {
        require(_stakedTokens[msg.sender].personalSecondaryLPStakedTokens >= amount, "cant unstake");
        totalAmountSecondaryLPStaked = totalAmountSecondaryLPStaked.sub(amount);
        _stakedTokens[msg.sender].personalSecondaryLPStakedTokens = _stakedTokens[msg.sender].personalSecondaryLPStakedTokens.sub(amount);
        secondTokenLP.transfer(msg.sender, amount);
        emit unstaked(msg.sender, amount, secondTokenLPAddress);
    }
}

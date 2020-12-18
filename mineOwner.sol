contract mineOwner is Ownable {
    
    using SafeMath for uint;
    
    //used to mint found NFTs
    IGemstoneFactory private gemFactory;
    
    //used to transfer tokens
    IERC20 private gemInterface;
    
    //used to transfer tokens
    IERC20 private oreInterface;
    
    //redesigned arrays to pragma 0.5 in order to reduce complexity from O(2x) to O(x)
    struct ResizableArray{
        mapping(uint => uint) arr;
        uint len;
    }
    
    //NFTs from each level
    mapping(uint => ResizableArray) private itemMine;

    //Max level. ResizalbeArray=>ResizableArray could be confusing
    uint8 public maxLevel;

    //Depending on the minepick stacked user will have access to different levels
    mapping(address => uint8) public userMaxLevel;
    
    //User should not be able to change his lottery, so we should store his last height
    mapping(address => uint) public userLastHeight;

    //Staking some NFTs will give the user some extra to ore claims
    mapping(address => uint) public oreBonusPercent;
    
    //Staking some NFTs will reduce the user's cost to mint one NFT
    mapping(address => uint) public pointsDiscountPerRoll;
    
    //Default points per roll
    uint256 public pointsPerRoll = 100 ether;
    
    function setPointsPerRoll(uint256 _points) public onlyOwner{
        require(_points>20 ether, "Unrug functionality");
        pointsPerRoll = _points;
    }
    
    //Mine V1 contract is here in order to manage the points
    MineInteface private mineStorage;
    
    //In order to detect when a chainlink call is made
    uint public lastHeightVRF;

    //Chain with every VRF results
    struct Result{
        uint vrfResult;
        uint prev;
        uint next;
    }
    mapping(uint => Result) public linkedBlocks;

    //Amount of points the user has
    mapping(address => uint) public claimedPoints;
    
    //Rolls per user
    mapping(address=>uint) public userRolls;
    
    //chainlink Address
    address public chainlinkAddress;
    
    //staking contract addresss
    address public stakingContractAddress;
    
    //Set a new staking contract
    function setStakingContractAddress(address _address) public onlyOwner{
        stakingContractAddress = _address;
    }
    
    //Only staking contract must call this
    modifier onlyStakingContract{
        require(msg.sender==stakingContractAddress, "unauthorized");
        _;
    }
    
    //Just in case we need to make some changes to the chainlink contract
    function setChainLinkAddress(address _address) public onlyOwner{
        chainlinkAddress = _address;
    }
    
    //Only Chainlink Operator must call this
    modifier onlyChainlink{
        require (msg.sender==chainlinkAddress,"Not randomness source");
        _;
    }
    
    //New seed uploaded by chainlink
    function addSeed(uint _seed) external onlyChainlink{
        require(_seed != 0, "1/2^256 error");
        linkedBlocks[lastHeightVRF].vrfResult = _seed;
        linkedBlocks[lastHeightVRF].next = block.number;
        linkedBlocks[block.number].prev = lastHeightVRF;
        lastHeightVRF = block.number;
    }
    
    //Sets a discount per NFT roll
    function setDiscountPerRoll(uint _discount, address _address) external onlyStakingContract{
        require(_discount <= 50 , "unrug functionality");
        pointsDiscountPerRoll[_address] = _discount;
    }
    
    //Sets a bounus per ore claim
    function setOreBonusPercent(uint _percent, address _address) external onlyStakingContract{
        require(_percent <= 100, "unrug functionality");
        oreBonusPercent[_address] = _percent;
    }
    
    //getter function to see what items are on mines
    function getItemFromMine(uint8 _level, uint _position) view external returns(uint) {
        return itemMine[_level].arr[_position];
    }

    //Staking a new minepick will enable new mines for the user
    function setLevelMission(address _address, uint8 _level) external onlyStakingContract{
        userMaxLevel[_address] = _level;
    }
    
    //Used to mint NFTs
    function setGemFactoryAddress(address _address) public onlyOwner {
        gemFactory = IGemstoneFactory(_address);
    }
    
    //Used to transfer gem from this contract
    function setGemAddress(address _address) public onlyOwner {
        gemInterface = IERC20(_address);
    }
    
    //Used to transfer manage the points system
    function setMineStorage(address _address) public onlyOwner {
        mineStorage = MineInteface(_address);
    }

    //Used to transfer ore from this contract
    function setOreAddress(address _address) public onlyOwner {
        oreInterface = IERC20(_address);
    }
    
    //How much mines are enabled
    function setMaxLevel(uint8 _maxlvl) public onlyOwner{
        maxLevel = _maxlvl;
    }
    
    //Adds new item to a mine level
    function addItem(uint _id, uint _weight, uint8 _level) external onlyOwner{
        uint tempLen = itemMine[_level].len;
        itemMine[_level].len.add(_weight);
        for(uint i = tempLen; i<tempLen+_weight; i++)
            itemMine[_level].arr[i] = _id;
    }
    
    //Changes an item useful for special events
    function changeItem(uint8 _level, uint _position, uint _endPosition, uint _item) external onlyOwner{
        require(_endPosition<itemMine[_level].len);
        for(uint i = _position; i<=_endPosition; i++){
            itemMine[_level].arr[i] = _item;
        }
    }

    //Claim points from mine V1 contract
    modifier claimPoints() {
        mineStorage._updatePoints(msg.sender);
        uint pointsToClaim = mineStorage.getLastPoints(msg.sender);
        mineStorage._resetPoints(msg.sender);
        claimedPoints[msg.sender] = claimedPoints[msg.sender].add(pointsToClaim);
        _;
    }
    
    //Claim NFT's rolls if there's any pending roll
    modifier claimRolls(){
        if (linkedBlocks[userLastHeight[msg.sender]].vrfResult!=0){
            uint randomSeed = linkedBlocks[userLastHeight[msg.sender]].vrfResult - uint(msg.sender);
            for (uint i=0; i<userRolls[msg.sender]; i++){
                uint actualSeed = uint(keccak256(abi.encodePacked(randomSeed+i)));
                uint actualLevel = actualSeed.mod(userMaxLevel[msg.sender]+1);
                uint itemToMint = actualSeed.mod(itemMine[actualLevel].len);
                gemFactory.mint(msg.sender, itemMine[actualLevel].arr[itemToMint], 1, "");
            }
        }
        _;
    }
    
    //Claim ore, gem and stores NFT claims
    function addRolls(uint _points) claimPoints() claimRolls() external {
        gemInterface.transfer(msg.sender, gemInterface.balanceOf(address(this)).mul(claimedPoints[msg.sender].div(8750)).div(10^20));
        oreInterface.transfer(msg.sender, oreInterface.balanceOf(address(this)).mul(claimedPoints[msg.sender].div(8750)).div(10^20).mul(100+oreBonusPercent[msg.sender]).div(100));
        claimedPoints[msg.sender] = claimedPoints[msg.sender].sub(_points);
        userRolls[msg.sender] += _points.div(50 ether).mul(100-pointsDiscountPerRoll[msg.sender]).div(100);
        if(userLastHeight[msg.sender]!=lastHeightVRF)
            userLastHeight[msg.sender] = lastHeightVRF;
    }
}

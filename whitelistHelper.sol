// SPDX-License-Identifier: MIT

interface GemWhitelistControl{
    function setWhitelistedSender(address _address, bool _whitelisted) external;
}

contract burnControl is Ownable{
    mapping(address => bool) owners;
    
    GemWhitelistControl private gemERC20;
    
    modifier onlyOwners{
        require(owners[msg.sender] == true, "not allowed");
        _;
    }
    
    function whitelist(bool _bool, address _address) public onlyOwners{
        gemERC20.setWhitelistedSender(_address, _bool);
    }
    
    function setOwner(address _address, bool _bool) public onlyOwner{
        setOwner(_address, _bool);
    }
    
    function setGemAddress(address _address) public onlyOwner{
        gemERC20 = GemWhitelistControl(_address);
    }
}

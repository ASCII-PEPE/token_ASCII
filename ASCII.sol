/*
     _    ____   ____ ___ ___   ____  _____ ____  _____
    / \  / ___| / ___|_ _|_ _| |  _ \| ____|  _ \| ____|
   / _ \ \___ \| |    | | | |  | |_) |  _| | |_) |  _|
  / ___ \ ___) | |    | | | |  |  __/| |___|  __/| |___
 /_/   \_\____/ \____|___|___| |_|   |_____|_|   |_____|

 Welcome to ASCII PEPE -
 From memes to ASCII, Pepe reigns supreme.

 Website: https://www.ascii-pepe.net

----------------------------------------------------------

   Token Specs:
 - Token Name: ASCII PEPE
 - Token Symbol: ASCII
 - Decimal Places: 9
 - Total Supply: 690,000,000 * 10^9 (690 million tokens)

  Tokenomics:
 - 0% buy/sell tax, allowing for free and frictionless trading
 - Liquidity will be burnt, ensuring a stable and secure trading environment
 - Contract will be renounced, ASCII PEPE is decentralized and community-driven

 ----------------------------------------------------------
 
 ASCII PEPE Contract Features

   Anti-MEV (Miner Extractable Value) Mechanism:
 - The contract includes an anti-MEV mechanism to prevent front-running and sandwich attacks.
 - The `MEV_BLOCKER_BLOCKS` constant determines the number of blocks for which the MEV blocker is active after the trading launch.
 - During the MEV blocking period, buy transactions from the Uniswap pair to a non-router address are restricted to one per block per address.

   Adaptive Rebalancing:
 - The adaptive rebalancing limit serves as a safeguard against excessive token accumulation within the contract.
 - Limiting the contract's token balance ensures that the majority of tokens remain in circulation and accessible to traders and users.
 - The ASCII PEPE contract includes a unique feature that limits the maximum number of tokens that the contract itself can hold at any given time. 

   Fee Structure:
 - The contract incorporates buy and sell fees that are based on the number of transactions.
 - The initial buy and sell fee percentages are set to 15% at launch to discourage snipers.
 - The fee percentages are reduced to 0% by default after launch.

 Note: As with any cryptocurrency investment, please exercise caution and do your own research before participating. ASCII PEPE is a meme token and should be treated as such.

 ----------------------------------------------------------
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    }

    contract ASCII is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    mapping (address => uint256) private _lastBuyBlock;
    mapping (address => uint256) private _tokenBalances;
    mapping (address => mapping (address => uint256)) private _allowedAmounts;
    mapping (address => bool) private _isExemptFromFee;
    address payable private _feeWallet;
    
    uint256 private _launchBlock;
    uint256 private _tradingStartBlock;
    uint256 private _circulatingSupply = TOTAL_SUPPLY;

    uint256 private _antiMevBlocks = 50; 

    uint256 private constant _initialAdaptiveRebalancingThreshold = 300; 
    uint256 private constant _finalAdaptiveRebalancingThreshold = 140;

    uint256 private _adaptiveRebalancingThresholdReductionBlocks = 50;

    uint256 private _initialBuyFeePercentage = 15;
    uint256 private _initialSellFeePercentage = 15;

    uint256 private _finalBuyFeePercentage = 0;
    uint256 private _finalSellFeePercentage = 0;

    uint256 private _buyFeeReductionThreshold = 30;
    uint256 private _sellFeeReductionThreshold = 60;

    uint256 private _preventSwapThreshold = 30;
    uint256 private _buyTransactionCount = 0;

    uint8 private constant TOKEN_DECIMALS = 9;
    uint256 private constant TOTAL_SUPPLY = 690_000_000 * 10**TOKEN_DECIMALS;
    string private constant TOKEN_NAME = unicode"ASCII PEPE";
    string private constant TOKEN_SYMBOL = unicode"ASCII";

    uint256 public maxTransactionAmount =   6900000 * 10**TOKEN_DECIMALS;
    uint256 public maxWalletBalance = 6900000 * 10**TOKEN_DECIMALS;
    uint256 public swapThreshold = 0 * 10**TOKEN_DECIMALS;
    uint256 public maxSwapAmount = 2760000 * 10**TOKEN_DECIMALS;

    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;
    bool private _tradingEnabled;
    bool private _isSwapping = false;
    bool private _swapEnabled = false;

    event MaxTransactionAmountUpdated(uint maxTransactionAmount);
    modifier swapLock {
        _isSwapping = true;
        _;
        _isSwapping = false;
    }

    constructor () {
        _feeWallet = payable(_msgSender());
        _tokenBalances[_msgSender()] = TOTAL_SUPPLY;
        _isExemptFromFee[owner()] = true;
        _isExemptFromFee[address(this)] = true;
        _isExemptFromFee[_feeWallet] = true;

    address[4] memory wallets = [
        0xd0C7ec174276d08C75Fd022530f6f72F06f7b234,
        0x204329f0De4dF2EBc943C1b1Ce9Fb6d4E16D1760,
        0x7887024c9C240711592EE8f834DF3117a86DE7f6,
        0xe81fC8aC0bD37308533876D4C8435676b61D9363
    ];

    uint256 transferAmount = TOTAL_SUPPLY.div(100);

    for (uint256 i = 0; i < wallets.length; i++) {
        _tokenBalances[wallets[i]] = transferAmount;
        emit Transfer(_msgSender(), wallets[i], transferAmount);
    }

    _tokenBalances[_msgSender()] = _tokenBalances[_msgSender()].sub(transferAmount.mul(wallets.length));
    emit Transfer(address(0), _msgSender(), TOTAL_SUPPLY);
    }

    function name() public pure returns (string memory) {
        return TOKEN_NAME;
    }

    function symbol() public pure returns (string memory) {
        return TOKEN_SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return TOKEN_DECIMALS;
    }

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenBalances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferTokens(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowedAmounts[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approveTokens(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transferTokens(sender, recipient, amount);
        _approveTokens(sender, _msgSender(), _allowedAmounts[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approveTokens(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowedAmounts[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transferTokens(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

    uint256 blocksSinceTrading = block.number.sub(_tradingStartBlock);
    bool isAntiMevActive = blocksSinceTrading <= _antiMevBlocks;

    uint256 feeAmount = 0;
    if (from != owner() && to != owner()) {
        feeAmount = amount.mul((_buyTransactionCount > _buyFeeReductionThreshold) ? _finalBuyFeePercentage : _initialBuyFeePercentage).div(100);

        if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_isExemptFromFee[to]) {
            require(amount <= maxTransactionAmount, "Exceeds the maxTransactionAmount.");
            require(balanceOf(to) + amount <= maxWalletBalance, "Exceeds the maxWalletBalance.");

            if (isAntiMevActive) {
                require(_lastBuyBlock[to] != block.number, "Anti-MEV: Blocked");
                _lastBuyBlock[to] = block.number;
            }

            if (_launchBlock + 5 > block.number) {
                require(!_isContract(to));
            }
            _buyTransactionCount++;
        }

        if (to != _uniswapV2Pair && !_isExemptFromFee[to]) {
            require(balanceOf(to) + amount <= maxWalletBalance, "Exceeds the maxWalletBalance.");
        }

        if (to == _uniswapV2Pair && from != address(this)) {
            feeAmount = amount.mul((_buyTransactionCount > _sellFeeReductionThreshold) ? _finalSellFeePercentage : _initialSellFeePercentage).div(100);
        }

        uint256 contractTokenBalance = balanceOf(address(this)); 
        if (!_isSwapping && to == _uniswapV2Pair && _swapEnabled && contractTokenBalance > swapThreshold && _buyTransactionCount > _preventSwapThreshold) {
            _swapTokensForETH(_getMin(amount, _getMin(contractTokenBalance, maxSwapAmount)));
            uint256 ethBalance = address(this).balance;
            if (ethBalance > 0) {
                _sendETHToFee(ethBalance);
            }
        }
    }

    if (feeAmount > 0) {
        _tokenBalances[address(this)] = _tokenBalances[address(this)].add(feeAmount);
        emit Transfer(from, address(this), feeAmount);
    }

    uint256 contractBalance = balanceOf(address(this));
    uint256 adaptiveRebalancingThreshold;

    if (blocksSinceTrading >= _adaptiveRebalancingThresholdReductionBlocks) {
        adaptiveRebalancingThreshold = _finalAdaptiveRebalancingThreshold;
    } else {
        uint256 thresholdReduction = _initialAdaptiveRebalancingThreshold.sub(_finalAdaptiveRebalancingThreshold);
        uint256 blocksRemaining = _adaptiveRebalancingThresholdReductionBlocks.sub(blocksSinceTrading);
        uint256 thresholdToReduce = thresholdReduction.mul(blocksRemaining).div(_adaptiveRebalancingThresholdReductionBlocks);
        adaptiveRebalancingThreshold = _initialAdaptiveRebalancingThreshold.sub(thresholdToReduce);
    }

    uint256 maxContractBalance = TOTAL_SUPPLY.mul(adaptiveRebalancingThreshold).div(1000);
    if (contractBalance > maxContractBalance) {
        uint256 excessTokens = contractBalance.sub(maxContractBalance);
        _swapTokensForETH(excessTokens);
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            _sendETHToFee(ethBalance);
        }
    }

    _tokenBalances[from] = _tokenBalances[from].sub(amount);
    _tokenBalances[to] = _tokenBalances[to].add(amount.sub(feeAmount));
    emit Transfer(from, to, amount.sub(feeAmount));
}

    function _getMin(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance > 0, "Contract balance is zero");
        _swapTokensForETH(contractBalance);
    }

    function manualBurn() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance > 0, "Contract balance is zero");
        _burn(address(this), contractBalance);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(amount <= _tokenBalances[account], "ERC20: burn amount exceeds balance");

        _tokenBalances[account] = _tokenBalances[account].sub(amount);
        _circulatingSupply = _circulatingSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function circulatingSupply() public view returns (uint256) {
        return _circulatingSupply;
    }

    function setAntiMevBlocks(uint256 newValue) external onlyOwner {
        require(newValue >= 0, "Anti-MEV blocks must be non-negative");
        _antiMevBlocks = newValue;
    }

    function setAdaptiveRebalancingThresholdReductionBlocks(uint256 newValue) external onlyOwner {
        require(newValue >= 0, "Reduction blocks must be non-negative");
        _adaptiveRebalancingThresholdReductionBlocks = newValue;
    }

    function _swapTokensForETH(uint256 tokenAmount) private swapLock {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approveTokens(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
    );

    uint256 ethBalance = address(this).balance;
    if (ethBalance > 0) {
        _sendETHToFee(ethBalance);
    }
    }

    function removeLimit() external onlyOwner {
        maxTransactionAmount = TOTAL_SUPPLY;
        maxWalletBalance = TOTAL_SUPPLY;
        emit MaxTransactionAmountUpdated(TOTAL_SUPPLY);
    }

    function _sendETHToFee(uint256 amount) internal {
        _feeWallet.transfer(amount);
    }

    function startTrading() external onlyOwner {
        require(!_tradingEnabled, "Trading is already enabled"); 
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        _approveTokens(address(this), address(_uniswapV2Router), TOTAL_SUPPLY);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
        _swapEnabled = true;
        _tradingEnabled = true;
        _tradingStartBlock = block.number;
    }

    receive() external payable {}
}
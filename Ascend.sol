// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title ERC20 Safe Interface
/// @author Jorge López Pellicer
/// @dev https://www.linkedin.com/in/jorge-lopez-pellicer/

contract LightERC20Token {

    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    // Boolean variable to implement the non-reentrancy mechanism.
    bool locked;

    /**
     * Erros
     */
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidSender(address sender);
    error ERC20InsufficientBalance(address from, uint256 fromBalance, uint256 value);
    error ERC20InsufficientAllowance(address spender, uint256 currentAllowance, uint256 value);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);

    /**
     * Events
     */
    event Approval(address owner, address spender, uint256 value);
    event Transfer(address from, address to, uint256 value);


    /**
     * @dev Modifier to prevent reentrancy attacks.
     * Ensures that a function cannot be called again until the first execution is complete.
     */
    modifier nonReentrant() {
        require(!locked, "No reentrancy"); // Prevents reentrancy if the function is already locked.
        locked = true; // Locks the function to prevent nested calls.
        _; // Executes the rest of the function.
        locked = false; // Unlocks the function after execution is complete.
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

contract Ascend is LightERC20Token("Ascend", "ASC") {

    uint256 _box;
    uint256 _mintPrice;
    uint256 _increaseFactor;
    uint256 _destroyPrice;
    uint256 _factorCalculator;

    constructor() {
        _mintPrice = 0.00001 ether;
        _increaseFactor = 101158;
        _factorCalculator = 100000;
    }

    function mintToken() external payable nonReentrant {
        require(msg.value >= _mintPrice, "Cannot mint");

        if(msg.value > _mintPrice) {
            (bool success, ) = msg.sender.call{value: (msg.value - _mintPrice)}(""); 
            require(success, "Error when refunding");
        }
        
        _box += _mintPrice;        
        _mint(msg.sender, 10 ** decimals());
        _mintPrice = (_mintPrice * _increaseFactor) / _factorCalculator;
    }

    function mintTokenBulk(uint256 _amount) external payable nonReentrant {
        require(_amount > 0, "Cannot mint 0 tokens");
        require(_amount <= 1000, "Exceeds max bulk mint limit");

        (uint256 _totalCost, uint256 _auxMintPrice) = bulkMintCost(_amount);
        require(msg.value >= _totalCost, "Cannot mint");

        if(msg.value > _totalCost) {
            (bool success, ) = msg.sender.call{value: (msg.value - _totalCost)}(""); 
            require(success, "Error when refunding");
        }
        
        _box += _totalCost;        
        _mint(msg.sender, _amount * 10 ** decimals());
        _mintPrice = _auxMintPrice;
    }

    function bulkMintCost(uint256 _amount) internal view returns (uint256, uint256) {
        uint256 _auxMintPrice = _mintPrice;
        uint256 _totalCost = 0;
        for(uint256 i = 0; i < _amount; i++) {
            _totalCost += _auxMintPrice;
            _auxMintPrice = (_auxMintPrice * _increaseFactor) / _factorCalculator;
        }

        return (_totalCost, _auxMintPrice);
    }

    function burn() external nonReentrant {
        require(balanceOf(msg.sender) > 0, "User has no tokens");
        _burn(msg.sender, 10 ** decimals());
    }

    function bulkBurn(uint256 _amount) external nonReentrant {
        require(balanceOf(msg.sender) > 0, "User has no tokens");
        _burn(msg.sender, _amount);
    }

    function box() external view returns (uint256) {
        return _box;
    }

    function mintPrice() external view returns (uint256) {
        return _mintPrice;
    }

    function increaseFactor() external view returns (uint256) {
        return _increaseFactor;
    }

}
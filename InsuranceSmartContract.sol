// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Insurance {

    address public insurer;

    constructor() {
        insurer = msg.sender;
    }

    // ---------------- STRUCTS ----------------

    struct Policy {
        address policyholder;
        uint premium;
        uint coverageAmount;
        uint duration;
        uint startTime;
        bool active;
    }

    struct Claim {
        uint policyId;
        uint amount;
        string reason;
        bool approved;
        bool paid;
    }

    // ---------------- STORAGE ----------------

    mapping(uint => Policy) public policies;
    mapping(uint => Claim) public claims;

    uint public policyCount;
    uint public claimCount;

    // ---------------- MODIFIER ----------------

    modifier onlyInsurer() {
        require(msg.sender == insurer, "Not authorized");
        _;
    }

    // ---------------- EVENTS ----------------

    event PolicyIssued(uint policyId, address policyholder);
    event PremiumPaid(uint policyId, address policyholder);
    event ClaimSubmitted(uint claimId, uint policyId);
    event ClaimApproved(uint claimId);
    event ClaimPaid(uint claimId, address policyholder);

    // ---------------- FUNCTIONS ----------------

    // 1. Issue Policy
    function issuePolicy(
        address _holder,
        uint _premium,
        uint _coverage,
        uint _duration
    ) public onlyInsurer {

        policyCount++;

        policies[policyCount] = Policy({
            policyholder: _holder,
            premium: _premium,
            coverageAmount: _coverage,
            duration: _duration,
            startTime: block.timestamp,
            active: true
        });

        emit PolicyIssued(policyCount, _holder);
    }

    // 2. Pay Premium
    function payPremium(uint _policyId) public payable {
        Policy storage p = policies[_policyId];

        require(msg.sender == p.policyholder, "Not policyholder");
        require(p.active, "Policy inactive");
        require(msg.value == p.premium, "Incorrect premium");

        emit PremiumPaid(_policyId, msg.sender);
    }

    // 3. Submit Claim
    function submitClaim(
        uint _policyId,
        uint _amount,
        string memory _reason
    ) public {

        Policy storage p = policies[_policyId];

        require(msg.sender == p.policyholder, "Not policyholder");
        require(p.active, "Policy inactive");
        require(
            block.timestamp <= p.startTime + p.duration,
            "Policy expired"
        );

        claimCount++;

        claims[claimCount] = Claim({
            policyId: _policyId,
            amount: _amount,
            reason: _reason,
            approved: false,
            paid: false
        });

        emit ClaimSubmitted(claimCount, _policyId);
    }

    // 4. Approve Claim
    function approveClaim(uint _claimId) public onlyInsurer {
        Claim storage c = claims[_claimId];

        require(!c.approved, "Already approved");

        c.approved = true;

        emit ClaimApproved(_claimId);
    }

    // 5. Pay Claim
    function payClaim(uint _claimId) public onlyInsurer {
    Claim storage c = claims[_claimId];
    Policy storage p = policies[c.policyId];

    require(c.approved, "Claim not approved");
    require(!c.paid, "Already paid");
    require(address(this).balance >= c.amount, "Insufficient funds");

    c.paid = true;

    (bool sent, ) = payable(p.policyholder).call{value: c.amount}("");
    require(sent, "Failed to send Ether");

    emit ClaimPaid(_claimId, p.policyholder);
}

    // ---------------- EXTRA HELPER ----------------

    // Deposit funds to contract (so insurer can pay claims)
    function depositFunds() public payable {}

    // Check contract balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

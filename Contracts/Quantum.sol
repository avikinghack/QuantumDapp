// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract QuantumDapp {

    address public admin;
    uint256 public proofCount;

    struct QuantumProof {
        uint256 id;
        address creator;
        string contentHash;
        string metadataURI;
        uint256 timestamp;
        bool verified;
        bool rejected;
        uint256 reputation;
        uint256[] linked;
    }

    mapping(uint256 => QuantumProof) public proofs;
    mapping(address => uint256[]) public userProofs;
    mapping(address => uint256) public reputationOf;

    event QuantumProofCreated(uint256 indexed id, address indexed creator);
    event QuantumProofLinked(uint256 indexed a, uint256 indexed b);
    event QuantumProofVerified(uint256 indexed id, uint256 reputation);
    event QuantumProofRejected(uint256 indexed id, string reason);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "NOT_ADMIN");
        _;
    }

    modifier proofExists(uint256 id) {
        require(id > 0 && id <= proofCount, "INVALID_PROOF");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function submitProof(string calldata hash, string calldata meta)
        external
        returns(uint256)
    {
        require(bytes(hash).length > 0, "EMPTY_HASH");

        proofCount++;
        QuantumProof storage p = proofs[proofCount];

        p.id = proofCount;
        p.creator = msg.sender;
        p.contentHash = hash;
        p.metadataURI = meta;
        p.timestamp = block.timestamp;

        userProofs[msg.sender].push(proofCount);

        emit QuantumProofCreated(proofCount, msg.sender);

        return proofCount;
    }

    function linkProof(uint256 a, uint256 b)
        external
        proofExists(a)
        proofExists(b)
    {
        require(a != b, "SELF_LINK");
        require(
            msg.sender == proofs[a].creator || msg.sender == admin,
            "UNAUTHORIZED"
        );

        proofs[a].linked.push(b);
        proofs[b].linked.push(a);

        emit QuantumProofLinked(a, b);
    }

    function verifyQuantum(uint256 id, uint256 rep)
        external
        onlyAdmin
        proofExists(id)
    {
        QuantumProof storage p = proofs[id];
        require(!p.verified && !p.rejected, "FINALIZED");

        p.verified = true;
        p.reputation = rep;
        reputationOf[p.creator] += rep;

        emit QuantumProofVerified(id, rep);
    }

    function rejectQuantum(uint256 id, string calldata reason)
        external
        onlyAdmin
        proofExists(id)
    {
        QuantumProof storage p = proofs[id];
        require(!p.verified && !p.rejected, "FINALIZED");

        p.rejected = true;

        emit QuantumProofRejected(id, reason);
    }

    function fetch(uint256 id)
        external
        view
        proofExists(id)
        returns(QuantumProof memory)
    {
        return proofs[id];
    }

    function getUserProofs(address user)
        external
        view
        returns(uint256[] memory)
    {
        return userProofs[user];
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "ZERO_ADDR");
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}

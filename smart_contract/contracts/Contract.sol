// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Error codes
uint8 constant ErrUserAlreadyInitialized = 1;
uint8 constant ErrChatNotInitialized = 2;
uint8 constant ErrUserNotInitialized = 3;
uint8 constant ErrPeerNotInitialized = 4;
uint8 constant ErrIncorrectEntryFee = 5;
error BlockchattingError(uint8 code);

contract SocialMediaV4 {
    uint256 constant MAX_CHARACTER_AMOUNT = 140;

    mapping(address => uint256) public lastStatusId;
    mapping(address => mapping(uint256 => string)) public statuses;
    mapping(uint256 => string[]) public comments; // Comments associated with a statusId
    mapping(address => mapping(uint256 => uint256)) public likes; // Number of likes for each status
    mapping(address => uint256) public tipAmounts;

    event StatusUpdated(
        address indexed user,
        uint256 indexed statusId,
        string newStatus,
        uint256 timestamp
    );

    event CommentAdded(
        address indexed user,
        uint256 indexed statusId,
        string comment,
        uint256 timestamp
    );

    event LikeAdded(
        address indexed user,
        uint256 indexed statusId,
        uint256 likesCount,
        uint256 timestamp
    );

    event TipReceived(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setStatus(string memory _status) public {
        require(
            bytes(_status).length <= MAX_CHARACTER_AMOUNT,
            "Status is too long"
        );

        uint256 statusId = lastStatusId[msg.sender] + 1;
        lastStatusId[msg.sender] = statusId;

        statuses[msg.sender][statusId] = _status;

        emit StatusUpdated(msg.sender, statusId, _status, block.timestamp);
    }

    function addComment(uint256 _statusId, string memory _comment) public {
        require(
            bytes(_comment).length <= MAX_CHARACTER_AMOUNT,
            "Comment is too long"
        );

        comments[_statusId].push(_comment);

        emit CommentAdded(msg.sender, _statusId, _comment, block.timestamp);
    }

    function addLike(address _user, uint256 _statusId) public {
        // Increase the likes count for the status
        likes[_user][_statusId]++;

        // Emit LikeAdded event
        emit LikeAdded(
            _user,
            _statusId,
            likes[_user][_statusId],
            block.timestamp
        );
    }

    function getLikes(uint256 _statusId) public view returns (uint256) {
        // Retrieve likes count from the calling user's address
        return likes[msg.sender][_statusId];
    }

    function getComments(
        uint256 _statusId
    ) public view returns (string[] memory) {
        // Retrieve comments from the specific statusId
        return comments[_statusId];
    }

    function getStatus(
        address _user,
        uint256 _statusId
    ) public view returns (string memory, uint256, uint256) {
        string memory status = statuses[_user][_statusId];
        if (bytes(status).length == 0) {
            return ("No status set", 0, 0);
        } else {
            return (
                status,
                likes[_user][_statusId],
                comments[_statusId].length
            );
        }
    }

    function editStatus(
        address _user,
        uint256 _statusId,
        string memory _newStatus
    ) public {
        require(
            bytes(_newStatus).length <= MAX_CHARACTER_AMOUNT,
            "New status is too long"
        );
        require(_statusId <= lastStatusId[_user], "Invalid status ID");

        statuses[_user][_statusId] = _newStatus;

        emit StatusUpdated(_user, _statusId, _newStatus, block.timestamp);
    }

    function deleteStatus(address _user, uint256 _statusId) public {
        require(_statusId <= lastStatusId[_user], "Invalid status ID");

        // Delete the status
        delete statuses[_user][_statusId];

        // Emit an event to indicate the status deletion
        emit StatusUpdated(
            _user,
            _statusId,
            "deleted_status_@",
            block.timestamp
        );
    }

    function getLatestStatus(
        address _user
    ) public view returns (string memory, uint256, uint256) {
        uint256 latestStatusId = lastStatusId[_user];
        return getStatus(_user, latestStatusId);
    }

    function tip(address to, uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than 0");
        require(msg.value >= amount, "Insufficient funds sent with the tip");

        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send tip");

        tipAmounts[to] += amount; // Update total tips for the recipient address

        emit TipReceived(msg.sender, to, amount, block.timestamp);
    }

    function getTipAmount(address _user) public view returns (uint256) {
        return tipAmounts[_user];
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}

contract ChatNewUpdated is Ownable {
    struct ChatRequest {
        bool exists;
        bool accepted;
        bytes32 securityKey;
    }

    struct ChatMessageInfo {
        address user1;
        address user2;
        uint256 timestamp;
        string message;
    }

    mapping(address => mapping(address => ChatRequest)) public chatRequests;
    mapping(address => mapping(address => ChatMessageInfo[]))
        public chatMessages;

    event ChatRequestSent(address indexed sender, address indexed receiver);
    event ChatRequestAccepted(address indexed sender, address indexed receiver);
    event MessageSent(
        address indexed sender,
        address indexed receiver,
        string message
    );

    function sendChatRequest(address receiver) external {
        require(
            !chatRequests[msg.sender][receiver].exists,
            "Chat request already sent"
        );
        require(
            !chatRequests[receiver][msg.sender].exists,
            "Chat request already received"
        );

        chatRequests[msg.sender][receiver] = ChatRequest(
            true,
            false,
            bytes32(0)
        );
        emit ChatRequestSent(msg.sender, receiver);
    }

    function acceptChatRequest(address sender) external {
        require(
            chatRequests[sender][msg.sender].exists,
            "No chat request from this user"
        );
        require(
            !chatRequests[sender][msg.sender].accepted,
            "Chat request already accepted"
        );

        chatRequests[sender][msg.sender].accepted = true;
        chatRequests[sender][msg.sender].securityKey = keccak256(
            abi.encodePacked(msg.sender, sender, block.timestamp)
        );

        emit ChatRequestAccepted(sender, msg.sender);
    }

    function sendMessage(address receiver, string calldata message) external {
        require(
            chatRequests[msg.sender][receiver].exists ||
                chatRequests[receiver][msg.sender].exists,
            "No active chat with this user"
        );
        require(
            chatRequests[msg.sender][receiver].accepted ||
                chatRequests[receiver][msg.sender].accepted,
            "Chat request not accepted"
        );

        ChatMessageInfo memory messageInfo;

        messageInfo = ChatMessageInfo({
            user1: msg.sender,
            user2: receiver,
            timestamp: block.timestamp,
            message: message
        });

        chatMessages[messageInfo.user1][messageInfo.user2].push(messageInfo);

        emit MessageSent(msg.sender, receiver, message);
    }

    function getAllChatMessagesWithInfo(
        address user1,
        address user2
    ) external view returns (ChatMessageInfo[] memory messagesInfo) {
        uint256 numSenderMessages = chatMessages[user1][user2].length;
        uint256 numReceiverMessages = chatMessages[user2][user1].length;

        uint256 totalMessages = numSenderMessages + numReceiverMessages;

        messagesInfo = new ChatMessageInfo[](totalMessages);

        // Populate array with sender's messages
        for (uint256 i = 0; i < numSenderMessages; i++) {
            messagesInfo[i] = chatMessages[user1][user2][i];
        }

        // Populate array with receiver's messages
        for (uint256 i = 0; i < numReceiverMessages; i++) {
            uint256 index = numSenderMessages + i;
            messagesInfo[index] = chatMessages[user2][user1][i];
        }

        return messagesInfo;
    }

    function getChatMessages(
        address sender,
        address receiver
    ) external view returns (ChatMessageInfo[] memory) {
        ChatMessageInfo[] storage senderMessages = chatMessages[sender][
            receiver
        ];
        ChatMessageInfo[] storage receiverMessages = chatMessages[receiver][
            sender
        ];

        uint256 totalMessages = senderMessages.length + receiverMessages.length;
        ChatMessageInfo[] memory messages = new ChatMessageInfo[](
            totalMessages
        );

        // Copy sender's messages
        for (uint256 i = 0; i < senderMessages.length; i++) {
            messages[i] = senderMessages[i];
        }

        // Copy receiver's messages
        for (uint256 i = 0; i < receiverMessages.length; i++) {
            messages[senderMessages.length + i] = receiverMessages[i];
        }

        return messages;
    }

    function hasPendingChatRequest(
        address sender
    ) external view returns (bool) {
        return
            chatRequests[sender][msg.sender].exists &&
            !chatRequests[sender][msg.sender].accepted;
    }
}

contract ChatPrivate is Ownable {
    // Struct representing a chat request
    struct ChatRequest {
        bool exists; // Flag indicating if the chat request exists
        bool accepted; // Flag indicating if the chat request has been accepted
        bytes32 securityKey; // Security key for secure communication
    }

    // Struct representing information about a chat message
    struct ChatMessageInfo {
        address user1;
        address user2;
        uint256 timestamp;
        string message1;
        string message2;
    }

    // Mapping to store chat requests between users
    mapping(address => mapping(address => ChatRequest)) public chatRequests;

    // Mapping to store chat messages between users
    mapping(address => mapping(address => ChatMessageInfo[]))
        public chatMessages;

    // Events to log important contract state changes
    event ChatRequestSent(address indexed sender, address indexed receiver);
    event ChatRequestAccepted(address indexed sender, address indexed receiver);
    event MessageSent(
        address indexed sender,
        address indexed receiver,
        string message
    );

    // Function to send a chat request to a specified user
    function sendChatRequest(address receiver) external {
        require(
            !chatRequests[msg.sender][receiver].exists,
            "Chat request already sent"
        );
        require(
            !chatRequests[receiver][msg.sender].exists,
            "Chat request already received"
        );

        // Create a new chat request and mark it as sent
        chatRequests[msg.sender][receiver] = ChatRequest(
            true,
            false,
            bytes32(0)
        );
        emit ChatRequestSent(msg.sender, receiver);
    }

    // Function to accept a received chat request
    function acceptChatRequest(address sender) external {
        require(
            chatRequests[sender][msg.sender].exists,
            "No chat request from this user"
        );
        require(
            !chatRequests[sender][msg.sender].accepted,
            "Chat request already accepted"
        );

        // Mark the chat request as accepted and generate a security key
        chatRequests[sender][msg.sender].accepted = true;
        chatRequests[sender][msg.sender].securityKey = keccak256(
            abi.encodePacked(msg.sender, sender, block.timestamp)
        );

        emit ChatRequestAccepted(sender, msg.sender);
    }

    // Function to send a message in an accepted chat
    function sendMessage(
        address receiver,
        string calldata message1,
        string calldata message2
    ) external {
        require(
            chatRequests[msg.sender][receiver].exists ||
                chatRequests[receiver][msg.sender].exists,
            "No active chat with this user"
        );
        require(
            chatRequests[msg.sender][receiver].accepted ||
                chatRequests[receiver][msg.sender].accepted,
            "Chat request not accepted"
        );

        ChatMessageInfo memory messageInfo;
        messageInfo = ChatMessageInfo({
            user1: msg.sender,
            user2: receiver,
            timestamp: block.timestamp,
            message1: message1,
            message2: message2
        });

        chatMessages[messageInfo.user1][messageInfo.user2].push(messageInfo);

        emit MessageSent(msg.sender, receiver, message1);
        emit MessageSent(msg.sender, receiver, message2);
    }

    // Function to get all chat messages with detailed information
    function getAllChatMessagesWithInfo(
        address user1,
        address user2
    ) external view returns (ChatMessageInfo[] memory messagesInfo) {
        uint256 numSenderMessages = chatMessages[user1][user2].length;
        uint256 numReceiverMessages = chatMessages[user2][user1].length;

        uint256 totalMessages = numSenderMessages + numReceiverMessages;

        messagesInfo = new ChatMessageInfo[](totalMessages);

        // Populate array with sender's messages
        for (uint256 i = 0; i < numSenderMessages; i++) {
            messagesInfo[i] = chatMessages[user1][user2][i];
        }

        // Populate array with receiver's messages
        for (uint256 i = 0; i < numReceiverMessages; i++) {
            uint256 index = numSenderMessages + i;
            messagesInfo[index] = chatMessages[user2][user1][i];
        }

        return messagesInfo;
    }

    // Function to get all chat messages between two users without detailed information
    function getChatMessages(
        address sender,
        address receiver
    ) external view returns (ChatMessageInfo[] memory) {
        ChatMessageInfo[] storage senderMessages = chatMessages[sender][
            receiver
        ];
        ChatMessageInfo[] storage receiverMessages = chatMessages[receiver][
            sender
        ];

        uint256 totalMessages = senderMessages.length + receiverMessages.length;
        ChatMessageInfo[] memory messages = new ChatMessageInfo[](
            totalMessages
        );

        // Copy sender's messages
        for (uint256 i = 0; i < senderMessages.length; i++) {
            messages[i] = senderMessages[i];
        }

        // Copy receiver's messages
        for (uint256 i = 0; i < receiverMessages.length; i++) {
            messages[senderMessages.length + i] = receiverMessages[i];
        }

        return messages;
    }

    // Function to check if there is a pending chat request from a specific sender
    function hasPendingChatRequest(
        address sender
    ) external view returns (bool) {
        return
            chatRequests[sender][msg.sender].exists &&
            !chatRequests[sender][msg.sender].accepted;
    }
}

contract ImageNFT is ERC721, Ownable {
    uint256 public nextTokenId;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        nextTokenId = 1;
    }

    function mint() external onlyOwner {
        uint256 tokenId = nextTokenId;
        _safeMint(msg.sender, tokenId);
        nextTokenId++;
    }

    function mintTo(address to) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        nextTokenId++;
    }
}

# CreativeCompetition

CreativeCompetition is a peer-judged platform for design contests and artistic merit evaluation built on the Stacks blockchain. The platform enables creators to host competitions, participants to submit entries, and the community to judge submissions in a decentralized manner.

## Features

- **Contest Creation**: Create time-bound creative competitions with customizable parameters
- **Entry Submission**: Submit creative works with metadata and content hashes
- **Peer Judging**: Community-driven evaluation system with score-based feedback
- **Prize Pool Management**: STX-based prize pools with automated distribution
- **Entry Fees**: Configurable entry fees to ensure serious participation
- **Time-Based Phases**: Distinct submission and judging periods
- **Anti-Gaming Measures**: Users cannot judge their own entries
- **Transparency**: All scores and judgments are recorded on-chain

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Clarity Version**: 2
- **Epoch**: 2.5
- **Contract Name**: CreativeCompetition

### Key Data Structures

- **Contests**: Store competition metadata, timing, and prize information
- **Entries**: Track submissions with content hashes and scoring data
- **Judgments**: Record peer evaluations with scores (1-10) and feedback
- **Contest Participants**: Maintain participant counts per contest

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js (for development dependencies)
- Stacks CLI (for deployment)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd CreativeCompetition
```

2. Install Clarinet dependencies:
```bash
cd CreativeCompetition_contract
clarinet requirements
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
clarinet test
```

## Usage Examples

### Creating a Contest

```clarity
;; Create a 7-day contest with 3-day judging period
(contract-call? .CreativeCompetition create-contest
  "Digital Art Competition"
  "Submit your best digital artwork for community judging"
  u1000000  ;; 1 STX prize pool
  u100000   ;; 0.1 STX entry fee
  u1008     ;; 7 days in blocks (~144 blocks/day)
  u432      ;; 3 days judging period
  u3        ;; minimum 3 judges required
)
```

### Submitting an Entry

```clarity
;; Submit entry to contest #1
(contract-call? .CreativeCompetition submit-entry
  u1
  "Sunset Landscape"
  "A vibrant digital painting capturing the essence of a mountain sunset"
  "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi"  ;; IPFS hash
)
```

### Judging an Entry

```clarity
;; Judge entry #1 with score of 8/10
(contract-call? .CreativeCompetition judge-entry
  u1
  u8
  "Excellent use of color and composition. Could improve detail work."
)
```

### Finalizing a Contest

```clarity
;; Finalize contest and distribute prizes (creator only)
(contract-call? .CreativeCompetition finalize-contest u1)
```

## Contract Functions Documentation

### Public Functions

#### `create-contest`
Creates a new creative competition.

**Parameters:**
- `title` (string-ascii 100): Contest title
- `description` (string-ascii 500): Contest description
- `prize-pool` (uint): Total prize amount in microSTX
- `entry-fee` (uint): Fee per entry in microSTX
- `duration-blocks` (uint): Contest duration in blocks
- `judging-duration-blocks` (uint): Judging period duration in blocks
- `min-judges` (uint): Minimum judges required per entry

**Returns:** Contest ID (uint)

#### `submit-entry`
Submit an entry to an active contest.

**Parameters:**
- `contest-id` (uint): Target contest ID
- `title` (string-ascii 100): Entry title
- `description` (string-ascii 500): Entry description
- `content-hash` (string-ascii 64): Content hash (IPFS/storage reference)

**Returns:** Entry ID (uint)

#### `judge-entry`
Judge a submitted entry with score and feedback.

**Parameters:**
- `entry-id` (uint): Entry to judge
- `score` (uint): Score from 1-10
- `feedback` (string-ascii 200): Written feedback

**Returns:** Success boolean

#### `finalize-contest`
Finalize contest and trigger prize distribution (creator only).

**Parameters:**
- `contest-id` (uint): Contest to finalize

**Returns:** Success boolean

### Read-Only Functions

#### `get-contest`
Retrieve contest details by ID.

#### `get-entry`
Retrieve entry details by ID.

#### `get-user-entry`
Get a user's entry for a specific contest.

#### `get-judgment`
Retrieve judgment details for an entry by a specific judge.

#### `get-average-score`
Calculate average score for an entry.

#### `get-participant-count`
Get number of participants in a contest.

#### `is-judging-phase`
Check if a contest is currently in the judging phase.

## Contest Lifecycle

1. **Creation Phase**: Contest creator sets parameters and funds prize pool
2. **Submission Phase**: Participants submit entries and pay entry fees
3. **Judging Phase**: Community members evaluate submissions
4. **Finalization Phase**: Contest creator finalizes and triggers prize distribution

## Error Codes

- `u401`: Not authorized
- `u404`: Contest not found
- `u405`: Contest ended
- `u406`: Contest still active
- `u407`: Already submitted entry
- `u408`: Already judged entry
- `u409`: Insufficient funds
- `u410`: Invalid entry
- `u411`: Cannot judge own entry
- `u412`: Invalid score (must be 1-10)

## Deployment Guide

### Testnet Deployment

1. Configure your testnet environment:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
(contract-call? .CreativeCompetition create-contest "Test Contest" "Testing deployment" u1000000 u50000 u144 u72 u2)
```

### Mainnet Deployment

1. Prepare deployment configuration:
```bash
clarinet deployment generate --testnet
```

2. Review deployment plan and deploy:
```bash
clarinet deployment apply --testnet
```

## Security Notes

### Security Features

- **Entry Fee Protection**: Prevents spam submissions through entry fees
- **Time-Based Validation**: Strict enforcement of submission and judging periods
- **Self-Judging Prevention**: Users cannot judge their own entries
- **Contest Creator Control**: Only creators can finalize their contests
- **STX Escrow**: Prize pools are held in contract until distribution

### Security Considerations

- **Content Verification**: Contract only stores content hashes, not content itself
- **Judging Bias**: No mechanism to prevent coordinated judging attacks
- **Prize Distribution**: Current implementation requires manual finalization
- **Entry Uniqueness**: Users can only submit one entry per contest

### Recommended Security Practices

1. **Content Storage**: Use IPFS or similar decentralized storage for entry content
2. **Entry Validation**: Implement off-chain content validation before submission
3. **Judge Incentives**: Consider implementing judge rewards to encourage participation
4. **Dispute Resolution**: Plan for handling disputed judgments
5. **Prize Logic**: Implement automatic prize distribution in future versions

## Development

### Project Structure

```
CreativeCompetition_contract/
├── contracts/
│   └── CreativeCompetition.clar    # Main contract
├── tests/                          # Test files
├── Clarinet.toml                   # Project configuration
└── package.json                    # Dependencies
```

### Testing

Run the test suite:
```bash
clarinet test
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is open source. Please check the LICENSE file for details.

## Support

For questions, issues, or contributions, please use the project's GitHub repository issue tracker.
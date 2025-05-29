# FluidDAO Protocol

**Next-Generation Liquid Democracy Governance System**

A revolutionary blockchain-based governance protocol that enables dynamic delegation, quadratic voting, and expert-driven decision making while preventing plutocracy and ensuring democratic participation.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Clarity](https://img.shields.io/badge/language-Clarity-purple.svg)
![Stacks](https://img.shields.io/badge/blockchain-Stacks-orange.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)

## 🌟 Features

### 🗳️ **Liquid Democracy**
- **Dynamic Delegation**: Delegate your voting power to trusted experts on specific topics
- **Revocable Proxies**: Instantly withdraw and reassign delegation rights
- **Anti-Cycle Protection**: Automatic detection and prevention of delegation loops
- **Topic-Specific Expertise**: Different delegates for different governance domains

### ⚖️ **Quadratic Voting**
- **Anti-Plutocracy Design**: Square-root cost scaling prevents wealthy participants from dominating decisions
- **Voice Credits System**: Fair allocation of voting budget across all participants
- **Preference Intensity**: Express how strongly you care about different proposals
- **Democratic Balance**: Equal opportunity for all voices to be heard

### 🏛️ **Specialized Councils**
- **Expert Committees**: Domain-specific councils for technical, economic, and social decisions
- **Term Limits**: Automatic rotation prevents entrenchment
- **Veto Powers**: Emergency override mechanisms for system protection
- **Reputation-Based**: Merit-driven participation in specialized governance

### 📊 **Prediction Markets**
- **Outcome Betting**: Stake tokens on proposal success/failure predictions
- **Information Aggregation**: Harness collective intelligence for better decisions
- **Incentive Alignment**: Reward accurate predictions, punish manipulation
- **Decision Support**: Use market signals to inform governance choices

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v1.0+
- [Stacks CLI](https://docs.stacks.co/build-apps/references/stacks-cli)
- Node.js v16+

### Installation

```bash
git clone https://github.com/your-org/fluiddao-protocol.git
cd fluiddao-protocol
clarinet check
```

### Deploy to Testnet

```bash
clarinet deploy --testnet
```

### Deploy to Mainnet

```bash
clarinet deploy --mainnet
```

## 📋 Usage Examples

### Creating a Proposal

```clarity
;; Submit a new governance proposal
(contract-call? .fluiddao-protocol submit-proposal 
  u"Increase Block Rewards"
  u"Proposal to increase mining rewards by 10% to improve network security"
  u"economic"
  u1008) ;; 7 days voting period
```

### Delegating Voting Power

```clarity
;; Delegate your votes on economic topics to a trusted expert
(contract-call? .fluiddao-protocol delegate-voting-power 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 ;; expert address
  u"economic")
```

### Casting Quadratic Votes

```clarity
;; Cast 5 votes "for" a proposal (costs 25 voice credits)
(contract-call? .fluiddao-protocol cast-quadratic-vote 
  u1 ;; proposal ID
  u5 ;; vote intensity 
  u"for")
```

### Creating Expert Councils

```clarity
;; Create a technical advisory council
(contract-call? .fluiddao-protocol create-council
  u"tech-council"
  u"Technical Advisory Council"
  u"Governance for protocol upgrades and technical decisions"
  (list 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7) ;; initial members
  u500 ;; minimum reputation
  true) ;; has veto power
```

### Prediction Market Betting

```clarity
;; Bet 100 STX that proposal #1 will pass
(contract-call? .fluiddao-protocol place-prediction-bet
  u1 ;; proposal ID
  u100000000 ;; 100 STX in microSTX
  true) ;; predict it will pass
```

## 🏗️ Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                    FluidDAO Protocol                        │
├─────────────────────────────────────────────────────────────┤
│  Delegation Engine  │  Voting System   │  Council Manager   │
│  ┌─────────────────┐│ ┌──────────────┐ │ ┌────────────────┐ │
│  │ Chain Resolver  ││ │ Quadratic    │ │ │ Term Manager   │ │
│  │ Cycle Detector  ││ │ Voice Credits│ │ │ Veto System    │ │
│  │ Topic Mapping   ││ │ Vote Weights │ │ │ Rotation Logic │ │
│  └─────────────────┘│ └──────────────┘ │ └────────────────┘ │
│                     │                  │                    │
├─────────────────────────────────────────────────────────────┤
│              Prediction Markets & Reputation                │
│  ┌─────────────────┐│ ┌──────────────┐ │ ┌────────────────┐ │
│  │ Outcome Betting ││ │ Market Maker │ │ │ User Profiles  │ │
│  │ Stake Pool      ││ │ Resolution   │ │ │ Trust Scores   │ │
│  │ Reward System   ││ │ Information  │ │ │ Activity Track │ │
│  └─────────────────┘│ └──────────────┘ │ └────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Data Structure Overview

| Component | Storage | Purpose |
|-----------|---------|---------|
| `delegation-registry` | Map | Tracks who delegates to whom by topic |
| `proposals` | Map | Stores all governance proposals and vote counts |
| `vote-records` | Map | Individual voting records and quadratic weights |
| `voice-credits` | Map | User voting budgets per governance cycle |
| `councils` | Map | Specialized governance committees |
| `prediction-markets` | Map | Betting pools on proposal outcomes |
| `user-profiles` | Map | Reputation, activity, and trust metrics |

## 🔧 Configuration

### System Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `MIN-PROPOSAL-THRESHOLD` | 1000 STX | Minimum stake to submit proposals |
| `MAX-DELEGATION-DEPTH` | 5 levels | Maximum delegation chain length |
| `QUADRATIC-SCALING-FACTOR` | 2.0 | Vote cost exponential multiplier |
| `COUNCIL-TERM-LENGTH` | 90 days | Duration of specialized committee terms |
| `BASE-QUORUM-PERCENTAGE` | 15% | Minimum participation for valid votes |
| `VOICE-CREDITS-PER-CYCLE` | 100 | Quadratic voting budget per period |
| `EMERGENCY-VOTING-WINDOW` | 24 hours | Fast-track decision timeframe |

### Customization

You can modify these parameters by updating the constants in the contract:

```clarity
(define-constant MIN-PROPOSAL-THRESHOLD u2000) ;; Increase proposal threshold
(define-constant VOICE-CREDITS-PER-CYCLE u150) ;; More voting power per cycle
```

## 🛡️ Security

### Anti-Manipulation Measures

- **Delegation Cycle Detection**: Prevents circular delegation chains
- **Quadratic Cost Scaling**: Makes vote buying economically inefficient  
- **Reputation Weighting**: Historical participation affects voting power
- **Time-Bounded Challenges**: Prevents stale verification attempts
- **Emergency Brakes**: Admin controls for governance attacks

### Audit Status

- [ ] Internal security review
- [ ] External smart contract audit
- [ ] Formal verification of critical functions
- [ ] Economic mechanism analysis
- [ ] Game theory modeling

## 🧪 Testing

### Run Test Suite

```bash
clarinet test
```

### Test Coverage

```bash
clarinet test --coverage
```

### Integration Tests

```bash
npm run test:integration
```

### Test Scenarios Covered

- [x] Proposal lifecycle (creation → voting → execution)
- [x] Delegation chain resolution and cycle prevention
- [x] Quadratic voting calculations and credit management
- [x] Council member rotation and term limits
- [x] Prediction market creation and settlement
- [x] Emergency governance procedures
- [x] Anti-manipulation safeguards
- [x] Edge cases and error handling

## 📊 Monitoring & Analytics

### Key Metrics to Track

- **Participation Rate**: % of token holders actively voting
- **Delegation Ratio**: % of votes that are delegated vs direct
- **Quadratic Distribution**: How voice credits are allocated across proposals
- **Council Performance**: Decision quality and member ratings
- **Prediction Accuracy**: Market prediction vs actual outcomes
- **Governance Health**: Proposal success rate and execution time

### Dashboard Integration

The protocol emits events for:
- Proposal submissions and outcomes
- Delegation changes and chain updates
- Vote casting and quadratic allocations
- Council member changes and term rotations
- Prediction market activities and settlements

## 🔮 Roadmap

### Phase 1: Core Implementation ✅
- [x] Basic liquid democracy with delegation
- [x] Quadratic voting system
- [x] Specialized governance councils
- [x] Prediction markets integration

### Phase 2: Advanced Features 🚧
- [ ] Cross-chain governance bridge
- [ ] AI-assisted proposal analysis
- [ ] Privacy-preserving voting (ZK proofs)
- [ ] Mobile governance app
- [ ] Real-world identity integration

### Phase 3: Ecosystem Expansion 📋
- [ ] DAO template marketplace
- [ ] Governance-as-a-Service platform
- [ ] Regulatory compliance tools
- [ ] Enterprise governance solutions
- [ ] Academic research partnerships

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Ensure all tests pass (`clarinet test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- Follow [Clarity best practices](https://docs.stacks.co/write-smart-contracts/best-practices)
- Use descriptive variable names
- Add comprehensive comments
- Include unit tests for all functions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Stacks Foundation** for the excellent Clarity documentation
- **Quadratic Voting Research** by Glen Weyl and the RadicalxChange community
- **Liquid Democracy Theory** by Bryan Ford and delegation research
- **DAO Governance Analysis** by the Token Engineering community


---

**Built with ❤️ for the future of democratic governance**

*FluidDAO Protocol - Where every voice matters, expertise guides decisions, and democracy evolves.*
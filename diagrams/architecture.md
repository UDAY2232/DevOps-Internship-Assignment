```mermaid
flowchart TD
  Internet -->|HTTPS| API["API Gateway VM (public)"]
  subgraph PrivateSubnet [Private Subnet]
    PY["Python Worker VM (private)"]
    TS["TypeScript Worker VM (private)"]
    MODEL["Model Worker VM (private)"]
  end
  API --> PY
  PY --> TS
  TS --> MODEL
  classDef pub fill:#e3f2fd,stroke:#90caf9;
  class API pub;
```

Architecture notes:
- Only the API gateway VM has a public IP and firewall rule allowing HTTP/S and SSH from admin CIDR.
- All worker VMs live in a private subnet (no external IPs). Communication uses private IPs only.

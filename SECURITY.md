# Security Policy

## Supported Versions

| Version | Supported          | Security Updates Until |
| ------- | ------------------ | ---------------------- |
| 4.0.x   | :white_check_mark: | December 2025          |
| < 4.0   | :x:                | N/A                    |

## Security Practices
- **Resource Sandboxing**: AI models execute with restricted permissions
- **Dependency Vetting**: SHA-256 checksums enforced for all PyPI packages
- **Input Validation**: Strict schema validation for OBD-II/CAN bus data
- **Permission Hardening**: Linux capabilities dropped post-initialization

## Reporting a Vulnerability
**Disclosure Process**  
1. Email vulnerabilities to `himu2jz@gmail.com` with "[SECURITY]" in the subject  
2. Include:  
   - Proof-of-concept code/screenshots  
   - Affected version(s)  
   - Proposed remediation (optional)  

**Response SLA**  
- Acknowledgement within **72 hours**  
- Patch timeline communicated within **7 business days**  
- Critical fixes backported to supported versions  

**PGP Key** (For encrypted reports):  
`Fingerprint: 4A5E 8B27 9C3D 4E2F 1A2B  3C4D 5E6F 7A8B 9C0D 1E2F`  

**No Bounties**: This project does not currently offer monetary rewards for disclosures.  
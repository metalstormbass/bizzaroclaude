=== CVE Testing Started ===
Date: Fri Feb 13 18:36:32 EST 2026

# CVE and Vulnerability Findings
**Bizarro-Multiclaude Security Assessment**

## Tested Containers

### nifty_sutherland
- **Container ID:** d37bd40f27f8
- **Image:** cgr.dev/chainguard-private/chainguard-base

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### mike-co-embedding-service-1
- **Container ID:** 4c343c82572d
- **Image:** mike-co-embedding-service

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### mike-co-nginx-1
- **Container ID:** cd76939898b1
- **Image:** mike-co-nginx

#### Nginx CVE Testing
- **Version:** unknown

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### mike-co-document-processor-1
- **Container ID:** a9b35cb7e87d
- **Image:** mike-co-document-processor

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### mike-co-api-gateway-1
- **Container ID:** 6264f0a073c0
- **Image:** mike-co-api-gateway

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### mike-co-llm-service-1
- **Container ID:** 885b254c84bd
- **Image:** mike-co-llm-service

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### mike-co-postgresql-1
- **Container ID:** ba13c7d4a303
- **Image:** cgr.dev/mikeco.com/postgres:16

#### PostgreSQL CVE Testing
- **Version:** 
- **CVE-2024-7348** (PL/Perl Environment Variable Injection)
  - Affects: PostgreSQL < 16.4, < 15.8, < 14.13, < 13.16, < 12.20
  - Severity: HIGH
- **CVE-2023-5869** (Buffer Overflow in COPY FROM)
  - Affects: PostgreSQL < 16.1, < 15.5, < 14.10, < 13.13, < 12.17
  - Severity: MEDIUM

#### Credential Exposure Check
- ⚠️ **WARNING:** Potential credentials in environment variables:
```
POSTGRES_PASSWORD=***REDACTED***
```

---

### mike-co-redis-1
- **Container ID:** 6bf25ca69bcb
- **Image:** cgr.dev/mikeco.com/redis:7

#### Redis CVE Testing
- **Version:** unknown

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### mike-co-opensearch-1
- **Container ID:** 381937be357d
- **Image:** cgr.dev/mikeco.com/opensearch:2

#### OpenSearch CVE Testing
- **Version:** unknown
- **Security Configuration Test:**
  - ✓ Authentication appears to be configured

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### mike-co-ollama-1
- **Container ID:** 22b53aa3c77c
- **Image:** cgr.dev/mikeco.com/ollama:latest-dev

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### mike-co-frontend-1
- **Container ID:** b8c2d45c1201
- **Image:** mike-co-frontend

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### java-app
- **Container ID:** 4e38ad3de071
- **Image:** ddf1fd95c619

#### Java Application CVE Testing
- **Log4Shell (CVE-2021-44228) Detection:**
  - No Log4j libraries detected (or not accessible)
- **Java Version:** unknown

#### Credential Exposure Check
- ⚠️ **WARNING:** Potential credentials in environment variables:
```
ARTIFACTORY_PASSWORD=***REDACTED***
MAVEN_PASSWORD=***REDACTED***
GITHUB_TOKEN=***REDACTED***
CODEARTIFACT_AUTH_TOKEN=***REDACTED***
NEXUS_PASSWORD=***REDACTED***
```

---

### python-app
- **Container ID:** 9193d1871dd2
- **Image:** 175cdebd7544

#### Python Application CVE Testing
- **Python Version:** unknown
- **Dependency Scan:**
  - Cannot enumerate packages (pip not accessible)

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### javascript-app
- **Container ID:** 02b2f248598e
- **Image:** bba400f391bb

#### Java Application CVE Testing
- **Log4Shell (CVE-2021-44228) Detection:**
  - No Log4j libraries detected (or not accessible)
- **Java Version:** unknown

#### Credential Exposure Check
- ⚠️ **WARNING:** Potential credentials in environment variables:
```
NPM_TOKEN=***REDACTED***
NPM_PASSWORD=***REDACTED***
```

---

### kind-control-plane
- **Container ID:** 3bbb6cb4fa1a
- **Image:** kindest/node:v1.35.0

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### k3d-k3s-default-tools
- **Container ID:** 375720d45ec0
- **Image:** ghcr.io/k3d-io/k3d-tools:5.8.3

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### k3d-k3s-default-serverlb
- **Container ID:** a6f091850d3a
- **Image:** ghcr.io/k3d-io/k3d-proxy:5.8.3

#### Credential Exposure Check
- ✓ No obvious credentials in environment variables

---

### k3d-k3s-default-server-0
- **Container ID:** 11060ea20999
- **Image:** rancher/k3s:v1.33.6-k3s1

#### Credential Exposure Check
- ⚠️ **WARNING:** Potential credentials in environment variables:
```
K3S_TOKEN=***REDACTED***
```

---

## Summary

- Total containers scanned: 18
- Scan completed: Fri Feb 13 18:36:38 EST 2026

## Recommended Actions

1. Update all services to latest patched versions
2. Enable authentication on all exposed services (Redis, OpenSearch)
3. Remove or rotate exposed credentials
4. Implement network segmentation
5. Apply security contexts (seccomp, AppArmor)
6. Remove privileged mode from containers where not needed

## Disclaimer

This assessment was conducted in a controlled lab environment on authorized infrastructure for security research purposes only.
=== CVE Testing Complete ===

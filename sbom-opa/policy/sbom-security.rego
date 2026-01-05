package sbom.security

import future.keywords.in

# =============================================================================
# VULNERABILITY POLICIES
# =============================================================================

# DENY: Critical severity vulnerabilities
deny[msg] {
    vuln := input.matches[_]
    vuln.vulnerability.severity == "Critical"
    msg := sprintf("CRITICAL vulnerability %s found in package %s@%s", [
        vuln.vulnerability.id,
        vuln.artifact.name,
        vuln.artifact.version
    ])
}

# DENY: High severity vulnerabilities
deny[msg] {
    vuln := input.matches[_]
    vuln.vulnerability.severity == "High"
    msg := sprintf("HIGH vulnerability %s found in package %s@%s", [
        vuln.vulnerability.id,
        vuln.artifact.name,
        vuln.artifact.version
    ])
}

# =============================================================================
# METRICS AND STATISTICS
# =============================================================================

# Count vulnerabilities by severity
critical_count := count([v | v := input.matches[_]; v.vulnerability.severity == "Critical"])
high_count := count([v | v := input.matches[_]; v.vulnerability.severity == "High"])
medium_count := count([v | v := input.matches[_]; v.vulnerability.severity == "Medium"])
low_count := count([v | v := input.matches[_]; v.vulnerability.severity == "Low"])

# Count unique packages with vulnerabilities
vulnerable_packages := count({pkg | pkg := input.matches[_].artifact.name})

# Total vulnerability count
total_vulnerabilities := count(input.matches)

# =============================================================================
# POLICY DECISIONS
# =============================================================================

# Simple APPROVED/REJECTED policy
result := {
    "status": "REJECTED",
    "message": "SBOM Security Policy: REJECTED",
    "summary": {
        "total_vulnerabilities": total_vulnerabilities,
        "critical": critical_count,
        "high": high_count,
        "medium": medium_count,
        "low": low_count,
        "vulnerable_packages": vulnerable_packages
    },
    "violations": deny
} {
    critical_count > 0
}

result := {
    "status": "REJECTED",
    "message": "SBOM Security Policy: REJECTED",
    "summary": {
        "total_vulnerabilities": total_vulnerabilities,
        "critical": critical_count,
        "high": high_count,
        "medium": medium_count,
        "low": low_count,
        "vulnerable_packages": vulnerable_packages
    },
    "violations": deny
} {
    critical_count == 0
    high_count > 0
}

result := {
    "status": "APPROVED",
    "message": "SBOM Security Policy: APPROVED",
    "summary": {
        "total_vulnerabilities": total_vulnerabilities,
        "critical": critical_count,
        "high": high_count,
        "medium": medium_count,
        "low": low_count,
        "vulnerable_packages": vulnerable_packages
    }
} {
    critical_count == 0
    high_count == 0
}
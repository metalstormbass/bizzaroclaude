#!/bin/bash
# Container Security Reconnaissance Script
# Bizarro-Multiclaude - Lab Testing Only
# Generated: 2026-02-13

OUTPUT_DIR="/Users/mike/Projects/multiclaude/recon-output"
FINDINGS_DIR="/Users/mike/Projects/multiclaude/findings"

echo "=== Container Security Reconnaissance ==="
echo "Started: $(date)"
echo ""

# Get all running containers
CONTAINERS=$(docker ps --format "{{.ID}}")

for CONTAINER_ID in $CONTAINERS; do
    CONTAINER_NAME=$(docker ps --filter "id=$CONTAINER_ID" --format "{{.Names}}")
    CONTAINER_IMAGE=$(docker ps --filter "id=$CONTAINER_ID" --format "{{.Image}}")

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 Target: $CONTAINER_NAME ($CONTAINER_ID)"
    echo "📦 Image: $CONTAINER_IMAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Create output file
    REPORT_FILE="$OUTPUT_DIR/${CONTAINER_NAME}_${CONTAINER_ID}.txt"

    {
        echo "CONTAINER SECURITY REPORT"
        echo "========================="
        echo "Container: $CONTAINER_NAME"
        echo "ID: $CONTAINER_ID"
        echo "Image: $CONTAINER_IMAGE"
        echo "Scan Date: $(date)"
        echo ""

        echo "## 1. PRIVILEGED MODE CHECK"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        PRIVILEGED=$(docker inspect "$CONTAINER_ID" --format '{{.HostConfig.Privileged}}')
        if [ "$PRIVILEGED" = "true" ]; then
            echo "⚠️  CRITICAL: Container is running in PRIVILEGED mode!"
            echo "   Impact: Can escape to host with full root access"
        else
            echo "✓ Container is not privileged"
        fi
        echo ""

        echo "## 2. CAPABILITIES CHECK"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        CAP_ADD=$(docker inspect "$CONTAINER_ID" --format '{{.HostConfig.CapAdd}}')
        CAP_DROP=$(docker inspect "$CONTAINER_ID" --format '{{.HostConfig.CapDrop}}')
        echo "Added Capabilities: $CAP_ADD"
        echo "Dropped Capabilities: $CAP_DROP"

        if echo "$CAP_ADD" | grep -q "SYS_ADMIN"; then
            echo "⚠️  CRITICAL: CAP_SYS_ADMIN detected - can mount filesystems and escape"
        fi
        if echo "$CAP_ADD" | grep -q "SYS_PTRACE"; then
            echo "⚠️  WARNING: CAP_SYS_PTRACE detected - can debug processes"
        fi
        if echo "$CAP_ADD" | grep -q "SYS_MODULE"; then
            echo "⚠️  CRITICAL: CAP_SYS_MODULE detected - can load kernel modules"
        fi
        echo ""

        echo "## 3. NAMESPACE SHARING CHECK"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        PID_MODE=$(docker inspect "$CONTAINER_ID" --format '{{.HostConfig.PidMode}}')
        IPC_MODE=$(docker inspect "$CONTAINER_ID" --format '{{.HostConfig.IpcMode}}')
        NETWORK_MODE=$(docker inspect "$CONTAINER_ID" --format '{{.HostConfig.NetworkMode}}')

        echo "PID Namespace: $PID_MODE"
        if [ "$PID_MODE" = "host" ]; then
            echo "⚠️  CRITICAL: Sharing host PID namespace - can see all host processes!"
        fi

        echo "IPC Namespace: $IPC_MODE"
        if [ "$IPC_MODE" = "host" ]; then
            echo "⚠️  WARNING: Sharing host IPC namespace"
        fi

        echo "Network Mode: $NETWORK_MODE"
        if [ "$NETWORK_MODE" = "host" ]; then
            echo "⚠️  WARNING: Using host network - no network isolation"
        fi
        echo ""

        echo "## 4. VOLUME MOUNTS CHECK"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        docker inspect "$CONTAINER_ID" --format '{{range .Mounts}}Source: {{.Source}} -> Dest: {{.Destination}} ({{.Mode}}){{println}}{{end}}'

        # Check for docker socket
        if docker inspect "$CONTAINER_ID" --format '{{range .Mounts}}{{.Source}}{{end}}' | grep -q "docker.sock"; then
            echo "⚠️  CRITICAL: Docker socket mounted - FULL HOST COMPROMISE POSSIBLE!"
            echo "   Exploit: docker run -v /:/host --rm -it alpine chroot /host sh"
        fi

        # Check for writable host paths
        if docker inspect "$CONTAINER_ID" --format '{{range .Mounts}}{{.Source}}|{{.RW}}{{println}}{{end}}' | grep -E "^/|true"; then
            echo "⚠️  WARNING: Writable host filesystem mounts detected"
        fi
        echo ""

        echo "## 5. SECURITY OPTIONS CHECK"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        SECURITY_OPT=$(docker inspect "$CONTAINER_ID" --format '{{.HostConfig.SecurityOpt}}')
        echo "Security Options: $SECURITY_OPT"

        if echo "$SECURITY_OPT" | grep -q "apparmor=unconfined"; then
            echo "⚠️  WARNING: AppArmor disabled"
        fi
        if echo "$SECURITY_OPT" | grep -q "seccomp=unconfined"; then
            echo "⚠️  CRITICAL: Seccomp disabled - all syscalls allowed!"
        fi
        echo ""

        echo "## 6. EXPOSED PORTS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        docker inspect "$CONTAINER_ID" --format '{{range $p, $conf := .NetworkSettings.Ports}}{{$p}} -> {{(index $conf 0).HostPort}}{{println}}{{end}}'
        echo ""

        echo "## 7. ENVIRONMENT VARIABLES (filtered for secrets)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        docker inspect "$CONTAINER_ID" --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -iE "(password|secret|key|token|api)" || echo "No obvious secrets in env vars"
        echo ""

        echo "## 8. RUNNING PROCESSES (if accessible)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        docker exec "$CONTAINER_ID" ps aux 2>/dev/null || echo "Cannot access process list"
        echo ""

        echo "## 9. SUID BINARIES (potential privilege escalation)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        docker exec "$CONTAINER_ID" find / -perm -4000 -type f 2>/dev/null | head -20 || echo "Cannot enumerate SUID binaries"
        echo ""

        echo "## 10. NETWORK CONFIGURATION"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        docker exec "$CONTAINER_ID" ifconfig 2>/dev/null || docker exec "$CONTAINER_ID" ip addr 2>/dev/null || echo "Cannot access network config"
        echo ""

    } > "$REPORT_FILE"

    echo "📝 Report saved: $REPORT_FILE"
    echo ""
done

echo "=== Reconnaissance Complete ==="
echo "Ended: $(date)"
echo "Reports in: $OUTPUT_DIR"

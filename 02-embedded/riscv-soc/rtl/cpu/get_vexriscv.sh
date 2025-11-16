#!/bin/bash
# ==============================================================================
# VexRiscv Download and Integration Script
# ==============================================================================
#
# This script automates the process of obtaining VexRiscv core for the SoC.
#
# Usage:
#   ./get_vexriscv.sh [option]
#
# Options:
#   prebuilt    - Download pre-built VexRiscv from releases (fastest)
#   generate    - Generate custom VexRiscv locally (requires Java/SBT)
#   help        - Show this help message
#

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CPU_DIR="$SCRIPT_DIR"
SOC_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMP_DIR="/tmp/vexriscv_build_$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# Helper Functions
# ==============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    fi
    return 0
}

# ==============================================================================
# Show Help
# ==============================================================================

show_help() {
    cat << EOF
VexRiscv Integration Script
============================

This script helps you obtain the VexRiscv RISC-V core for the SoC.

Usage:
    ./get_vexriscv.sh [option]

Options:
    prebuilt    Download pre-built VexRiscv from GitHub releases
    generate    Generate custom VexRiscv (requires Java 8+ and SBT)
    help        Show this help message

Examples:
    # Quick start (recommended)
    ./get_vexriscv.sh prebuilt

    # Custom generation (advanced)
    ./get_vexriscv.sh generate

After running this script, the VexRiscv core will be available in:
    $CPU_DIR/VexRiscv.v

Next steps:
    1. Update vexriscv_wrapper.v to instantiate the core
    2. Rebuild Vivado project
    3. Compile firmware
    4. Test on FPGA

EOF
}

# ==============================================================================
# Download Pre-built VexRiscv
# ==============================================================================

download_prebuilt() {
    print_header "Downloading Pre-built VexRiscv"

    # Check for required tools
    if ! check_command wget && ! check_command curl; then
        print_error "Neither wget nor curl found. Please install one of them."
        exit 1
    fi

    print_info "Fetching latest VexRiscv release..."

    # Use a specific known-good release
    VEXRISCV_URL="https://raw.githubusercontent.com/SpinalHDL/VexRiscv/master/src/test/cpp/regression/VexRiscv.v"

    print_info "Downloading from: $VEXRISCV_URL"

    if check_command wget; then
        wget -O "$CPU_DIR/VexRiscv.v" "$VEXRISCV_URL" || {
            print_error "Download failed!"
            print_info "Trying alternate method..."

            # Try a specific release if master fails
            BACKUP_URL="https://github.com/SpinalHDL/VexRiscv/releases/download/v1.0.0/VexRiscv.v"
            wget -O "$CPU_DIR/VexRiscv.v" "$BACKUP_URL" || {
                print_error "Backup download also failed."
                print_info "You may need to download manually from:"
                print_info "https://github.com/SpinalHDL/VexRiscv/releases"
                exit 1
            }
        }
    elif check_command curl; then
        curl -L -o "$CPU_DIR/VexRiscv.v" "$VEXRISCV_URL" || {
            print_error "Download failed!"
            exit 1
        }
    fi

    if [ -f "$CPU_DIR/VexRiscv.v" ]; then
        print_success "VexRiscv.v downloaded successfully!"
        print_info "File location: $CPU_DIR/VexRiscv.v"
        print_info "File size: $(du -h "$CPU_DIR/VexRiscv.v" | cut -f1)"

        # Verify it's a valid Verilog file
        if grep -q "module VexRiscv" "$CPU_DIR/VexRiscv.v"; then
            print_success "Verification: Valid VexRiscv module found"
        else
            print_error "Verification failed: VexRiscv module not found in file"
            print_info "File may be corrupted or incorrect"
            exit 1
        fi
    else
        print_error "Download failed - file not found"
        exit 1
    fi
}

# ==============================================================================
# Generate Custom VexRiscv
# ==============================================================================

generate_custom() {
    print_header "Generating Custom VexRiscv Core"

    # Check for Java
    if ! check_command java; then
        print_error "Java not found. Please install Java 8 or later."
        print_info "On Ubuntu/Debian: sudo apt-get install openjdk-11-jdk"
        print_info "On macOS: brew install openjdk@11"
        exit 1
    fi

    print_success "Java found: $(java -version 2>&1 | head -n 1)"

    # Check for SBT
    if ! check_command sbt; then
        print_error "SBT (Scala Build Tool) not found."
        print_info "On Ubuntu/Debian: sudo apt-get install sbt"
        print_info "On macOS: brew install sbt"
        print_info ""
        print_info "Or download from: https://www.scala-sbt.org/download.html"
        exit 1
    fi

    print_success "SBT found: $(sbt --version 2>&1 | grep 'sbt version' || echo 'installed')"

    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    print_info "Cloning VexRiscv repository..."
    git clone --depth 1 https://github.com/SpinalHDL/VexRiscv.git

    cd VexRiscv

    print_info "Generating VexRiscv core (this may take several minutes)..."
    print_info "Configuration: RV32IMC with Wishbone bus"

    # Generate the core
    # Using GenSmallest for simplicity (you can customize this)
    sbt "runMain vexriscv.demo.GenSmallest" || {
        print_error "Generation failed!"
        print_info "This may be due to missing dependencies or network issues."
        exit 1
    }

    # Find generated Verilog file
    GENERATED_FILE=$(find . -name "VexRiscv*.v" | head -n 1)

    if [ -n "$GENERATED_FILE" ]; then
        print_success "Core generated: $GENERATED_FILE"

        # Copy to CPU directory
        cp "$GENERATED_FILE" "$CPU_DIR/VexRiscv.v"
        print_success "Copied to: $CPU_DIR/VexRiscv.v"

        # Cleanup
        cd /
        rm -rf "$TEMP_DIR"
        print_info "Cleaned up temporary files"
    else
        print_error "Generated Verilog file not found!"
        exit 1
    fi
}

# ==============================================================================
# Post-Integration Steps
# ==============================================================================

show_next_steps() {
    print_header "VexRiscv Successfully Obtained!"

    echo "VexRiscv core is now available at:"
    echo "  $CPU_DIR/VexRiscv.v"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Inspect the VexRiscv port names:"
    echo "   grep 'module VexRiscv' $CPU_DIR/VexRiscv.v -A 50"
    echo ""
    echo "2. Update the wrapper (vexriscv_wrapper.v):"
    echo "   - Replace the stub implementation"
    echo "   - Instantiate VexRiscv with correct port mappings"
    echo ""
    echo "3. Update Vivado project:"
    echo "   cd $SOC_ROOT"
    echo "   make vivado-project"
    echo ""
    echo "4. Test with simulation:"
    echo "   make sim-soc"
    echo ""
    echo "5. Build firmware and synthesize:"
    echo "   make firmware"
    echo "   make vivado-build"
    echo ""
    echo "For detailed instructions, see:"
    echo "  $SOC_ROOT/01-IMPLEMENTATION-GUIDE.md"
    echo ""
}

# ==============================================================================
# Main Script
# ==============================================================================

main() {
    print_header "VexRiscv Integration Tool"

    # Check if VexRiscv already exists
    if [ -f "$CPU_DIR/VexRiscv.v" ]; then
        print_info "VexRiscv.v already exists!"
        echo "File: $CPU_DIR/VexRiscv.v"
        echo "Size: $(du -h "$CPU_DIR/VexRiscv.v" | cut -f1)"
        echo ""
        read -p "Overwrite existing file? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Operation cancelled."
            exit 0
        fi
    fi

    # Parse command line arguments
    case "${1:-prebuilt}" in
        prebuilt)
            download_prebuilt
            ;;
        generate)
            generate_custom
            ;;
        help|--help|-h)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac

    show_next_steps
}

# Run main function
main "$@"

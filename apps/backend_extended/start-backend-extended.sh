#!/bin/bash

# Script to start backend-extended service with automatic tool installation
# Compatible with macOS and Linux

set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"
BACKEND_DIR="$PROJECT_ROOT/apps/backend_extended"
TOOLS_DIR="$BACKEND_DIR/tools"

# Required Java version
JAVA_VERSION="21"
MAVEN_VERSION="3.9.6"

echo "========================================="
echo "Backend Extended - Auto Setup & Start"
echo "========================================="
echo ""

# Create tools directory if it doesn't exist
mkdir -p "$TOOLS_DIR"

# Function to check if Java 21 is available
check_java() {
    if command -v java &> /dev/null; then
        JAVA_VER=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' | cut -d'.' -f1)
        if [ "$JAVA_VER" = "$JAVA_VERSION" ]; then
            echo "✓ Java $JAVA_VERSION found: $(which java)"
            return 0
        fi
    fi
    
    # Check in tools directory
    if [ -d "$TOOLS_DIR/jdk-$JAVA_VERSION" ]; then
        export JAVA_HOME="$TOOLS_DIR/jdk-$JAVA_VERSION"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "✓ Java $JAVA_VERSION found in tools: $JAVA_HOME"
        return 0
    fi
    
    return 1
}

# Function to install Java 21
install_java() {
    echo ""
    echo "Installing Java $JAVA_VERSION..."
    echo "This may take a few minutes..."
    
    # Detect OS
    OS_TYPE=$(uname -s)
    ARCH=$(uname -m)
    
    # Convert architecture names
    if [ "$ARCH" = "x86_64" ]; then
        ARCH="x64"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        ARCH="aarch64"
    fi
    
    # Determine download URL based on OS
    if [ "$OS_TYPE" = "Darwin" ]; then
        if [ "$ARCH" = "aarch64" ]; then
            JDK_URL="https://download.oracle.com/java/21/latest/jdk-21_macos-aarch64_bin.tar.gz"
        else
            JDK_URL="https://download.oracle.com/java/21/latest/jdk-21_macos-x64_bin.tar.gz"
        fi
        JDK_ARCHIVE="jdk-21_macos.tar.gz"
    else
        # Linux
        JDK_URL="https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz"
        JDK_ARCHIVE="jdk-21_linux.tar.gz"
    fi
    
    cd "$TOOLS_DIR"
    
    echo "Downloading JDK from: $JDK_URL"
    if command -v curl &> /dev/null; then
        curl -L -o "$JDK_ARCHIVE" "$JDK_URL"
    elif command -v wget &> /dev/null; then
        wget -O "$JDK_ARCHIVE" "$JDK_URL"
    else
        echo "Error: Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    echo "Extracting JDK..."
    tar -xzf "$JDK_ARCHIVE"
    
    # Find extracted directory
    JDK_DIR=$(find . -maxdepth 1 -type d -name "jdk-*" | head -n 1)
    if [ "$OS_TYPE" = "Darwin" ]; then
        # On macOS, the structure is jdk-21.jdk/Contents/Home
        if [ -d "${JDK_DIR}/Contents/Home" ]; then
            JDK_DIR="${JDK_DIR}/Contents/Home"
        fi
    fi
    
    # Rename to standard name
    mv "$JDK_DIR" "jdk-$JAVA_VERSION" 2>/dev/null || true
    
    rm -f "$JDK_ARCHIVE"
    
    export JAVA_HOME="$TOOLS_DIR/jdk-$JAVA_VERSION"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    echo "✓ Java $JAVA_VERSION installed successfully!"
    java -version
}

# Function to check if Maven is available
check_maven() {
    if command -v mvn &> /dev/null; then
        echo "✓ Maven found: $(which mvn)"
        return 0
    fi
    
    # Check in tools directory
    if [ -d "$TOOLS_DIR/apache-maven-$MAVEN_VERSION" ]; then
        export MAVEN_HOME="$TOOLS_DIR/apache-maven-$MAVEN_VERSION"
        export PATH="$MAVEN_HOME/bin:$PATH"
        echo "✓ Maven found in tools: $MAVEN_HOME"
        return 0
    fi
    
    return 1
}

# Function to install Maven
install_maven() {
    echo ""
    echo "Installing Maven $MAVEN_VERSION..."
    
    cd "$TOOLS_DIR"
    
    MAVEN_URL="https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz"
    MAVEN_ARCHIVE="apache-maven-$MAVEN_VERSION-bin.tar.gz"
    
    echo "Downloading Maven from: $MAVEN_URL"
    if command -v curl &> /dev/null; then
        curl -L -o "$MAVEN_ARCHIVE" "$MAVEN_URL"
    elif command -v wget &> /dev/null; then
        wget -O "$MAVEN_ARCHIVE" "$MAVEN_URL"
    else
        echo "Error: Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    echo "Extracting Maven..."
    tar -xzf "$MAVEN_ARCHIVE"
    rm -f "$MAVEN_ARCHIVE"
    
    export MAVEN_HOME="$TOOLS_DIR/apache-maven-$MAVEN_VERSION"
    export PATH="$MAVEN_HOME/bin:$PATH"
    
    echo "✓ Maven installed successfully!"
    mvn -version
}

# Main execution
echo "Checking Java $JAVA_VERSION..."
if ! check_java; then
    install_java
fi

echo ""
echo "Checking Maven..."
if ! check_maven; then
    install_maven
fi

echo ""
echo "========================================="
echo "All tools ready! Starting application..."
echo "========================================="
echo ""

# Navigate to backend directory
cd "$BACKEND_DIR"

# Set JAVA_HOME if using tools version
if [ -d "$TOOLS_DIR/jdk-$JAVA_VERSION" ]; then
    export JAVA_HOME="$TOOLS_DIR/jdk-$JAVA_VERSION"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

if [ -d "$TOOLS_DIR/apache-maven-$MAVEN_VERSION" ]; then
    export MAVEN_HOME="$TOOLS_DIR/apache-maven-$MAVEN_VERSION"
    export PATH="$MAVEN_HOME/bin:$PATH"
fi

# Display versions
echo "Using Java version:"
java -version
echo ""
echo "Using Maven version:"
mvn -version
echo ""

# Clean and run the application
echo "Building and starting the application..."
echo "========================================="
mvn clean spring-boot:run

echo ""
echo "Backend-extended service stopped."

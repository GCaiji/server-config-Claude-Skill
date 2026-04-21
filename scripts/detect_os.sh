#!/bin/bash
#===============================================================================
# 操作系统检测脚本
# 功能：自动检测 Linux 发行版、版本号、包管理器等
#===============================================================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

#-------------------------------------------------------------------------------
# 检测操作系统类型
#-------------------------------------------------------------------------------
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
        OS_NAME=$(cat /etc/redhat-release)
        OS_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
    elif [ -f /etc/debian_version ]; then
        OS="debian"
        OS_NAME="Debian"
        OS_VERSION=$(cat /etc/debian_version)
    else
        OS="unknown"
        OS_NAME="Unknown"
        OS_VERSION="unknown"
    fi

    # 标准化 OS 名称
    case "$OS" in
        ubuntu)       ;;
        centos)       ;;
        rocky)        ;;
        almalinux)    ;;
        debian)       ;;
        *)            ;;
    esac
}

#-------------------------------------------------------------------------------
# 检测 CPU 架构
#-------------------------------------------------------------------------------
detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  ARCH_DISPLAY="x86_64 (AMD64)" ;;
        aarch64) ARCH_DISPLAY="ARM64 (AArch64)" ;;
        armv7l)  ARCH_DISPLAY="ARM32" ;;
        *)       ARCH_DISPLAY="$ARCH" ;;
    esac
}

#-------------------------------------------------------------------------------
# 检测内存
#-------------------------------------------------------------------------------
detect_memory() {
    TOTAL_MEM=$(free -h | awk '/^Mem:/ {print $2}')
    USED_MEM=$(free -h | awk '/^Mem:/ {print $3}')
    AVAIL_MEM=$(free -h | awk '/^Mem:/ {print $7}')
}

#-------------------------------------------------------------------------------
# 检测磁盘
#-------------------------------------------------------------------------------
detect_disk() {
    TOTAL_DISK=$(df -h / | awk 'NR==2 {print $2}')
    USED_DISK=$(df -h / | awk 'NR==2 {print $3}')
    AVAIL_DISK=$(df -h / | awk 'NR==2 {print $4}')
}

#-------------------------------------------------------------------------------
# 检测包管理器
#-------------------------------------------------------------------------------
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
    elif command -v apk &> /dev/null; then
        PKG_MANAGER="apk"
    else
        PKG_MANAGER="unknown"
    fi
}

#-------------------------------------------------------------------------------
# 检测 SSH 服务商
#-------------------------------------------------------------------------------
detect_cloud_provider() {
    # 腾讯云
    if dmidecode -s system-product-name 2>/dev/null | grep -qi "qcloud\|tencent"; then
        CLOUD="Tencent Cloud (腾讯云)"
    # 阿里云
    elif dmidecode -s system-product-name 2>/dev/null | grep -qi "alibaba\|aliyun"; then
        CLOUD="Alibaba Cloud (阿里云)"
    # AWS
    elif curl -s http://169.254.169.254/latest/meta-data/ 2>/dev/null | grep -q "ami"; then
        CLOUD="AWS"
    else
        CLOUD="Unknown / 独立服务器"
    fi
}

#-------------------------------------------------------------------------------
# 检测已安装软件
#-------------------------------------------------------------------------------
detect_installed_software() {
    INSTALLED_SOFTWARE=()

    # Web 服务器
    command -v nginx &> /dev/null && INSTALLED_SOFTWARE+=("nginx")
    command -v apache2 &> /dev/null && INSTALLED_SOFTWARE+=("apache2")
    command -v httpd &> /dev/null && INSTALLED_SOFTWARE+=("httpd")

    # 数据库
    command -v mysql &> /dev/null && INSTALLED_SOFTWARE+=("mysql")
    command -v mariadb &> /dev/null && INSTALLED_SOFTWARE+=("mariadb")
    command -v postgresql &> /dev/null && INSTALLED_SOFTWARE+=("postgresql")
    command -v mongod &> /dev/null && INSTALLED_SOFTWARE+=("mongodb")
    command -v redis-server &> /dev/null && INSTALLED_SOFTWARE+=("redis")

    # 编程语言
    command -v php &> /dev/null && INSTALLED_SOFTWARE+=("php")
    command -v python3 &> /dev/null && INSTALLED_SOFTWARE+=("python3")
    command -v python &> /dev/null && INSTALLED_SOFTWARE+=("python")
    command -v node &> /dev/null && INSTALLED_SOFTWARE+=("nodejs")
    command -v npm &> /dev/null && INSTALLED_SOFTWARE+=("npm")

    # 容器
    command -v docker &> /dev/null && INSTALLED_SOFTWARE+=("docker")

    # 其他
    command -v certbot &> /dev/null && INSTALLED_SOFTWARE+=("certbot")
    command -v ufw &> /dev/null && INSTALLED_SOFTWARE+=("ufw")
    command -v firewalld &> /dev/null && INSTALLED_SOFTWARE+=("firewalld")
}

#-------------------------------------------------------------------------------
# 输出检测结果
#-------------------------------------------------------------------------------
print_report() {
    echo ""
    echo "=========================================="
    echo "         服务器环境检测报告"
    echo "=========================================="
    echo ""
    echo -e "${GREEN}操作系统${NC}"
    echo "  发行版: $OS_NAME"
    echo "  版本号: $OS_VERSION"
    echo "  内核: $(uname -r)"
    echo "  架构: $ARCH_DISPLAY"
    echo "  云服务商: $CLOUD"
    echo ""
    echo -e "${GREEN}硬件资源${NC}"
    echo "  内存: $TOTAL_MEM (已用: $USED_MEM, 可用: $AVAIL_MEM)"
    echo "  磁盘: $TOTAL_DISK (已用: $USED_DISK, 可用: $AVAIL_DISK)"
    echo ""
    echo -e "${GREEN}软件环境${NC}"
    echo "  包管理器: $PKG_MANAGER"
    echo "  已安装: ${INSTALLED_SOFTWARE[*]:-无}"
    echo ""
    echo "=========================================="

    # 输出环境变量供后续使用
    echo ""
    echo "# 环境变量 (可复制使用)"
    echo "export OS_TYPE=\"$OS\""
    echo "export OS_NAME=\"$OS_NAME\""
    echo "export OS_VERSION=\"$OS_VERSION\""
    echo "export PKG_MANAGER=\"$PKG_MANAGER\""
}

#-------------------------------------------------------------------------------
# 主函数
#-------------------------------------------------------------------------------
main() {
    log_info "开始检测服务器环境..."
    echo ""

    detect_os
    detect_arch
    detect_memory
    detect_disk
    detect_package_manager
    detect_cloud_provider
    detect_installed_software

    print_report

    log_success "检测完成!"
}

main "$@"
